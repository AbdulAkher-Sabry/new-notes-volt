import 'package:flutter/material.dart';
import 'package:flutter_notes/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('getAutoTextDirection unit tests', () {
    test('detects directional first strong character accurately', () {
      expect(getAutoTextDirection(''), TextDirection.ltr);
      expect(getAutoTextDirection('   '), TextDirection.ltr);
      expect(getAutoTextDirection('Hello'), TextDirection.ltr);
      expect(getAutoTextDirection('مرحبا'), TextDirection.rtl);
      expect(getAutoTextDirection('123 مرحبا'), TextDirection.rtl);
      expect(getAutoTextDirection('123 Hello'), TextDirection.ltr);
      expect(getAutoTextDirection('Hello مرحبا'), TextDirection.ltr);
      expect(getAutoTextDirection('مرحبا Hello'), TextDirection.rtl);
    });
  });

  group('Widget and Navigation Tests', () {
    testWidgets('App opens on Notes screen and + button opens editor', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(const NotesApp());
      await tester.pumpAndSettle();

      expect(find.text('Notes'), findsOneWidget);
      expect(find.text('No notes yet. Tap + to add one.'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);

      expect(find.text('Edit Note'), findsNothing);

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      expect(find.text('Edit Note'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(find.text('Notes'), findsOneWidget);
      expect(find.text('Edit Note'), findsNothing);
    });

    testWidgets('English-first input receives LTR text direction', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(const NotesApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      final textFieldFinder = find.byType(TextField);
      await tester.enterText(textFieldFinder, 'Hello world');
      await tester.pumpAndSettle();

      final TextField textField = tester.widget(textFieldFinder);
      expect(textField.textDirection, TextDirection.ltr);
    });

    testWidgets('Arabic-first input receives RTL text direction', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(const NotesApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      final textFieldFinder = find.byType(TextField);
      await tester.enterText(textFieldFinder, 'مرحبا بك');
      await tester.pumpAndSettle();

      final TextField textField = tester.widget(textFieldFinder);
      expect(textField.textDirection, TextDirection.rtl);
    });

    testWidgets(
      'Mixed-language text direction depends on first strong character',
      (WidgetTester tester) async {
        SharedPreferences.setMockInitialValues({});
        await tester.pumpWidget(const NotesApp());
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.add));
        await tester.pumpAndSettle();

        final textFieldFinder = find.byType(TextField);

        await tester.enterText(textFieldFinder, 'Hello مرحبا');
        await tester.pumpAndSettle();
        TextField textField = tester.widget(textFieldFinder);
        expect(textField.textDirection, TextDirection.ltr);

        await tester.enterText(textFieldFinder, 'مرحبا Hello');
        await tester.pumpAndSettle();
        textField = tester.widget(textFieldFinder);
        expect(textField.textDirection, TextDirection.rtl);
      },
    );

    testWidgets(
      'Clearing text and typing in another language updates direction',
      (WidgetTester tester) async {
        SharedPreferences.setMockInitialValues({});
        await tester.pumpWidget(const NotesApp());
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.add));
        await tester.pumpAndSettle();

        final textFieldFinder = find.byType(TextField);

        await tester.enterText(textFieldFinder, 'مرحبا');
        await tester.pumpAndSettle();
        TextField textField = tester.widget(textFieldFinder);
        expect(textField.textDirection, TextDirection.rtl);

        await tester.enterText(textFieldFinder, '');
        await tester.pumpAndSettle();
        textField = tester.widget(textFieldFinder);
        expect(textField.textDirection, TextDirection.ltr);

        await tester.enterText(textFieldFinder, 'Welcome');
        await tester.pumpAndSettle();
        textField = tester.widget(textFieldFinder);
        expect(textField.textDirection, TextDirection.ltr);
      },
    );

    testWidgets('Saving a note and returning to list preserves content', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(const NotesApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'My first saved note');
      await tester.pumpAndSettle();

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(find.text('My first saved note'), findsOneWidget);
      expect(find.text('No notes yet. Tap + to add one.'), findsNothing);
    });

    testWidgets(
      'Opening and editing existing note updates it without duplicates',
      (WidgetTester tester) async {
        SharedPreferences.setMockInitialValues({});
        await tester.pumpWidget(const NotesApp());
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.add));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), 'Original Note Content');
        await tester.pumpAndSettle();
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();

        expect(find.text('Original Note Content'), findsOneWidget);

        await tester.tap(find.text('Original Note Content'));
        await tester.pumpAndSettle();

        expect(find.text('Original Note Content'), findsOneWidget);

        await tester.enterText(find.byType(TextField), 'Updated Note Content');
        await tester.pumpAndSettle();

        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();

        expect(find.text('Updated Note Content'), findsOneWidget);
        expect(find.text('Original Note Content'), findsNothing);
      },
    );

    testWidgets('Empty notes are handled consistently', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(const NotesApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(find.text('No notes yet. Tap + to add one.'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Temporary text');
      await tester.pumpAndSettle();
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(find.text('Temporary text'), findsOneWidget);

      await tester.tap(find.text('Temporary text'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '   ');
      await tester.pumpAndSettle();
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(find.text('No notes yet. Tap + to add one.'), findsOneWidget);
    });

    testWidgets('Notes persist across application restarts', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(const NotesApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Persistent note item');
      await tester.pumpAndSettle();
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(find.text('Persistent note item'), findsOneWidget);

      await tester.pumpWidget(const NotesApp());
      await tester.pumpAndSettle();

      expect(find.text('Persistent note item'), findsOneWidget);
    });
  });
}
