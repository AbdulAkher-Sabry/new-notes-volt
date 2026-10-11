import 'package:flutter/material.dart';

void main() {
  runApp(const NotesApp());
}

class NotesApp extends StatelessWidget {
  const NotesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Notes Prototype',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const NotesListScreen(),
    );
  }
}

class NotesListScreen extends StatelessWidget {
  const NotesListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notes')),
      body: const Center(child: Text('No notes yet. Tap + to add one.')),
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

class EditorScreen extends StatelessWidget {
  const EditorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Note')),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: TextField(
          maxLines: null,
          expands: true,
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.start,
          decoration: InputDecoration(
            hintText: 'Start typing your note here...',
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }
}
