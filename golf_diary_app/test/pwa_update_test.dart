import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golf_diary_app/pwa/pwa_published_build.dart';
import 'package:golf_diary_app/pwa/pwa_update_client.dart';
import 'package:golf_diary_app/pwa/pwa_update_host.dart';
import 'package:golf_diary_app/pwa/pwa_update_policy.dart';
import 'package:golf_diary_app/theme/app_theme.dart';

void main() {
  group('shouldOfferPwaUpdate', () {
    test('offers a published build the running app does not have', () {
      expect(
        shouldOfferPwaUpdate(runningBuildId: 'aaa', publishedBuildId: 'bbb'),
        isTrue,
      );
    });

    test('stays quiet when the published build is the one already running', () {
      expect(
        shouldOfferPwaUpdate(runningBuildId: 'aaa', publishedBuildId: 'aaa'),
        isFalse,
      );
    });

    test('stays quiet when the publish check has no id', () {
      expect(
        shouldOfferPwaUpdate(runningBuildId: 'aaa', publishedBuildId: null),
        isFalse,
      );
      expect(
        shouldOfferPwaUpdate(runningBuildId: 'aaa', publishedBuildId: '  '),
        isFalse,
      );
    });

    test('stays quiet after Later for that same published build', () {
      expect(
        shouldOfferPwaUpdate(
          runningBuildId: 'aaa',
          publishedBuildId: 'bbb',
          dismissedBuildId: 'bbb',
        ),
        isFalse,
      );
      expect(
        shouldOfferPwaUpdate(
          runningBuildId: 'aaa',
          publishedBuildId: 'ccc',
          dismissedBuildId: 'bbb',
        ),
        isTrue,
      );
    });
  });

  testWidgets('Update is the action that starts the reload', (tester) async {
    final client = _FakePwaUpdateClient(
      const PwaPublishedBuild(buildId: 'published-2', version: '1.0.0+1'),
    );
    await _pumpHost(tester, client);

    expect(find.byKey(PwaUpdateDialog.dialogKey), findsOneWidget);
    expect(find.text('New version published'), findsOneWidget);
    expect(client.applyCount, 0);

    await tester.tap(find.byKey(PwaUpdateDialog.updateKey));
    await tester.pumpAndSettle();

    expect(client.applyCount, 1);
    expect(find.byKey(PwaUpdateDialog.dialogKey), findsNothing);
  });

  testWidgets('Later leaves the running version in place', (tester) async {
    final client = _FakePwaUpdateClient(
      const PwaPublishedBuild(buildId: 'published-2'),
    );
    await _pumpHost(tester, client);

    await tester.tap(find.byKey(PwaUpdateDialog.laterKey));
    await tester.pumpAndSettle();

    expect(client.applyCount, 0);
    expect(find.byKey(PwaUpdateDialog.dialogKey), findsNothing);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.byKey(PwaUpdateDialog.dialogKey), findsNothing);
  });

  testWidgets('a matching publish does not interrupt the round',
      (tester) async {
    final client = _FakePwaUpdateClient(
      const PwaPublishedBuild(buildId: 'running-1'),
    );
    await _pumpHost(tester, client);
    expect(find.byKey(PwaUpdateDialog.dialogKey), findsNothing);
  });
}

Future<void> _pumpHost(WidgetTester tester, _FakePwaUpdateClient client) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: buildGolfTheme(),
      home: PwaUpdateHost(
        enabled: true,
        recheckInterval: null,
        runningBuildId: 'running-1',
        client: client,
        child: const Scaffold(body: Text('On the course')),
      ),
    ),
  );
  await tester.pump();
  await tester.pumpAndSettle();
}

class _FakePwaUpdateClient extends PwaUpdateClient {
  _FakePwaUpdateClient(this.published);

  final PwaPublishedBuild? published;
  int applyCount = 0;

  @override
  Future<PwaPublishedBuild?> fetchPublishedBuild() async => published;

  @override
  Future<void> applyUpdate() async {
    applyCount += 1;
  }
}
