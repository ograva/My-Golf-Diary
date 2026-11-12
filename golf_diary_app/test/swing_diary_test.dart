import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golf_diary_app/app_check_config.dart';
import 'package:golf_diary_app/main.dart';
import 'package:golf_diary_app/models/golf_models.dart';
import 'package:golf_diary_app/screens/range_drill_screen.dart';
import 'package:golf_diary_app/services/diary_model.dart';
import 'package:golf_diary_app/services/local_database_service.dart';
import 'package:golf_diary_app/services/swing_diary_service.dart';
import 'package:golf_diary_app/theme/app_theme.dart';
import 'package:golf_diary_app/widgets/swing_diary_sheet.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class FakeDiaryModel implements DiaryModel {
  FakeDiaryModel({
    this.available = true,
    this.reply = 'Solid contact.',
    this.hold = false,
    this.error,
  });

  @override
  final bool available;
  final String reply;

  /// When true, [generate] waits until [DiaryCancel.cancel] runs.
  final bool hold;
  Object? error;
  int calls = 0;
  String? lastPrompt;

  @override
  String get modelName => 'gemini-3.8-flash';

  @override
  String get location => 'global';

  @override
  Stream<String> generate(String prompt, {DiaryCancel? cancel}) async* {
    calls += 1;
    lastPrompt = prompt;
    if (cancel?.isCancelled == true) throw const DiaryCancelled();
    if (hold) {
      final gate = Completer<void>();
      cancel?.bindAbort(() {
        if (!gate.isCompleted) gate.complete();
      });
      await gate.future;
      if (cancel?.isCancelled == true) throw const DiaryCancelled();
    }
    if (error != null) throw error!;
    yield reply;
  }
}

