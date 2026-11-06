import 'package:flutter/material.dart';

import 'screens/clubs_screen.dart';
import 'screens/fairway_tracker_screen.dart';
import 'screens/range_drill_screen.dart';
import 'services/cloud_sync_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
  int _index = 1;

  static const _pages = [
    ClubsScreen(),
    FairwayTrackerScreen(),
    RangeDrillScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.golf_course), label: 'My Bag'),
          NavigationDestination(icon: Icon(Icons.my_location), label: 'On Course'),
          NavigationDestination(icon: Icon(Icons.fitness_center), label: 'Range'),
        ],
      ),
    );
  }
}
