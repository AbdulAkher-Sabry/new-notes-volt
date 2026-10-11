import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const NotesApp());
}

/// Dynamic text direction detection based on the first strong character.
TextDirection getAutoTextDirection(String text) {
  final rtlRegex = RegExp(
    r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF\u0590-\u05FF]',
  );
  final ltrRegex = RegExp(r'[A-Za-z\u00C0-\u024F\u1E00-\u1EFF]');

  for (final rune in text.runes) {
    final char = String.fromCharCode(rune);
    if (rtlRegex.hasMatch(char)) {
      return TextDirection.rtl;
    }
    if (ltrRegex.hasMatch(char)) {
      return TextDirection.ltr;
    }
  }

  return TextDirection.ltr;
}

class Note {
  final String id;
  final String content;
  final DateTime updatedAt;

  Note({required this.id, required this.content, required this.updatedAt});

  Map<String, dynamic> toJson() => {
    'id': id,
    'content': content,
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory Note.fromJson(Map<String, dynamic> json) => Note(
    id: json['id'] as String,
    content: json['content'] as String,
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );

  Note copyWith({String? content, DateTime? updatedAt}) {
    return Note(
      id: id,
      content: content ?? this.content,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class NotesRepository {
  static const String _storageKey = 'saved_notes';
  final SharedPreferences? _prefs;

  NotesRepository([this._prefs]);

  Future<List<Note>> loadNotes() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);
    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }
    try {
      final List<dynamic> jsonList = jsonDecode(jsonString) as List<dynamic>;
      final notes = jsonList
          .map((item) => Note.fromJson(item as Map<String, dynamic>))
          .toList();
      notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return notes;
    } catch (_) {
      return [];
    }
  }

  Future<void> saveNotes(List<Note> notes) async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    final jsonList = notes.map((n) => n.toJson()).toList();
    await prefs.setString(_storageKey, jsonEncode(jsonList));
  }
}

class NotesManager extends ChangeNotifier {
  final NotesRepository _repository;
  List<Note> _notes = [];
  bool _isLoading = true;

  NotesManager({NotesRepository? repository})
    : _repository = repository ?? NotesRepository();

  List<Note> get notes => List.unmodifiable(_notes);
  bool get isLoading => _isLoading;

  Future<void> loadNotes() async {
    _notes = await _repository.loadNotes();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> saveNote(Note note) async {
    final trimmed = note.content.trim();
    if (trimmed.isEmpty) {
      await deleteNote(note.id);
      return;
    }

    final index = _notes.indexWhere((n) => n.id == note.id);
    if (index >= 0) {
      _notes[index] = note;
    } else {
      _notes.insert(0, note);
    }
    _notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    notifyListeners();
    await _repository.saveNotes(_notes);
  }

  Future<void> deleteNote(String id) async {
    final initialLength = _notes.length;
    _notes.removeWhere((n) => n.id == id);
    if (_notes.length != initialLength) {
      notifyListeners();
      await _repository.saveNotes(_notes);
    }
  }
}

class NotesApp extends StatefulWidget {
  final NotesManager? notesManager;

  const NotesApp({super.key, this.notesManager});

  @override
  State<NotesApp> createState() => _NotesAppState();
}

class _NotesAppState extends State<NotesApp> {
  late final NotesManager _notesManager;

  @override
  void initState() {
    super.initState();
    _notesManager = widget.notesManager ?? NotesManager();
    _notesManager.loadNotes();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Notes Prototype',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: NotesListScreen(notesManager: _notesManager),
    );
  }
}

class NotesListScreen extends StatelessWidget {
  final NotesManager notesManager;

  const NotesListScreen({super.key, required this.notesManager});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notes')),
      body: ListenableBuilder(
        listenable: notesManager,
        builder: (context, _) {
          if (notesManager.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (notesManager.notes.isEmpty) {
            return const Center(child: Text('No notes yet. Tap + to add one.'));
          }
          return ListView.builder(
            itemCount: notesManager.notes.length,
            itemBuilder: (context, index) {
              final note = notesManager.notes[index];
              final direction = getAutoTextDirection(note.content);
              return ListTile(
                title: Text(
                  note.content,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textDirection: direction,
                  textAlign: direction == TextDirection.rtl
                      ? TextAlign.right
                      : TextAlign.left,
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          EditorScreen(note: note, notesManager: notesManager),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EditorScreen(notesManager: notesManager),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class EditorScreen extends StatefulWidget {
  final Note? note;
  final NotesManager notesManager;

  const EditorScreen({super.key, this.note, required this.notesManager});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  late final TextEditingController _controller;
  late final String _noteId;
  TextDirection _textDirection = TextDirection.ltr;
  bool _hasSaved = false;

  @override
  void initState() {
    super.initState();
    _noteId =
        widget.note?.id ?? DateTime.now().microsecondsSinceEpoch.toString();
    _controller = TextEditingController(text: widget.note?.content ?? '');
    _textDirection = getAutoTextDirection(_controller.text);
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final newDirection = getAutoTextDirection(_controller.text);
    if (newDirection != _textDirection) {
      setState(() {
        _textDirection = newDirection;
      });
    }
  }

  @override
  void dispose() {
    _saveNote();
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  void _saveNote() {
    if (_hasSaved) return;
    _hasSaved = true;
    final text = _controller.text;
    final noteToSave = Note(
      id: _noteId,
      content: text,
      updatedAt: DateTime.now(),
    );
    widget.notesManager.saveNote(noteToSave);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          _saveNote();
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Edit Note')),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _controller,
            maxLines: null,
            expands: true,
            textDirection: _textDirection,
            textAlign: TextAlign.start,
            decoration: const InputDecoration(
              hintText: 'Start typing your note here...',
              border: InputBorder.none,
            ),
          ),
        ),
      ),
    );
  }
}
