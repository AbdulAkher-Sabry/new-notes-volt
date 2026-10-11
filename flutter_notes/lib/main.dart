import 'package:flutter/material.dart';

void main() {
  runApp(const NotesApp());
}

/// Detects text direction based on the first strong directional character (Unicode Bidi algorithm).
/// Returns [TextDirection.rtl] for RTL scripts (Arabic, Hebrew, etc.),
/// [TextDirection.ltr] for LTR scripts (English, Latin, etc.),
/// or [fallback] (or null) if no strong character is found.
TextDirection? detectTextDirection(String text, [TextDirection? fallback]) {
  if (text.isEmpty) return fallback;

  // Regular expressions for strong RTL and LTR characters
  final rtlRegExp = RegExp(
    r'[\u0590-\u05FF\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF]',
  );
  final ltrRegExp = RegExp(r'[a-zA-Z\u00C0-\u024F\u0370-\u03FF\u0400-\u04FF]');

  for (final rune in text.runes) {
    final char = String.fromCharCode(rune);
    if (rtlRegExp.hasMatch(char)) {
      return TextDirection.rtl;
    }
    if (ltrRegExp.hasMatch(char)) {
      return TextDirection.ltr;
    }
  }

  return fallback;
}

/// A [TextEditingController] that dynamically decorates each paragraph/line with
/// directional Unicode formatting marks (RLM `\u200F` / LRM `\u200E`) based on
/// each paragraph's detected text direction.
/// This enables independent RTL/LTR direction per paragraph in multi-line text fields
/// without mutating the raw underlying string content or selection indices.
class BidiTextEditingController extends TextEditingController {
  BidiTextEditingController({super.text});

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    bool? withComposing,
  }) {
    final defaultDir = Directionality.maybeOf(context) ?? TextDirection.ltr;
    final lines = text.split('\n');
    final children = <InlineSpan>[];

    TextDirection? lastKnownDirection;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      TextDirection? lineDir = detectTextDirection(line);

      if (lineDir != null) {
        lastKnownDirection = lineDir;
      } else {
        lineDir = lastKnownDirection ?? detectTextDirection(text, defaultDir);
      }

      final String prefix = lineDir == TextDirection.rtl ? '\u200F' : '\u200E';

      children.add(TextSpan(text: prefix + line));
      if (i < lines.length - 1) {
        children.add(const TextSpan(text: '\n'));
      }
    }

    return TextSpan(style: style, children: children);
  }
}

/// A [TextField] wrapper that automatically determines text direction based on content,
/// falling back to the ambient UI [Directionality].
class DynamicDirectionTextField extends StatefulWidget {
  const DynamicDirectionTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.decoration,
    this.maxLines = 1,
    this.minLines,
    this.expands = false,
    this.onChanged,
    this.onSubmitted,
    this.textInputAction,
    this.keyboardType,
    this.style,
    this.textAlign = TextAlign.start,
    this.autofocus = false,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final InputDecoration? decoration;
  final int? maxLines;
  final int? minLines;
  final bool expands;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputAction? textInputAction;
  final TextInputType? keyboardType;
  final TextStyle? style;
  final TextAlign textAlign;
  final bool autofocus;

  @override
  State<DynamicDirectionTextField> createState() =>
      _DynamicDirectionTextFieldState();
}

class _DynamicDirectionTextFieldState extends State<DynamicDirectionTextField> {
  late TextEditingController _controller;
  bool _internalController = false;
  TextDirection? _detectedDirection;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      _controller = BidiTextEditingController();
      _internalController = true;
    }
    _controller.addListener(_onTextChanged);
    _updateDirection(_controller.text);
  }

  @override
  void didUpdateWidget(DynamicDirectionTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller?.removeListener(_onTextChanged);
      if (_internalController) {
        _controller.dispose();
        _internalController = false;
      }
      if (widget.controller != null) {
        _controller = widget.controller!;
      } else {
        _controller = BidiTextEditingController();
        _internalController = true;
      }
      _controller.addListener(_onTextChanged);
      _updateDirection(_controller.text);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    if (_internalController) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _onTextChanged() {
    _updateDirection(_controller.text);
  }

  void _updateDirection(String text) {
    final direction = detectTextDirection(text);
    if (direction != _detectedDirection) {
      setState(() {
        _detectedDirection = direction;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final fallbackDirection = Directionality.of(context);
    final effectiveDirection = _detectedDirection ?? fallbackDirection;

    return TextField(
      controller: _controller,
      focusNode: widget.focusNode,
      decoration: widget.decoration,
      maxLines: widget.maxLines,
      minLines: widget.minLines,
      expands: widget.expands,
      textDirection: effectiveDirection,
      textAlign: widget.textAlign,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      textInputAction: widget.textInputAction,
      keyboardType: widget.keyboardType,
      style: widget.style,
      autofocus: widget.autofocus,
    );
  }
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

class NotesListScreen extends StatefulWidget {
  const NotesListScreen({super.key});

  @override
  State<NotesListScreen> createState() => _NotesListScreenState();
}

class _NotesListScreenState extends State<NotesListScreen> {
  late final TextEditingController _searchController;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _searchController = BidiTextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Search Notes'),
          content: DynamicDirectionTextField(
            controller: _searchController,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Enter search query...',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? DynamicDirectionTextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search notes...',
                  border: InputBorder.none,
                ),
              )
            : const Text('Notes'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showSearchDialog,
          ),
        ],
      ),
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

class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _bodyController;

  @override
  void initState() {
    super.initState();
    _titleController = BidiTextEditingController();
    _bodyController = BidiTextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Note')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DynamicDirectionTextField(
              controller: _titleController,
              style: Theme.of(context).textTheme.headlineSmall,
              decoration: const InputDecoration(
                hintText: 'Note Title',
                border: InputBorder.none,
              ),
            ),
            const Divider(),
            Expanded(
              child: DynamicDirectionTextField(
                controller: _bodyController,
                maxLines: null,
                expands: true,
                textAlign: TextAlign.start,
                decoration: const InputDecoration(
                  hintText: 'Start typing your note here...',
                  border: InputBorder.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
