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

  group('BidiTextEditingController unit and widget tests', () {
    testWidgets('buildTextSpan attaches RLM and LRM prefixes per line', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                final controller = BidiTextEditingController(
                  text: 'English line 1\nمرحبا line 2\nEnglish line 3',
                );
                final span = controller.buildTextSpan(
                  context: context,
                  style: null,
                  withComposing: false,
                );

                expect(span.children, isNotNull);
                expect(
                  span.children!.length,
                  equals(5),
                ); // 3 line spans + 2 newlines

                final span1 = span.children![0] as TextSpan;
                final newline1 = span.children![1] as TextSpan;
                final span2 = span.children![2] as TextSpan;
                final newline2 = span.children![3] as TextSpan;
                final span3 = span.children![4] as TextSpan;

                expect(span1.text, equals('\u200EEnglish line 1'));
                expect(newline1.text, equals('\n'));
                expect(span2.text, equals('\u200Fمرحبا line 2'));
                expect(newline2.text, equals('\n'));
                expect(span3.text, equals('\u200EEnglish line 3'));

                return Container();
              },
            ),
          ),
        ),
      );
    });

    testWidgets('Independent layout direction per paragraph', (
      WidgetTester tester,
    ) async {
      final controller = BidiTextEditingController(
        text: 'English paragraph\nمرحبا بالعالم\nAnother English paragraph',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DynamicDirectionTextField(
              controller: controller,
              maxLines: null,
            ),
          ),
        ),
      );

      final editableFinder = find.byType(EditableText);
      expect(editableFinder, findsOneWidget);
      final EditableTextState state = tester.state(editableFinder);
      final renderEditable = state.renderEditable;

      // Line 1 ('E' at offset 0): LTR start
      final p1 = renderEditable
          .getEndpointsForSelection(const TextSelection.collapsed(offset: 0))
          .first
          .point;

      // Line 2 ('م' at offset 18): RTL start
      final p2 = renderEditable
          .getEndpointsForSelection(const TextSelection.collapsed(offset: 18))
          .first
          .point;

      // Line 3 ('A' at offset 31): LTR start
      final p3 = renderEditable
          .getEndpointsForSelection(const TextSelection.collapsed(offset: 31))
          .first
          .point;

      expect(p1.dx, lessThan(p2.dx));
      expect(p3.dx, lessThan(p2.dx));
    });

    testWidgets('English -> Enter -> Arabic scenario', (
      WidgetTester tester,
    ) async {
      final controller = BidiTextEditingController();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DynamicDirectionTextField(
              controller: controller,
              maxLines: null,
            ),
          ),
        ),
      );

      // Type English -> Enter -> Arabic
      await tester.enterText(
        find.byType(TextField),
        'First line in English\nمرحبا بالعالم',
      );
      await tester.pumpAndSettle();

      final EditableTextState state = tester.state(find.byType(EditableText));
      final renderEditable = state.renderEditable;

      final p1 = renderEditable
          .getEndpointsForSelection(const TextSelection.collapsed(offset: 0))
          .first
          .point;
      final p2 = renderEditable
          .getEndpointsForSelection(const TextSelection.collapsed(offset: 22))
          .first
          .point;

      expect(p1.dx, lessThan(p2.dx));
    });

    testWidgets('Arabic -> Enter -> English scenario', (
      WidgetTester tester,
    ) async {
      final controller = BidiTextEditingController();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DynamicDirectionTextField(
              controller: controller,
              maxLines: null,
            ),
          ),
        ),
      );

      // Type Arabic -> Enter -> English
      await tester.enterText(
        find.byType(TextField),
        'فقرة باللغة العربية\nSecond paragraph in English',
      );
      await tester.pumpAndSettle();

      final EditableTextState state = tester.state(find.byType(EditableText));
      final renderEditable = state.renderEditable;

      final p1 = renderEditable
          .getEndpointsForSelection(const TextSelection.collapsed(offset: 0))
          .first
          .point;
      final p2 = renderEditable
          .getEndpointsForSelection(const TextSelection.collapsed(offset: 20))
          .first
          .point;

      expect(p1.dx, greaterThan(p2.dx));
    });

    testWidgets('Empty paragraph between different directions', (
      WidgetTester tester,
    ) async {
      final controller = BidiTextEditingController(text: 'مرحبا\n\nHello');
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DynamicDirectionTextField(
              controller: controller,
              maxLines: null,
            ),
          ),
        ),
      );

      final span = controller.buildTextSpan(
        context: tester.element(find.byType(TextField)),
        style: null,
        withComposing: false,
      );

      expect(span.children, isNotNull);
      expect(span.children!.length, equals(5));

      final spanLine1 = span.children![0] as TextSpan; // 'مرحبا'
      final spanEmpty = span.children![2] as TextSpan; // '' (empty line)
      final spanLine3 = span.children![4] as TextSpan; // 'Hello'

      // Verify line 1 and empty line 2 have RTL prefix (\u200F), line 3 has LTR prefix (\u200E)
      expect(spanLine1.text, startsWith('\u200F'));
      expect(spanEmpty.text, equals('\u200F'));
      expect(spanLine3.text, startsWith('\u200E'));
    });

    testWidgets(
      'Paragraph beginning with numbers or punctuation followed by Arabic/English',
      (WidgetTester tester) async {
        final controller = BidiTextEditingController(
          text: '123! #123 مرحبا\n123! #123 Hello',
        );
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: DynamicDirectionTextField(
                controller: controller,
                maxLines: null,
              ),
            ),
          ),
        );

        final EditableTextState state = tester.state(find.byType(EditableText));
        final renderEditable = state.renderEditable;

        final p1 = renderEditable
            .getEndpointsForSelection(const TextSelection.collapsed(offset: 0))
            .first
            .point;
        final p2 = renderEditable
            .getEndpointsForSelection(const TextSelection.collapsed(offset: 16))
            .first
            .point;

        expect(p1.dx, greaterThan(p2.dx));
      },
    );

    testWidgets('Editing in middle, inserting and deleting newlines', (
      WidgetTester tester,
    ) async {
      final controller = BidiTextEditingController(text: 'Hello\nمرحبا');
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DynamicDirectionTextField(
              controller: controller,
              maxLines: null,
            ),
          ),
        ),
      );

      // Insert text in the middle of line 1
      controller.value = const TextEditingValue(
        text: 'Hello World\nمرحبا',
        selection: TextSelection.collapsed(offset: 11),
      );
      await tester.pumpAndSettle();
      expect(controller.text, equals('Hello World\nمرحبا'));

      // Delete newline
      controller.value = const TextEditingValue(
        text: 'Hello World مرحبا',
        selection: TextSelection.collapsed(offset: 11),
      );
      await tester.pumpAndSettle();
      expect(controller.text, equals('Hello World مرحبا'));

      // Re-insert newline
      controller.value = const TextEditingValue(
        text: 'Hello World\nمرحبا',
        selection: TextSelection.collapsed(offset: 12),
      );
      await tester.pumpAndSettle();
      expect(controller.text, equals('Hello World\nمرحبا'));
    });

    testWidgets('Cursor movement and selection across paragraph boundaries', (
      WidgetTester tester,
    ) async {
      final controller = BidiTextEditingController(text: 'Hello\nمرحبا');
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DynamicDirectionTextField(
              controller: controller,
              maxLines: null,
            ),
          ),
        ),
      );

      // Select across paragraph boundary
      controller.selection = const TextSelection(
        baseOffset: 2,
        extentOffset: 8,
      );
      await tester.pumpAndSettle();

      expect(controller.selection.baseOffset, equals(2));
      expect(controller.selection.extentOffset, equals(8));
      expect(controller.text.substring(2, 8), equals('llo\nمر'));
    });

    testWidgets('Pasting multiline mixed-direction text', (
      WidgetTester tester,
    ) async {
      final controller = BidiTextEditingController();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DynamicDirectionTextField(
              controller: controller,
              maxLines: null,
            ),
          ),
        ),
      );

      const pastedText = 'Line 1 English\nالسطر الثاني عربي\nLine 3 English';
      await tester.enterText(find.byType(TextField), pastedText);
      await tester.pumpAndSettle();

      final EditableTextState state = tester.state(find.byType(EditableText));
      final renderEditable = state.renderEditable;

      final p1 = renderEditable
          .getEndpointsForSelection(const TextSelection.collapsed(offset: 0))
          .first
          .point;
      final p2 = renderEditable
          .getEndpointsForSelection(const TextSelection.collapsed(offset: 15))
          .first
          .point;
      final p3 = renderEditable
          .getEndpointsForSelection(const TextSelection.collapsed(offset: 33))
          .first
          .point;

      expect(p1.dx, lessThan(p2.dx));
      expect(p3.dx, lessThan(p2.dx));
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
