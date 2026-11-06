import 'package:flutter/material.dart';

import 'screens/clubs_screen.dart';
import 'screens/fairway_tracker_screen.dart';
import 'screens/range_drill_screen.dart';
import 'screens/scorecard_screen.dart';
import 'services/cloud_sync_service.dart';
import 'services/desktop_database.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
      themeMode: ThemeMode.system, // follows device dark/light preference
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
  int _index = 1;
  final _bagKey = GlobalKey<ClubsScreenState>();
  final _scorecardKey = GlobalKey<ScorecardScreenState>();

  late final List<Widget> _pages = [
    ClubsScreen(key: _bagKey),
    const FairwayTrackerScreen(),
    ScorecardScreen(key: _scorecardKey),
    const RangeDrillScreen(),
  ];

  void _onTabSelected(int i) {
    setState(() => _index = i);
    if (i == 0) {
      _bagKey.currentState?.reloadClubs();
    }
    if (i == 2) {
      _scorecardKey.currentState?.loadScorecard();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            icon: Icon(Icons.golf_course_outlined),
            selectedIcon: Icon(Icons.golf_course),
            label: 'My Bag',
          ),
          NavigationDestination(
            key: ValueKey('shell-tab-oncourse'),
            icon: Icon(Icons.my_location_outlined),
            selectedIcon: Icon(Icons.my_location),
            label: 'On Course',
          ),
          NavigationDestination(
            key: ValueKey('shell-tab-scorecard'),
            icon: Icon(Icons.scoreboard_outlined),
            selectedIcon: Icon(Icons.scoreboard),
            label: 'Scorecard',
          ),
          NavigationDestination(
            key: ValueKey('shell-tab-range'),
            icon: Icon(Icons.fitness_center_outlined),
            selectedIcon: Icon(Icons.fitness_center),
            label: 'Range',
          ),
        ],
      ),
    );
  }
}
