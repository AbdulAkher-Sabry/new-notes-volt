import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_notes/main.dart';

void main() {
  group('Text direction detection unit tests', () {
    test('Detects English-first input as LTR', () {
      expect(getDirectionOfText('Hello world'), TextDirection.ltr);
      expect(getDirectionOfText('123 Hello'), TextDirection.ltr);
    });

    test('Detects Arabic-first input as RTL', () {
      expect(getDirectionOfText('مرحبا بالعالم'), TextDirection.rtl);
      expect(getDirectionOfText('123 مرحبا'), TextDirection.rtl);
    });

    test('Handles mixed text based on first strong character', () {
      expect(getDirectionOfText('Hello مرحبا'), TextDirection.ltr);
      expect(getDirectionOfText('مرحبا Hello'), TextDirection.rtl);
    });

    test(
      'Defaults to LTR for empty text or text without strong characters',
      () {
        expect(getDirectionOfText(''), TextDirection.ltr);
        expect(getDirectionOfText('!123 #\$%'), TextDirection.ltr);
      },
    );
  });

  group('Notes App Widget Tests', () {
    testWidgets('Opens on Notes screen and + button opens editor', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const NotesApp());

      // Verify initial list screen state
      expect(find.text('Notes'), findsOneWidget);
      expect(find.text('No notes yet. Tap + to add one.'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);

      // Tap + button
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Verify EditorScreen is displayed
      expect(find.text('Edit Note'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);

      // Verify empty editor defaults to LTR
      final TextField textField = tester.widget(find.byType(TextField));
      expect(textField.textDirection, TextDirection.ltr);

      // Navigate back
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(find.text('Notes'), findsOneWidget);
    });

    testWidgets(
      'Dynamic text direction updates for Arabic, English, mixed, and clearing input',
      (WidgetTester tester) async {
        await tester.pumpWidget(const NotesApp());

        await tester.tap(find.byIcon(Icons.add));
        await tester.pumpAndSettle();

        // Arabic input -> RTL
        await tester.enterText(find.byType(TextField), 'مرحبا');
        await tester.pump();
        TextField textField = tester.widget(find.byType(TextField));
        expect(textField.textDirection, TextDirection.rtl);

        // English input -> LTR
        await tester.enterText(find.byType(TextField), 'Hello world');
        await tester.pump();
        textField = tester.widget(find.byType(TextField));
        expect(textField.textDirection, TextDirection.ltr);

        // Clear text -> LTR default
        await tester.enterText(find.byType(TextField), '');
        await tester.pump();
        textField = tester.widget(find.byType(TextField));
        expect(textField.textDirection, TextDirection.ltr);

        // Arabic after clearing -> RTL
        await tester.enterText(find.byType(TextField), 'أهلا وسهلا');
        await tester.pump();
        textField = tester.widget(find.byType(TextField));
        expect(textField.textDirection, TextDirection.rtl);

        // Mixed text with numbers first
        await tester.enterText(find.byType(TextField), '123 hello');
        await tester.pump();
        textField = tester.widget(find.byType(TextField));
        expect(textField.textDirection, TextDirection.ltr);

        await tester.enterText(find.byType(TextField), '123 مرحبا');
        await tester.pump();
        textField = tester.widget(find.byType(TextField));
        expect(textField.textDirection, TextDirection.rtl);
      },
    );

    testWidgets('Saves note and returns to list preserving content', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const NotesApp());

      // Open editor and type note
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Buy groceries');
      await tester.pump();

      // Return to list
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      // Check note is displayed in list and empty prompt is gone
      expect(find.text('Buy groceries'), findsOneWidget);
      expect(find.text('No notes yet. Tap + to add one.'), findsNothing);
    });

    testWidgets('Opens and edits existing note without creating duplicates', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const NotesApp());

      // Create initial note
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Original Note');
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(find.text('Original Note'), findsOneWidget);

      // Tap saved note to edit
      await tester.tap(find.text('Original Note'));
      await tester.pumpAndSettle();

      // Verify controller contains existing text
      final TextField textField = tester.widget(find.byType(TextField));
      expect(textField.controller?.text, 'Original Note');

      // Edit text
      await tester.enterText(find.byType(TextField), 'Updated Note');
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      // Verify note updated and no duplicate created
      expect(find.text('Updated Note'), findsOneWidget);
      expect(find.text('Original Note'), findsNothing);
      expect(find.byType(ListTile), findsNWidgets(1));
    });

    testWidgets('Empty-note behavior is consistent when created or cleared', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const NotesApp());

      // Open new editor and leave empty
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      // Empty note should not be saved
      expect(find.text('No notes yet. Tap + to add one.'), findsOneWidget);
      expect(find.byType(ListTile), findsNothing);

      // Create a note
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Temporary note');
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(find.text('Temporary note'), findsOneWidget);

      // Open note and clear text
      await tester.tap(find.text('Temporary note'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '   ');
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      // Cleared note should be removed
      expect(find.text('No notes yet. Tap + to add one.'), findsOneWidget);
      expect(find.byType(ListTile), findsNothing);
    });
  });
}
