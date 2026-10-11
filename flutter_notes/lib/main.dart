import 'package:flutter/material.dart';

class Note {
  final String id;
  String content;
  DateTime updatedAt;

  Note({required this.id, required this.content, required this.updatedAt});
}

class NotesRepository extends ChangeNotifier {
  final List<Note> _notes = [];

  List<Note> get notes => List.unmodifiable(_notes);

  void saveNote({String? id, required String content}) {
    final trimmed = content.trim();
    if (id == null || id.isEmpty) {
      if (trimmed.isEmpty) return;
      _notes.insert(
        0,
        Note(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          content: content,
          updatedAt: DateTime.now(),
        ),
      );
    } else {
      final index = _notes.indexWhere((note) => note.id == id);
      if (index != -1) {
        if (trimmed.isEmpty) {
          _notes.removeAt(index);
        } else {
          _notes[index].content = content;
          _notes[index].updatedAt = DateTime.now();
        }
      } else if (trimmed.isNotEmpty) {
        _notes.insert(
          0,
          Note(id: id, content: content, updatedAt: DateTime.now()),
        );
      }
    }
    notifyListeners();
  }

  void deleteNote(String id) {
    _notes.removeWhere((note) => note.id == id);
    notifyListeners();
  }
}

class NotesRepositoryProvider extends InheritedNotifier<NotesRepository> {
  const NotesRepositoryProvider({
    super.key,
    required NotesRepository repository,
    required super.child,
  }) : super(notifier: repository);

  static NotesRepository of(BuildContext context) {
    final provider = context
        .dependOnInheritedWidgetOfExactType<NotesRepositoryProvider>();
    assert(provider != null, 'No NotesRepositoryProvider found in context');
    return provider!.notifier!;
  }
}

void main() {
  runApp(const NotesApp());
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
    return NotesRepositoryProvider(
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
    final repository = NotesRepositoryProvider.of(context);
    final notes = repository.notes;

    return Scaffold(
      appBar: AppBar(title: const Text('Notes')),
      body: notes.isEmpty
          ? const Center(child: Text('No notes yet. Tap + to add one.'))
          : ListView.builder(
              itemCount: notes.length,
              itemBuilder: (context, index) {
                final note = notes[index];
                final textDir = getDirectionFromText(note.content);
                return ListTile(
                  title: Text(
                    note.content,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textDirection: textDir,
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

TextDirection getDirectionFromText(String text) {
  final rtlMatch = RegExp(
    r'[\u0590-\u05FF\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF]',
  ).firstMatch(text);
  final ltrMatch = RegExp(r'[A-Za-z\u00C0-\u024F]').firstMatch(text);

  if (rtlMatch != null && ltrMatch != null) {
    return rtlMatch.start < ltrMatch.start
        ? TextDirection.rtl
        : TextDirection.ltr;
  } else if (rtlMatch != null) {
    return TextDirection.rtl;
  } else {
    return TextDirection.ltr;
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

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.note?.content ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _saveNote() {
    final repository = NotesRepositoryProvider.of(context);
    repository.saveNote(id: widget.note?.id, content: _controller.text);
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
          child: ValueListenableBuilder<TextEditingValue>(
            valueListenable: _controller,
            builder: (context, value, child) {
              final textDirection = getDirectionFromText(value.text);
              return TextField(
                controller: _controller,
                maxLines: null,
                expands: true,
                textDirection: textDirection,
                textAlign: TextAlign.start,
                decoration: const InputDecoration(
                  hintText: 'Start typing your note here...',
                  border: InputBorder.none,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
