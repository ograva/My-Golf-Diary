import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> settleSheet(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> openCourseSheet(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('oncourse-course-summary')));
  await settleSheet(tester);
}

/// Types [name] into the course sheet and submits it with the keyboard action.
Future<void> submitCourseName(WidgetTester tester, String name) async {
  await openCourseSheet(tester);
  await tester.enterText(find.widgetWithText(TextField, 'Course name'), name);
  await tester.testTextInput.receiveAction(TextInputAction.done);
  FocusManager.instance.primaryFocus?.unfocus();
  await settleSheet(tester);
}

/// Types [query] into the course sheet and taps the [option] suggestion.
Future<void> pickCourse(
    WidgetTester tester, String query, String option) async {
  await openCourseSheet(tester);
  await tester.enterText(find.widgetWithText(TextField, 'Course name'), query);
  await tester.pump();
  await tester.tap(find.text(option));
  await settleSheet(tester);
}

Future<void> _selectMode(WidgetTester tester, String key) async {
  final segment = find.byKey(ValueKey(key));
  await tester.ensureVisible(segment);
  await tester.pump();
  await tester.tap(segment);
  await tester.pump();
}

Future<void> selectSimulator(WidgetTester tester) =>
    _selectMode(tester, 'oncourse-mode-simulator');

Future<void> selectFairway(WidgetTester tester) =>
    _selectMode(tester, 'oncourse-mode-course');

/// Scrolls the stroke log (below the Concede | Finish Hole row) into view.
Future<void> expandShotList(WidgetTester tester) async {
  final expander = find.byKey(const ValueKey('oncourse-shots-list-expander'));
  await tester.scrollUntilVisible(expander, 200,
      scrollable: find.byType(Scrollable).first);
  await tester.ensureVisible(expander);
  await settleSheet(tester);
}

String parSummaryLabel(WidgetTester tester) {
  final text = tester.widget<Text>(find.descendant(
    of: find.byKey(const ValueKey('oncourse-par-summary')),
    matching: find.byType(Text),
  ));
  return text.data!;
}
