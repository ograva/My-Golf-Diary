import 'package:flutter/material.dart';

import '../pwa/pwa_update_host.dart';
import '../widgets/caddy_golfer_merge_host.dart';
import '../services/golfer_profile_store.dart';
import 'clubs_screen.dart';
import 'fairway_tracker_screen.dart';
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

  List<Widget> get _pages => [
        ClubsScreen(
          key: _bagKey,
          onProfileSettingsChanged: _onProfileSettingsChanged,
        ),
        RangeDrillScreen(
          key: _rangeKey,
          onProfileSettingsChanged: _onProfileSettingsChanged,
        ),
        FairwayTrackerScreen(
          key: _courseKey,
          onProfileSettingsChanged: _onProfileSettingsChanged,
        ),
        ScorecardScreen(
          key: _scorecardKey,
          onProfileSettingsChanged: _onProfileSettingsChanged,
        ),
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

  void _onProfileSettingsChanged() {
    _bagKey.currentState?.reload();
    _rangeKey.currentState?.reload();
  }

  @override
  Widget build(BuildContext context) {
    return PwaUpdateHost(
      child: Scaffold(
        body: CaddyGolferMergeHost(
          onSessionChanged: () {
            _courseKey.currentState?.reloadActiveRound();
            _scorecardKey.currentState?.loadScorecard();
          },
          child: IndexedStack(
            index: _index,
            children: _pages,
          ),
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