import 'package:flutter/material.dart';

import 'pwa/pwa_update_client.dart';
import 'pwa/pwa_update_host.dart';
import 'screens/clubs_screen.dart';
import 'screens/fairway_tracker_screen.dart';
import 'screens/range_drill_screen.dart';
import 'screens/scorecard_screen.dart';
import 'services/cloud_sync_service.dart';
import 'services/desktop_database.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await preparePwaSession();
  await initDesktopDatabase();
  await initializeFirebase();
  runApp(const GolfDiaryApp());
}

class GolfDiaryApp extends StatelessWidget {
  const GolfDiaryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Golf Diary',
      theme: buildGolfTheme(),
      darkTheme: buildGolfTheme(brightness: Brightness.dark),
      home: const HomeShell(),
    );
  }
}

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
        case 3:
          _scorecardKey.currentState?.loadScorecard();
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return PwaUpdateHost(
      child: Scaffold(
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
