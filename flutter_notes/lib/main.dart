import 'package:flutter/material.dart';

void main() {
  runApp(const NotesApp());
}

TextDirection getDirectionOfText(
  String text, {
  TextDirection defaultDirection = TextDirection.ltr,
}) {
  for (final char in text.runes) {
    if (_isRtlCharacter(char)) {
      return TextDirection.rtl;
    }
    if (_isLtrCharacter(char)) {
      return TextDirection.ltr;
    }
  }
  return defaultDirection;
}

bool _isRtlCharacter(int rune) {
  return (rune >= 0x0590 && rune <= 0x08FF) ||
      (rune >= 0xFB50 && rune <= 0xFDFF) ||
      (rune >= 0xFE70 && rune <= 0xFEFF);
}

bool _isLtrCharacter(int rune) {
  return (rune >= 0x0041 && rune <= 0x005A) ||
      (rune >= 0x0061 && rune <= 0x007A) ||
      (rune >= 0x00C0 && rune <= 0x024F) ||
      (rune >= 0x0370 && rune <= 0x052F) ||
      (rune >= 0x2C00 && rune <= 0x2DFF) ||
      (rune >= 0x3000 && rune <= 0x9FFF);
}

class Note {
  final String id;
  final String content;
  final DateTime updatedAt;

  Note({required this.id, required this.content, required this.updatedAt});

  Note copyWith({String? id, String? content, DateTime? updatedAt}) {
    return Note(
      id: id ?? this.id,
      content: content ?? this.content,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class NotesRepository extends ValueNotifier<List<Note>> {
  NotesRepository([List<Note>? initialNotes]) : super(initialNotes ?? []);

  void saveNote({String? id, required String content}) {
    final trimmed = content.trim();
    if (trimmed.isEmpty) {
      if (id != null) {
        deleteNote(id);
      }
      return;
    }

    final now = DateTime.now();
    if (id == null || id.isEmpty) {
      final newNote = Note(
        id: now.microsecondsSinceEpoch.toString(),
        content: content,
        updatedAt: now,
      );
      value = [newNote, ...value];
    } else {
      final index = value.indexWhere((n) => n.id == id);
      if (index != -1) {
        final updatedNote = value[index].copyWith(
          content: content,
          updatedAt: now,
        );
        final newList = List<Note>.from(value);
        newList[index] = updatedNote;
        value = newList;
      } else {
        final newNote = Note(id: id, content: content, updatedAt: now);
        value = [newNote, ...value];
      }
    }
  }

  void deleteNote(String id) {
    value = value.where((n) => n.id != id).toList();
  }
}

class NotesScope extends InheritedNotifier<NotesRepository> {
  const NotesScope({
    super.key,
    required NotesRepository repository,
    required super.child,
  }) : super(notifier: repository);

  static NotesRepository of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<NotesScope>();
    assert(scope != null, 'No NotesScope found in context');
    return scope!.notifier!;
  }
}

class NotesApp extends StatefulWidget {
  final NotesRepository? repository;

  const NotesApp({super.key, this.repository});

  @override
  State<NotesApp> createState() => _NotesAppState();
}

class _NotesAppState extends State<NotesApp> {
  late final NotesRepository _repository;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? NotesRepository();
  }

  @override
  void dispose() {
    if (widget.repository == null) {
      _repository.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NotesScope(
      repository: _repository,
      child: MaterialApp(
        title: 'Notes Prototype',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: const NotesListScreen(),
      ),
    );
  }
}

class NotesListScreen extends StatelessWidget {
  const NotesListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = NotesScope.of(context);
    final notes = repository.value;

    return Scaffold(
      appBar: AppBar(title: const Text('Notes')),
      body: notes.isEmpty
          ? const Center(child: Text('No notes yet. Tap + to add one.'))
          : ListView.builder(
              itemCount: notes.length,
              itemBuilder: (context, index) {
                final note = notes[index];
                final direction = getDirectionOfText(note.content);
                return ListTile(
                  title: Text(
                    note.content,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textDirection: direction,
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditorScreen(note: note),
                      ),
                    );
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const EditorScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class EditorScreen extends StatefulWidget {
  final Note? note;

  const EditorScreen({super.key, this.note});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  late final TextEditingController _controller;
  late TextDirection _textDirection;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.note?.content ?? '');
    _textDirection = getDirectionOfText(_controller.text);
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final newDirection = getDirectionOfText(_controller.text);
    if (newDirection != _textDirection) {
      setState(() {
        _textDirection = newDirection;
      });
    }
  }

  void _saveNote() {
    final repository = NotesScope.of(context);
    repository.saveNote(id: widget.note?.id, content: _controller.text);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
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