void main() {
  test('an empty App Check site key does not activate', () {
    expect(shouldActivateAppCheck(isWeb: true, siteKey: ''), isFalse);
    expect(shouldActivateAppCheck(isWeb: true, siteKey: '   '), isFalse);
    expect(shouldActivateAppCheck(isWeb: false, siteKey: kRecaptchaSiteKey),
        isFalse);
    expect(shouldActivateAppCheck(isWeb: true, siteKey: kRecaptchaSiteKey),
        isTrue);
  });

  final db = LocalDatabaseService.instance;

  Future<void> useFreshDatabase() async {
    await LocalDatabaseService.debugClose();
    LocalDatabaseService.debugSetFileName('golf_diary_swing.db');
    await deleteDatabase(join(await getDatabasesPath(), 'golf_diary_swing.db'));
  }

  Future<void> restoreDatabase() async {
    await LocalDatabaseService.debugClose();
    LocalDatabaseService.debugSetFileName('golf_diary.db');
  }

  Future<void> pumpRange(WidgetTester tester, FakeDiaryModel model) async {
    await tester.pumpWidget(MaterialApp(
      theme: buildGolfTheme(),
      home: RangeDrillScreen(diary: model),
    ));
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)));
    await tester.pump();
  }

  Future<void> openDiary(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey('range-swing-diary-btn')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)));
    await tester.pump();
  }

  testWidgets('opt-in dismiss does not call the model', (tester) async {
    tester.view.physicalSize = const Size(1600, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.runAsync(useFreshDatabase);
    addTearDown(() => tester.runAsync(restoreDatabase));
    final model = FakeDiaryModel();
    await pumpRange(tester, model);

    expect(
        find.byKey(const ValueKey('diary-evaluation-log-btn')), findsNothing);
    await openDiary(tester);
    await tester.tap(find.byKey(const ValueKey('diary-opt-in-dismiss')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(model.calls, 0);
    expect(find.byKey(const ValueKey('diary-opt-in-dismiss')), findsNothing);
  });

  testWidgets(
      'summarize today stores the reply and a follow-up survives restart',
      (tester) async {
    tester.view.physicalSize = const Size(1600, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.runAsync(useFreshDatabase);
    addTearDown(() => tester.runAsync(restoreDatabase));
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    await tester.runAsync(() async {
      await db.saveRangeDrill(RangeDrillLog(
        id: 'drill_yesterday',
        clubId: 'driver',
        shotCount: 10,
        minYards: 130,
        maxYards: 150,
        avgYards: 140,
        tempoNotes: 'YESTERDAY CUE',
        timestamp: yesterday.millisecondsSinceEpoch,
        drillId: 'rng-drl-tempo-3to1',
      ));
      await db.saveRangeDrill(RangeDrillLog(
        id: 'drill_today',
        clubId: 'driver',
        shotCount: 10,
        minYards: 150,
        maxYards: 170,
        avgYards: 160,
        tempoNotes: 'TODAY CUE',
        timestamp: DateTime.now().millisecondsSinceEpoch,
        drillId: 'rng-drl-tempo-3to1',
      ));
    });

    final model = FakeDiaryModel();
    await pumpRange(tester, model);
    await openDiary(tester);
    await tester.tap(find.byKey(const ValueKey('diary-opt-in-continue')));
    await tester.pump();
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.pump();

    final summarize = find.byKey(const ValueKey('diary-summarize-today-btn'));
    await tester.ensureVisible(summarize);
    await tester.tap(summarize);
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)));
    await tester.pump();

    expect(model.calls, 1);
    expect(model.lastPrompt, contains('YESTERDAY CUE'));
    expect(model.lastPrompt, contains('TODAY CUE'));
    expect(model.lastPrompt, contains('3:1 Tour Tempo Rhythm'));
    expect(find.text('Solid contact.'), findsOneWidget);
    expect(find.textContaining('saved'), findsOneWidget);
    expect(find.textContaining('phase=done'), findsOneWidget);
    final summarizeButton = tester.widget<OutlinedButton>(
        find.byKey(const ValueKey('diary-summarize-today-btn')));
    expect(summarizeButton.onPressed, isNotNull);
    final evaluations =
        await tester.runAsync(() => SwingDiaryService().listEvaluations());
    expect(evaluations!.where((row) => row.kind == 'evaluation').length, 1);
    expect(evaluations.singleWhere((row) => row.kind == 'evaluation').content,
        'Solid contact.');
    expect(evaluations.where((row) => row.kind == 'periodic_summary'), isEmpty);

    await tester.enterText(find.byKey(const ValueKey('diary-composer-field')),
        'How was the face?');
    await tester.tap(find.byKey(const ValueKey('diary-send-btn')));
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)));
    await tester.pump();
    expect(model.calls, 2);
    expect(find.text('How was the face?'), findsOneWidget);
    Navigator.of(tester.element(find.byType(SwingDiarySheet))).pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await pumpRange(tester, model);
    await openDiary(tester);
    expect(find.byKey(const ValueKey('diary-opt-in-continue')), findsNothing);
    expect(find.text('How was the face?'), findsOneWidget);
    expect(find.text('Solid contact.'), findsWidgets);
  });

  testWidgets('offline diary disables send and the log does not call the model',
      (tester) async {
    tester.view.physicalSize = const Size(1600, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.runAsync(useFreshDatabase);
    addTearDown(() => tester.runAsync(restoreDatabase));
    await tester.runAsync(() async {
      await SwingDiaryService().setOptedIn(true);
      final database = await db.database;
      final now = DateTime.now().millisecondsSinceEpoch;
      await database.insert('range_evaluations', {
        'id': 'eval_seed',
        'kind': 'evaluation',
        'session_id': null,
        'session_date': '2026-11-11',
        'content': 'Saved evaluation text',
        'prompt_tokens': 12,
        'covered_through_ms': null,
        'referenced_drill_ids_json': '[]',
        'referenced_club_ids_json': '[]',
        'timestamp': now,
        'is_synced': 0,
        'updated_at_ms': now,
        'deleted': 0,
      });
      await database.insert('range_evaluations', {
        'id': 'sum_seed',
        'kind': 'periodic_summary',
        'session_id': null,
        'session_date': '2026-11-01',
        'content': 'Saved brief text',
        'prompt_tokens': 40,
        'covered_through_ms': now - 1000,
        'referenced_drill_ids_json': '[]',
        'referenced_club_ids_json': '[]',
        'timestamp': now - 1000,
        'is_synced': 0,
        'updated_at_ms': now,
        'deleted': 0,
      });
    });

    final model = FakeDiaryModel(available: false);
    await pumpRange(tester, model);
    expect(
        find.byKey(const ValueKey('diary-evaluation-log-btn')), findsNothing);

    await tester.pumpWidget(
        MaterialApp(theme: buildGolfTheme(), home: const GolfDiaryApp()));
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)));
    await tester.pump();
    expect(find.byKey(const ValueKey('shell-tab-range')), findsOneWidget);
    expect(
        find.byKey(const ValueKey('diary-evaluation-log-btn')), findsNothing);

    await pumpRange(tester, model);
    await openDiary(tester);
    expect(find.text('Your range log is still on this phone.'), findsOneWidget);
    final send = tester
        .widget<ElevatedButton>(find.byKey(const ValueKey('diary-send-btn')));
    expect(send.onPressed, isNull);
    final summarize = tester.widget<OutlinedButton>(
        find.byKey(const ValueKey('diary-summarize-today-btn')));
    expect(summarize.onPressed, isNull);

    await tester.tap(find.byKey(const ValueKey('diary-evaluation-log-btn')));
    await tester.pump();
    expect(find.text('Saved evaluation text'), findsOneWidget);
    expect(find.text('Progress brief'), findsOneWidget);
    expect(find.text('Saved brief text'), findsOneWidget);
    expect(model.calls, 0);
  });

  testWidgets('an empty evaluation log says so', (tester) async {
    tester.view.physicalSize = const Size(1600, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.runAsync(useFreshDatabase);
    addTearDown(() => tester.runAsync(restoreDatabase));
    await tester.runAsync(() => SwingDiaryService().setOptedIn(true));
    final model = FakeDiaryModel();
    await pumpRange(tester, model);
    await openDiary(tester);
    await tester.tap(find.byKey(const ValueKey('diary-evaluation-log-btn')));
    await tester.pump();
    expect(find.text('No evaluations yet.'), findsOneWidget);
    expect(model.calls, 0);
  });

  Future<void> seedTodayDrill() async {
    await SwingDiaryService().setOptedIn(true);
    await db.saveRangeDrill(RangeDrillLog(
      id: 'drill_today',
      clubId: 'driver',
      shotCount: 10,
      minYards: 150,
      maxYards: 170,
      avgYards: 160,
      tempoNotes: 'TODAY CUE',
      timestamp: DateTime.now().millisecondsSinceEpoch,
    ));
  }

  testWidgets('cancel leaves no evaluation and shows the debug line',
      (tester) async {
    tester.view.physicalSize = const Size(1600, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.runAsync(useFreshDatabase);
    addTearDown(() => tester.runAsync(restoreDatabase));
    await tester.runAsync(seedTodayDrill);
    final model = FakeDiaryModel(hold: true);
    await pumpRange(tester, model);
    await openDiary(tester);

    final summarize = find.byKey(const ValueKey('diary-summarize-today-btn'));
    await tester.ensureVisible(summarize);
    await tester.tap(summarize);
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)));
    await tester.pump();
    expect(find.byKey(const ValueKey('diary-eval-status')), findsOneWidget);
    expect(find.text('Waiting for Vertex'), findsOneWidget);
    expect(find.byKey(const ValueKey('diary-eval-debug')), findsOneWidget);
    expect(find.textContaining('phase=request'), findsOneWidget);
    expect(find.textContaining('model=gemini-3.8-flash'), findsOneWidget);
    expect(find.textContaining('appCheck=missing'), findsOneWidget);
    expect(find.byKey(const ValueKey('diary-eval-cancel')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('diary-eval-cancel')));
    await tester.pump();
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)));
    await tester.pump();

    expect(find.text('Evaluation cancelled'), findsOneWidget);
    expect(find.textContaining('cancelled by user'), findsOneWidget);
    final evaluations =
        await tester.runAsync(() => SwingDiaryService().listEvaluations());
    expect(evaluations!.where((row) => row.kind == 'evaluation'), isEmpty);
    final summarizeButton = tester.widget<OutlinedButton>(
        find.byKey(const ValueKey('diary-summarize-today-btn')));
    expect(summarizeButton.onPressed, isNotNull);
  });

  testWidgets('a failed evaluation can be tried again', (tester) async {
    tester.view.physicalSize = const Size(1600, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.runAsync(useFreshDatabase);
    addTearDown(() => tester.runAsync(restoreDatabase));
    await tester.runAsync(seedTodayDrill);
    final model = FakeDiaryModel(error: StateError('vertex down'));
    await pumpRange(tester, model);
    await openDiary(tester);

    final summarize = find.byKey(const ValueKey('diary-summarize-today-btn'));
    await tester.ensureVisible(summarize);
    await tester.tap(summarize);
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)));
    await tester.pump();

    expect(find.textContaining('StateError'), findsOneWidget);
    expect(find.textContaining('phase=failed'), findsOneWidget);
    expect(find.byKey(const ValueKey('diary-eval-retry')), findsOneWidget);
    final evaluations =
        await tester.runAsync(() => SwingDiaryService().listEvaluations());
    expect(evaluations!.where((row) => row.kind == 'evaluation'), isEmpty);

    model.error = null;
    await tester.tap(find.byKey(const ValueKey('diary-eval-retry')));
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)));
    await tester.pump();

    expect(model.calls, 2);
    expect(find.text('Solid contact.'), findsOneWidget);
    expect(find.textContaining('phase=done'), findsOneWidget);
    expect(find.textContaining('saved'), findsOneWidget);
    final saved =
        await tester.runAsync(() => SwingDiaryService().listEvaluations());
    expect(saved!.where((row) => row.kind == 'evaluation').length, 1);
    final summarizeButton = tester.widget<OutlinedButton>(
        find.byKey(const ValueKey('diary-summarize-today-btn')));
    expect(summarizeButton.onPressed, isNotNull);
  });
}
