import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_notes/main.dart';

void main() {
  group('detectTextDirection unit tests', () {
    test('returns LTR for English text', () {
      expect(detectTextDirection('Hello World'), TextDirection.ltr);
      expect(detectTextDirection('a'), TextDirection.ltr);
    });

    test('returns RTL for Arabic text', () {
      expect(detectTextDirection('مرحبا بالعالم'), TextDirection.rtl);
      expect(detectTextDirection('سلام'), TextDirection.rtl);
    });

    test('returns RTL for Hebrew text', () {
      expect(detectTextDirection('שלום עליכם'), TextDirection.rtl);
    });

    test(
      'returns direction based on first strong character for mixed text',
      () {
        expect(detectTextDirection('Hello مرحبا'), TextDirection.ltr);
        expect(detectTextDirection('مرحبا Hello'), TextDirection.rtl);
        expect(detectTextDirection('123 Hello مرحبا'), TextDirection.ltr);
        expect(detectTextDirection('123 مرحبا Hello'), TextDirection.rtl);
      },
    );

    test('returns fallback for empty or neutral text', () {
      expect(detectTextDirection(''), null);
      expect(detectTextDirection('', TextDirection.ltr), TextDirection.ltr);
      expect(detectTextDirection('', TextDirection.rtl), TextDirection.rtl);
      expect(
        detectTextDirection('12345 !@#\$%', TextDirection.ltr),
        TextDirection.ltr,
      );
    });
  });

  group('Notes App Widget Tests', () {
    testWidgets('Notes prototype navigation test', (WidgetTester tester) async {
      await tester.pumpWidget(const NotesApp());

      expect(find.text('Notes'), findsOneWidget);
      expect(find.text('No notes yet. Tap + to add one.'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);

      expect(find.text('Edit Note'), findsNothing);

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      expect(find.text('Edit Note'), findsOneWidget);
      expect(find.byType(TextField), findsNWidgets(2)); // Title & Body

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(find.text('Notes'), findsOneWidget);
      expect(find.text('Edit Note'), findsNothing);
    });

    testWidgets(
      'Dynamic text direction in EditorScreen (English, Arabic, Mixed)',
      (WidgetTester tester) async {
        await tester.pumpWidget(const NotesApp());

        await tester.tap(find.byIcon(Icons.add));
        await tester.pumpAndSettle();

        final textFields = find.byType(TextField);
        expect(textFields, findsNWidgets(2));

        // 1. Initial empty state should fallback to ambient locale direction (LTR)
        TextField titleWidget = tester.widget(textFields.first);
        TextField bodyWidget = tester.widget(textFields.last);
        expect(titleWidget.textDirection, TextDirection.ltr);
        expect(bodyWidget.textDirection, TextDirection.ltr);

        // 2. Type English text in title and body
        await tester.enterText(textFields.first, 'English Note Title');
        await tester.enterText(
          textFields.last,
          'This is an English note body.',
        );
        await tester.pumpAndSettle();

        titleWidget = tester.widget(textFields.first);
        bodyWidget = tester.widget(textFields.last);
        expect(titleWidget.textDirection, TextDirection.ltr);
        expect(bodyWidget.textDirection, TextDirection.ltr);

        // 3. Type Arabic text in title and body
        await tester.enterText(textFields.first, 'عنوان ملاحظة');
        await tester.enterText(textFields.last, 'هذا نص ملاحظة باللغة العربية');
        await tester.pumpAndSettle();

        titleWidget = tester.widget(textFields.first);
        bodyWidget = tester.widget(textFields.last);
        expect(titleWidget.textDirection, TextDirection.rtl);
        expect(bodyWidget.textDirection, TextDirection.rtl);

        // 4. Mixed text starting with Arabic
        await tester.enterText(textFields.last, 'مرحبا Hello world');
        await tester.pumpAndSettle();

        bodyWidget = tester.widget(textFields.last);
        expect(bodyWidget.textDirection, TextDirection.rtl);

        // 5. Mixed text starting with English
        await tester.enterText(textFields.last, 'Hello مرحبا بالعالم');
        await tester.pumpAndSettle();

        bodyWidget = tester.widget(textFields.last);
        expect(bodyWidget.textDirection, TextDirection.ltr);

        // 6. Clearing text restores fallback (LTR)
        await tester.enterText(textFields.last, '');
        await tester.pumpAndSettle();

        bodyWidget = tester.widget(textFields.last);
        expect(bodyWidget.textDirection, TextDirection.ltr);
      },
    );

    testWidgets('Dynamic text direction in search bar and search dialog', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const NotesApp());

      // Open AppBar Search
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      final searchFieldFinder = find.byType(TextField);
      expect(searchFieldFinder, findsOneWidget);

      TextField searchField = tester.widget(searchFieldFinder);
      expect(searchField.textDirection, TextDirection.ltr);

      // Type Arabic in search field
      await tester.enterText(searchFieldFinder, 'بحث عن ملاحظة');
      await tester.pumpAndSettle();

      searchField = tester.widget(searchFieldFinder);
      expect(searchField.textDirection, TextDirection.rtl);

      // Close search
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      // Open Search Dialog
      await tester.tap(find.byIcon(Icons.filter_list));
      await tester.pumpAndSettle();

      expect(find.text('Search Notes'), findsOneWidget);
      final dialogSearchFinder = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      );
      expect(dialogSearchFinder, findsOneWidget);

      TextField dialogSearchField = tester.widget(dialogSearchFinder);
      expect(dialogSearchField.textDirection, TextDirection.ltr);

      // Type Arabic in dialog search field
      await tester.enterText(dialogSearchFinder, 'بحث');
      await tester.pumpAndSettle();

      dialogSearchField = tester.widget(dialogSearchFinder);
      expect(dialogSearchField.textDirection, TextDirection.rtl);

      // Type English in dialog search field
      await tester.enterText(dialogSearchFinder, 'Search query');
      await tester.pumpAndSettle();

      dialogSearchField = tester.widget(dialogSearchFinder);
      expect(dialogSearchField.textDirection, TextDirection.ltr);
    });

    testWidgets('Respects ambient RTL UI locale for empty fields', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: child!,
            );
          },
          home: const EditorScreen(),
        ),
      );

      final textFields = find.byType(TextField);

      // Empty field under RTL locale should fallback to RTL
      TextField titleWidget = tester.widget(textFields.first);
      expect(titleWidget.textDirection, TextDirection.rtl);

      // Typing English should override to LTR
      await tester.enterText(textFields.first, 'English title');
      await tester.pumpAndSettle();

      titleWidget = tester.widget(textFields.first);
      expect(titleWidget.textDirection, TextDirection.ltr);
    });
  });
}
