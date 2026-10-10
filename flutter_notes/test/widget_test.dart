import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_notes/main.dart';

void main() {
  testWidgets('Notes prototype navigation test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const NotesApp());

    // Verify we are on the initial list screen.
    expect(find.text('Notes'), findsOneWidget);
    expect(find.text('No notes yet. Tap + to add one.'), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);

    // Verify EditorScreen is not visible yet.
    expect(find.text('Edit Note'), findsNothing);

    // Tap the '+' icon and trigger a frame.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle(); // Wait for navigation animation

    // Verify we navigated to the EditorScreen.
    expect(find.text('Edit Note'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);

    // Tap the back button to return to the list screen.
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle(); // Wait for back navigation animation

    // Verify we are back on the list screen.
    expect(find.text('Notes'), findsOneWidget);
    expect(find.text('Edit Note'), findsNothing);
  });
}
