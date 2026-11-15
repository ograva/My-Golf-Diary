import 'package:flutter/material.dart';

import '../screens/golfer_profile_settings_screen.dart';
import '../services/golfer_profile_store.dart';

/// Legacy profile menu — superseded by [AccountAvatarAppBarMenu] + [SharedHeaderActions].
@Deprecated('Use SharedHeaderActions / account settings instead')
class GolferProfileAppBarMenu extends StatelessWidget {
  const GolferProfileAppBarMenu({super.key, this.onProfileChanged});

  final VoidCallback? onProfileChanged;

  Future<void> _open(BuildContext context) async {
    final store = GolferProfileScope.of(context);
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (context) => GolferProfileSettingsScreen(
          initialProfile: store.profile,
        ),
      ),
    );
    if (changed == true) {
      await store.refresh();
      onProfileChanged?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (value) {
        if (value == 'profile') _open(context);
      },
      itemBuilder: (context) => [
        const PopupMenuItem<String>(
          value: 'profile',
          child: ListTile(
            key: ValueKey('settings-golfer-profile-entry'),
            leading: Icon(Icons.person_outline),
            title: Text('Golfer profile'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }
}