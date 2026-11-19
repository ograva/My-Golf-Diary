import 'package:flutter_test/flutter_test.dart';
import 'package:golf_diary_app/models/caddy_session.dart';
import 'package:golf_diary_app/services/caddy_event_applier.dart';
import 'package:golf_diary_app/services/caddy_launch_config.dart';
import 'package:golf_diary_app/services/caddy_pairing_service.dart';
import 'package:golf_diary_app/services/caddy_round_channel_store.dart';
import 'package:golf_diary_app/services/local_database_service.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

void main() {
  Future<void> useFreshDatabase() async {
    await LocalDatabaseService.debugClose();
    LocalDatabaseService.debugSetFileName('golf_diary_mgdv501.db');
    await deleteDatabase(
        join(await getDatabasesPath(), 'golf_diary_mgdv501.db'));
  }

  Future<void> restoreDatabase() async {
    await LocalDatabaseService.debugClose();
    LocalDatabaseService.debugSetFileName('golf_diary.db');
  }

  test('CaddyLaunchConfig builds invite query without uid', () {
    final url = CaddyLaunchConfig.buildInviteUrl('abc123opaque');
    expect(url, contains('mode=caddy'));
    expect(url, contains('request=abc123opaque'));
    expect(url, isNot(contains('uid=')));
  });

  test('mint → redeem → stroke event updates golfer SQLite', () async {
    await useFreshDatabase();
    addTearDown(restoreDatabase);

    final channel = MemoryCaddyRoundChannelStore();
    final db = LocalDatabaseService.instance;
    final roundId = await db.startNewRound(
      courseName: 'Club Intramuros Golf Course',
      par: 4,
    );

    final golferPairing = CaddyPairingService(
      database: db,
      channelStore: channel,
    );
    final caddyPairing = CaddyPairingService(
      database: db,
      channelStore: channel,
    );

    final session = await golferPairing.mintInvite(
      roundId: roundId,
      courseName: 'Club Intramuros Golf Course',
    );
    expect(session.requestToken, isNotEmpty);

    final redeemed = await caddyPairing.redeemInvite(session.requestToken);
    expect(redeemed, isNotNull);
    expect(redeemed!.status, CaddySessionStatus.active);

    final event = await caddyPairing.publishEvent(
      channelId: session.channelId,
      roundId: roundId,
      type: CaddyEventType.strokeAdd,
      holeNumber: 1,
      authorUid: 'caddy-test',
    );

    final applier = CaddyEventApplier(database: db);
    await applier.apply(
      event,
      courseName: 'Club Intramuros Golf Course',
    );

    final hole = await db.getHoleScore(roundId, 1);
    expect(hole, isNotNull);
    expect(hole!.strokes, 1);

    final shots = await db.getShotsForHole(roundId, 1);
    expect(shots, hasLength(1));
  });

  test('revoke marks channel revoked in memory store', () async {
    await useFreshDatabase();
    addTearDown(restoreDatabase);
    final channel = MemoryCaddyRoundChannelStore();
    final db = LocalDatabaseService.instance;
    final roundId = await db.startNewRound(
      courseName: 'Club Intramuros Golf Course',
      par: 4,
    );
    final pairing = CaddyPairingService(database: db, channelStore: channel);
    final session = await pairing.mintInvite(
      roundId: roundId,
      courseName: 'Club Intramuros Golf Course',
    );
    await pairing.revokeSession(session.channelId);
    final data = await channel.readChannel(session.channelId);
    expect(data?['status'], 'revoked');
  });
}
