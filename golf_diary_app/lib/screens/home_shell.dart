import 'package:flutter/material.dart';

import '../pwa/pwa_update_host.dart';
import '../services/golfer_profile_store.dart';
import 'clubs_screen.dart';
import 'fairway_tracker_screen.dart';
import 'golfer_profile_settings_screen.dart';
import 'range_drill_screen.dart';
import 'scorecard_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  /// Opens on On Course, which is the third tab.
  int _index = 2;

  final _bagKey = GlobalKey<ClubsScreenState>();
  final _courseKey = GlobalKey<FairwayTrackerScreenState>();
  final _scorecardKey = GlobalKey<ScorecardScreenState>();
  final _rangeKey = GlobalKey<RangeDrillScreenState>();

  late final List<Widget> _pages = [
    ClubsScreen(key: _bagKey),
    RangeDrillScreen(key: _rangeKey),
    FairwayTrackerScreen(key: _courseKey),
    ScorecardScreen(key: _scorecardKey),
  ];

  void _onTabSelected(int i) {
    setState(() => _index = i);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _index != i) return;
      switch (i) {
        case 0:
          _bagKey.currentState?.reload();
          break;
        case 1:
          _rangeKey.currentState?.reload();
          break;
        case 3:
          _scorecardKey.currentState?.loadScorecard();
          break;
      }
    });
  }

  Future<void> _openProfileSettings() async {
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
      _bagKey.currentState?.reload();
      _rangeKey.currentState?.reload();
    }
  }

  String get _shellTitle => switch (_index) {
        0 => 'My Bag',
        1 => 'Range',
        2 => 'On Course',
        3 => 'Scorecard',
        _ => 'Golf Diary',
      };

  @override
  Widget build(BuildContext context) {
    return PwaUpdateHost(
      child: Scaffold(
        appBar: AppBar(
          title: Text(_shellTitle),
          actions: [
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'profile') _openProfileSettings();
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
            ),
          ],
        ),
        body: IndexedStack(
          index: _index,
          children: _pages,
        ),
        bottomNavigationBar: NavigationBar(
          key: const ValueKey('shell-nav-bar'),
          selectedIndex: _index,
          onDestinationSelected: _onTabSelected,
          destinations: const [
            NavigationDestination(
              key: ValueKey('shell-tab-bag'),
              icon: Icon(Icons.golf_course),
              label: 'My Bag',
            ),
            NavigationDestination(
              key: ValueKey('shell-tab-range'),
              icon: Icon(Icons.fitness_center),
              label: 'Range',
            ),
            NavigationDestination(
              key: ValueKey('shell-tab-oncourse'),
              icon: Icon(Icons.my_location),
              label: 'On Course',
            ),
            NavigationDestination(
              key: ValueKey('shell-tab-scorecard'),
              icon: Icon(Icons.scoreboard),
              label: 'Scorecard',
            ),
          ],
        ),
      ),
    );
  }
}