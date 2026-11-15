import 'package:flutter/material.dart';

import '../models/diary_context_note.dart';
import '../models/golfer_profile.dart';
import '../services/diary_model.dart';
import '../services/golfer_profile_store.dart';
import '../services/swing_diary_service.dart';
import '../ui/header_action_policy.dart';
import 'account_avatar_app_bar_menu.dart';
import 'caddy_invite_app_bar_button.dart';
import 'caddy_invite_sheet.dart';
import 'diary_launcher.dart';

/// Trailing AppBar cluster: tier-aware diary/QR + account avatar (SYNC-005).
class SharedHeaderActions extends StatelessWidget {
  const SharedHeaderActions({
    super.key,
    required this.tab,
    this.roundId,
    this.courseName,
    this.diary,
    this.diaryStore,
    this.diaryEntryKey,
    this.diarySource,
    this.caddyInviteKey = 'on-course-invite-caddy',
  });

  final HeaderTabContext tab;
  final String? roundId;
  final String? courseName;
  final DiaryModel? diary;
  final SwingDiaryService? diaryStore;
  final String? diaryEntryKey;
  final DiaryContextSource? diarySource;
  final String caddyInviteKey;

  GolferProfile _profile(BuildContext context) {
    return GolferProfileScope.maybeOf(context)?.profile ?? const GolferProfile();
  }

  @override
  Widget build(BuildContext context) {
    final roundActive = roundId != null && roundId!.isNotEmpty;
    final policy = HeaderActionPolicy.resolve(
      profile: _profile(context),
      tab: tab,
      roundActive: roundActive,
    );

    final actions = <Widget>[];

    if (policy.showCaddyPinned && roundActive) {
      actions.add(
        CaddyInviteIconButton(
          valueKey: caddyInviteKey,
          roundId: roundId!,
          courseName: courseName ?? '',
        ),
      );
    }

    if (policy.showDiaryPinned &&
        diaryEntryKey != null &&
        diarySource != null) {
      actions.add(
        DiaryEntryButton(
          entryKey: diaryEntryKey!,
          diary: diary,
          store: diaryStore,
          entrySource: diarySource,
        ),
      );
    }

    if (policy.usePlayOverflow) {
      actions.add(
        _PlayHeaderOverflowButton(
          showDiary: policy.showDiaryInOverflow,
          showCaddy: policy.showCaddyInOverflow && roundActive,
          diaryEntryKey: diaryEntryKey,
          diary: diary,
          diaryStore: diaryStore,
          diarySource: diarySource,
          roundId: roundActive ? roundId : null,
          courseName: courseName ?? '',
          caddyInviteKey: caddyInviteKey,
        ),
      );
    } else if (policy.showCaddyInOverflow &&
        roundActive &&
        !policy.showCaddyPinned) {
      actions.add(
        PopupMenuButton<String>(
          key: const Key('shell-header-overflow-btn'),
          tooltip: 'More',
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            if (value == 'caddy') {
              showCaddyInviteSheet(
                context,
                roundId: roundId!,
                courseName: courseName ?? '',
              );
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem<String>(
              value: 'caddy',
              child: ListTile(
                key: ValueKey(caddyInviteKey),
                leading: const Icon(Icons.qr_code_2),
                title: const Text('Invite caddy'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      );
    }

    actions.add(const AccountAvatarAppBarMenu());

    return Row(mainAxisSize: MainAxisSize.min, children: actions);
  }
}

class _PlayHeaderOverflowButton extends StatelessWidget {
  const _PlayHeaderOverflowButton({
    required this.showDiary,
    required this.showCaddy,
    required this.diaryEntryKey,
    required this.diary,
    required this.diaryStore,
    required this.diarySource,
    required this.roundId,
    required this.courseName,
    required this.caddyInviteKey,
  });

  final bool showDiary;
  final bool showCaddy;
  final String? diaryEntryKey;
  final DiaryModel? diary;
  final SwingDiaryService? diaryStore;
  final DiaryContextSource? diarySource;
  final String? roundId;
  final String courseName;
  final String caddyInviteKey;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      key: const Key('shell-header-overflow-btn'),
      tooltip: 'More',
      icon: const Icon(Icons.more_vert),
      onSelected: (value) async {
        switch (value) {
          case 'caddy':
            if (roundId == null) return;
            await showCaddyInviteSheet(
              context,
              roundId: roundId!,
              courseName: courseName,
            );
          case 'diary':
            if (diarySource == null) return;
            await showSwingDiarySheet(
              context,
              diary: diary,
              store: diaryStore,
              entrySource: diarySource,
            );
        }
      },
      itemBuilder: (context) {
        final items = <PopupMenuEntry<String>>[];
        if (showCaddy && roundId != null) {
          items.add(
            PopupMenuItem<String>(
              value: 'caddy',
              child: ListTile(
                key: ValueKey(caddyInviteKey),
                leading: const Icon(Icons.qr_code_2),
                title: const Text('Invite caddy'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          );
        }
        if (showDiary && diaryEntryKey != null) {
          items.add(
            PopupMenuItem<String>(
              value: 'diary',
              child: ListTile(
                key: ValueKey(diaryEntryKey),
                leading: const Icon(Icons.auto_stories_outlined),
                title: const Text('Swing diary'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          );
        }
        return items;
      },
    );
  }
}