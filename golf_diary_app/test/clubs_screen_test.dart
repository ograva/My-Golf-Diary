import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golf_diary_app/models/golf_models.dart';
import 'package:golf_diary_app/screens/clubs_screen.dart';
import 'package:golf_diary_app/theme/app_theme.dart';

void main() {
  final club = Club(
    id: 'driver',
    name: 'Driver',
    category: 'wood',
    brand: 'Callaway',
    model: 'Paradym',
    avgDistance: 220,
  );

  Future<void> openDialog(WidgetTester tester, Widget dialog) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildGolfTheme(),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => dialog,
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  testWidgets('Add club button is a plus icon on the left side of the header without label text', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ClubsScreen()));
    await tester.pump();

    expect(find.byType(FloatingActionButton), findsNothing);
    expect(find.text('Add club'), findsNothing);

    final appBar = tester.widget<AppBar>(find.byType(AppBar));
    expect(appBar.leading, isA<IconButton>());

    final addBtnFinder = find.byKey(const Key('add-club-button'));
    expect(addBtnFinder, findsOneWidget);
    expect(
      find.descendant(of: addBtnFinder, matching: find.byIcon(Icons.add)),
      findsOneWidget,
    );

    final addCenter = tester.getCenter(addBtnFinder);
    final titleCenter = tester.getCenter(find.text('My Bag'));
    expect(addCenter.dx, lessThan(titleCenter.dx));

    await tester.tap(addBtnFinder);
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AlertDialog, 'Add club'), findsOneWidget);
  });

  testWidgets('Edit club dialog saves name, brand, model, and category', (tester) async {
    ClubEditResult? result;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildGolfTheme(),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await showDialog<ClubEditResult>(
                  context: context,
                  builder: (_) => EditClubDialog(club: club),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextField, 'Club name'), 'Big Driver');
    await tester.enterText(find.widgetWithText(TextField, 'Brand (optional)'), 'TaylorMade');
    await tester.enterText(find.widgetWithText(TextField, 'Model (optional)'), 'Qi10');
    await tester.tap(find.widgetWithText(DropdownButtonFormField<String>, 'Category'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Iron').last);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Save'));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.deleted, isFalse);
    expect(result!.club!.name, 'Big Driver');
    expect(result!.club!.brand, 'TaylorMade');
    expect(result!.club!.model, 'Qi10');
    expect(result!.club!.category, 'iron');
    expect(result!.club!.avgDistance, 220);
  });

  testWidgets('Delete asks for confirmation before removing the club', (tester) async {
    ClubEditResult? result;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildGolfTheme(),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await showDialog<ClubEditResult>(
                  context: context,
                  builder: (_) => EditClubDialog(club: club),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Delete Driver from your bag? This cannot be undone.'), findsOneWidget);
    expect(result, isNull);

    await tester.tap(find.widgetWithText(TextButton, 'Cancel').last);
    await tester.pumpAndSettle();
    expect(find.text('Edit club'), findsOneWidget);
    expect(result, isNull);

    await tester.tap(find.widgetWithText(TextButton, 'Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(
      of: find.widgetWithText(AlertDialog, 'Delete club'),
      matching: find.widgetWithText(TextButton, 'Delete'),
    ));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.deleted, isTrue);
  });

  testWidgets('Swing notes dialog returns the edited text', (tester) async {
    String? saved;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildGolfTheme(),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                saved = await showDialog<String>(
                  context: context,
                  builder: (_) => SwingNotesDialog(club: club),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Swing notes'), 'Smooth tempo');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Save notes'));
    await tester.pumpAndSettle();
    expect(saved, 'Smooth tempo');
  });

  testWidgets('empty club name stays in the edit dialog', (tester) async {
    await openDialog(tester, EditClubDialog(club: club));
    await tester.enterText(find.widgetWithText(TextField, 'Club name'), '   ');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Save'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a club name'), findsOneWidget);
    expect(find.text('Edit club'), findsOneWidget);
  });
}
