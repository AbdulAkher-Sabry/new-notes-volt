import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_notes/main.dart';

void main() {
  group('getDirectionFromText unit tests', () {
    test('defaults to LTR for empty string', () {
      expect(getDirectionFromText(''), TextDirection.ltr);
    });

    test('defaults to LTR for spaces or punctuation only', () {
      expect(getDirectionFromText('   !@#\$%^&*()  '), TextDirection.ltr);
    });

    test('returns LTR for English-first input', () {
      expect(getDirectionFromText('Hello world'), TextDirection.ltr);
    });

    test('returns RTL for Arabic-first input', () {
      expect(getDirectionFromText('مرحبا بك'), TextDirection.rtl);
    });

    test(
      'returns RTL when Arabic character appears before English character in mixed text',
      () {
        expect(getDirectionFromText('مرحبا Hello'), TextDirection.rtl);
      },
    );

    test(
      'returns LTR when English character appears before Arabic character in mixed text',
      () {
        expect(getDirectionFromText('Hello مرحبا'), TextDirection.ltr);
      },
    );
  });

  group('Widget and Navigation Integration Tests', () {
    testWidgets('Initial launch opens on Notes screen with empty state', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const NotesApp());

      expect(find.text('Notes'), findsOneWidget);
      expect(find.text('No notes yet. Tap + to add one.'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.text('Edit Note'), findsNothing);
    });

    testWidgets('Tapping + opens EditorScreen with default LTR direction', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const NotesApp());

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      expect(find.text('Edit Note'), findsOneWidget);
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.textDirection, TextDirection.ltr);
      expect(textField.textAlign, TextAlign.start);
    });

    testWidgets(
      'Automatic text direction updates dynamically on typing and clearing',
      (WidgetTester tester) async {
        await tester.pumpWidget(const NotesApp());

        await tester.tap(find.byIcon(Icons.add));
        await tester.pumpAndSettle();

        // Type Arabic text
        await tester.enterText(find.byType(TextField), 'مرحبا');
        await tester.pump();

        TextField textField = tester.widget<TextField>(find.byType(TextField));
        expect(textField.textDirection, TextDirection.rtl);

        // Clear text
        await tester.enterText(find.byType(TextField), '');
        await tester.pump();

        textField = tester.widget<TextField>(find.byType(TextField));
        expect(textField.textDirection, TextDirection.ltr);

        // Type English text
        await tester.enterText(find.byType(TextField), 'Hello note');
        await tester.pump();

        textField = tester.widget<TextField>(find.byType(TextField));
        expect(textField.textDirection, TextDirection.ltr);
      },
    );

    testWidgets('Saving note on back navigation and returning to list screen', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const NotesApp());

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'First saved note');
      await tester.pump();

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(find.text('Notes'), findsOneWidget);
      expect(find.text('No notes yet. Tap + to add one.'), findsNothing);
      expect(find.text('First saved note'), findsOneWidget);
    });

    testWidgets(
      'Opening existing note and updating it without duplicate entries',
      (WidgetTester tester) async {
        await tester.pumpWidget(const NotesApp());

        // Create initial note
        await tester.tap(find.byIcon(Icons.add));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), 'Original note content');
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();

        expect(find.text('Original note content'), findsOneWidget);

        // Open note for editing
        await tester.tap(find.text('Original note content'));
        await tester.pumpAndSettle();

        expect(find.text('Edit Note'), findsOneWidget);

        // Update content
        await tester.enterText(find.byType(TextField), 'Updated note content');
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();

        expect(find.text('Original note content'), findsNothing);
        expect(find.text('Updated note content'), findsOneWidget);
        expect(find.byType(ListTile), findsOneWidget);
      },
    );

    testWidgets('Empty notes are not saved or duplicates created', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const NotesApp());

      // Open editor and go back without entering text
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(find.text('No notes yet. Tap + to add one.'), findsOneWidget);

      // Create note
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Note to clear');
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(find.text('Note to clear'), findsOneWidget);

      // Edit note to be empty
      await tester.tap(find.text('Note to clear'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '');
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(find.text('Note to clear'), findsNothing);
      expect(find.text('No notes yet. Tap + to add one.'), findsOneWidget);
    });
  });
}
