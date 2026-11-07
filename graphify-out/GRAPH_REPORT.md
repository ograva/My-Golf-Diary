# Graph Report - My-Golf-Diary  (2026-11-07)

## Corpus Check
- cluster-only mode — file stats not available

## Summary
- 1266 nodes · 1689 edges · 81 communities (42 shown, 39 thin omitted)
- Extraction: 87% EXTRACTED · 13% INFERRED · 0% AMBIGUOUS · INFERRED: 228 edges (avg confidence: 0.85)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `b3e67d58`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- Community 1
- Community 2
- Community 3
- Community 4
- Community 5
- Community 6
- Community 7
- Community 8
- Community 9
- Community 10
- Community 11
- Community 12
- Community 13
- Community 14
- Community 15
- Community 16
- Community 17
- Community 18
- Community 19
- Community 20
- Community 21
- Community 22
- Community 23
- Community 24
- Community 25
- Community 26
- Community 27
- Community 28
- Community 29
- Community 30
- Community 31
- Community 32
- Community 33
- Community 34
- Community 35
- Community 36
- Community 37
- Community 38
- Community 39
- Community 40
- Community 41
- Community 43
- Community 44
- Community 45
- Community 46
- Community 47
- Community 48
- Community 50
- Community 51
- Community 52
- Community 53
- Community 54
- Community 55
- Community 56
- Community 57
- Community 58
- Community 59
- Community 60

## God Nodes (most connected - your core abstractions)
1. `b()` - 70 edges
2. `c()` - 45 edges
3. `p()` - 28 edges
4. `d()` - 23 edges
5. `o()` - 22 edges
6. `Win32Window` - 21 edges
7. `j()` - 20 edges
8. `i()` - 14 edges
9. `gk()` - 12 edges
10. `dependencies` - 12 edges

## Surprising Connections (you probably didn't know these)
- `wWinMain()` --calls--> `CreateAndAttachConsole()`  [INFERRED]
  golf_diary_app/windows/runner/main.cpp → golf_diary_app/windows/runner/utils.cpp
- `FlutterWindow` --inherits--> `Win32Window`  [EXTRACTED]
  golf_diary_app/windows/runner/flutter_window.h → golf_diary_app/windows/runner/win32_window.h
- `my_application_activate()` --calls--> `fl_register_plugins()`  [INFERRED]
  golf_diary_app/linux/my_application.cc → golf_diary_app/linux/flutter/generated_plugin_registrant.cc
- `main()` --calls--> `my_application_new()`  [INFERRED]
  golf_diary_app/linux/main.cc → golf_diary_app/linux/my_application.cc
- `wWinMain()` --calls--> `GetCommandLineArguments()`  [INFERRED]
  golf_diary_app/windows/runner/main.cpp → golf_diary_app/windows/runner/utils.cpp

## Import Cycles
- None detected.

## Communities (81 total, 39 thin omitted)

### Community 1 - "Community 1"
Cohesion: 0.04
Nodes (46): amber, AppColors, birdieGold, birdieGoldDark, buildGolfTheme, _buildTextTheme, cream, creamElevated (+38 more)

### Community 2 - "Community 2"
Cohesion: 0.04
Nodes (48): dependencies, cloud_firestore, cupertino_icons, firebase_core, flutter, geolocator, google_fonts, path (+40 more)

### Community 3 - "Community 3"
Cohesion: 0.05
Nodes (40): avgDistance, avgYards, category, clubId, computeFinalScore, conceded, copyWith, courseName (+32 more)

### Community 4 - "Community 4"
Cohesion: 0.05
Nodes (30): initDesktopDatabase, computeRoundTotals, concedeHole, _createDB, _database, ensureActiveRound, finishHole, getActiveRoundId (+22 more)

### Community 5 - "Community 5"
Cohesion: 0.06
Nodes (17): cloud_firestore, Cocoa, firebase_core, Flutter, FlutterMacOS, Foundation, geolocator_apple, AppDelegate (+9 more)

### Community 6 - "Community 6"
Cohesion: 0.06
Nodes (33): GolfDiaryApp, RoundScore, _ClubGlanceCard, _StatCol, _CounterRow, build, _courseName, createState (+25 more)

### Community 7 - "Community 7"
Cohesion: 0.06
Nodes (29): _bootstrap, _bootstrapFailed, build, _busy, _clubName, _clubs, _commitCourseName, _courseController (+21 more)

### Community 8 - "Community 8"
Cohesion: 0.07
Nodes (28): _adjustPenalties, _adjustStrokes, build, _conceded, courseName, createState, decKey, existing (+20 more)

### Community 9 - "Community 9"
Cohesion: 0.07
Nodes (27): Club, avg, _avgController, build, _clubs, createState, dispose, DrillYardageInput (+19 more)

### Community 10 - "Community 10"
Cohesion: 0.07
Nodes (15): CloudSyncService, _db, initializeFirebase, isAvailable, syncAll, _syncTable, _tables, userId (+7 more)

### Community 11 - "Community 11"
Cohesion: 0.09
Nodes (13): fl_register_plugins(), main(), my_application_activate(), my_application_class_init(), my_application_dispose(), my_application_init(), my_application_local_command_line(), my_application_new() (+5 more)

### Community 12 - "Community 12"
Cohesion: 0.07
Nodes (28): aE(), aS(), ax(), b(), bN(), bv(), c5(), cK() (+20 more)

### Community 13 - "Community 13"
Cohesion: 0.08
Nodes (27): A(), aA(), aC(), aG(), aV(), bj(), by(), bZ() (+19 more)

### Community 14 - "Community 14"
Cohesion: 0.10
Nodes (24): $0(), $1(), b4(), bk(), bs(), cR(), dL(), dU() (+16 more)

### Community 15 - "Community 15"
Cohesion: 0.12
Nodes (4): wWinMain(), CreateAndAttachConsole(), GetCommandLineArguments(), Utf8FromUtf16()

### Community 16 - "Community 16"
Cohesion: 0.09
Nodes (18): build, _categories, club, _clubs, _controller, createState, dispose, initState (+10 more)

### Community 17 - "Community 17"
Cohesion: 0.14
Nodes (21): a1(), aU(), c6(), cb(), cs(), dF(), eE(), ei() (+13 more)

### Community 18 - "Community 18"
Cohesion: 0.15
Nodes (8): EnableNonClientDpiScaling, Scale(), Win32Window::Win32Window(), WindowClassRegistrar, class_registered_, WindowClassRegistrar::GetWindowClass(), instance_, WindowClassRegistrar::UnregisterWindowClass()

### Community 19 - "Community 19"
Cohesion: 0.11
Nodes (10): _bagKey, build, createState, _index, initDesktopDatabase, initializeFirebase, main, _onTabSelected (+2 more)

### Community 20 - "Community 20"
Cohesion: 0.11
Nodes (17): backNinePar, backNineScore, backNineToPar, courseName, frontNinePar, frontNineScore, frontNineToPar, holesRecorded (+9 more)

### Community 21 - "Community 21"
Cohesion: 0.12
Nodes (4): FlutterWindow, flutter_controller_, FlutterWindow::FlutterWindow(), project_

### Community 22 - "Community 22"
Cohesion: 0.11
Nodes (18): a4(), aP(), b9(), bL(), cF(), cJ(), cM(), cU() (+10 more)

### Community 23 - "Community 23"
Cohesion: 0.17
Nodes (14): HomeShell, _HomeShellState, ClubsScreen, ClubsScreenState, _NotesSheet, _NotesSheetState, FairwayTrackerScreen, _FairwayTrackerScreenState (+6 more)

### Community 24 - "Community 24"
Cohesion: 0.13
Nodes (16): bt(), cD(), cG(), d(), de(), eB(), eC(), eP() (+8 more)

### Community 25 - "Community 25"
Cohesion: 0.18
Nodes (3): main, main, preloadDatabase

### Community 26 - "Community 26"
Cohesion: 0.18
Nodes (10): background_color, description, display, icons, name, orientation, prefer_related_applications, short_name (+2 more)

### Community 27 - "Community 27"
Cohesion: 0.24
Nodes (4): Win32Window, child_content_, quit_on_close_, window_handle_

### Community 29 - "Community 29"
Cohesion: 0.36
Nodes (10): aH(), e_(), ga9(), gcZ(), gG(), gk(), gP(), gu() (+2 more)

### Community 31 - "Community 31"
Cohesion: 0.33
Nodes (5): analyzer, exclude, include, linter, rules

### Community 32 - "Community 32"
Cohesion: 0.33
Nodes (6): a0(), aD(), aK(), ba(), cc(), U()

### Community 33 - "Community 33"
Cohesion: 0.33
Nodes (6): copyProperties(), inherit(), inheritMany(), setOrUpdateInterceptorsByTag(), setOrUpdateLeafTags(), updateHolder()

### Community 35 - "Community 35"
Cohesion: 0.40
Nodes (5): ai(), bO(), cO(), d7(), e3()

### Community 36 - "Community 36"
Cohesion: 0.40
Nodes (5): c2(), cL(), ef(), eg(), r_()

### Community 37 - "Community 37"
Cohesion: 0.40
Nodes (5): installInstanceTearOff(), installStaticTearOff(), instanceTearOffGetter(), staticTearOffGetter(), tearOffParameters()

### Community 38 - "Community 38"
Cohesion: 0.50
Nodes (4): getTag(), getTagFirefox(), getTagFixed(), getTagIE()

### Community 39 - "Community 39"
Cohesion: 0.50
Nodes (3): Point, x, y

### Community 40 - "Community 40"
Cohesion: 0.50
Nodes (3): Size, height, width

### Community 43 - "Community 43"
Cohesion: 0.67
Nodes (3): a3(), a5(), nB()

### Community 44 - "Community 44"
Cohesion: 0.67
Nodes (3): aq(), aZ(), dg()

### Community 45 - "Community 45"
Cohesion: 0.67
Nodes (3): bx(), c8(), c9()

### Community 46 - "Community 46"
Cohesion: 0.67
Nodes (3): c1(), cE(), f0()

### Community 48 - "Community 48"
Cohesion: 0.67
Nodes (3): gcn(), X(), z()

## Knowledge Gaps
- **305 isolated node(s):** `amber`, `AppColors`, `birdieGold`, `birdieGoldDark`, `buildGolfTheme` (+300 more)
  These have ≤1 connection - possible missing edges. (Counts symbols only; 872 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **39 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `RoundScore` connect `Community 6` to `Community 8`, `Community 3`, `Community 7`?**
  _High betweenness centrality (0.008) - this node is a cross-community bridge._
- **Are the 60 inferred relationships involving `b()` (e.g. with `a0()` and `aA()`) actually correct?**
  _`b()` has 60 INFERRED edges - model-reasoned connections that need verification._
- **What connects `amber`, `AppColors`, `birdieGold` to the rest of the system?**
  _305 weakly-connected nodes found - possible missing edges._
- **Should `Community 0` be split into smaller, more focused modules?**
  _Cohesion score 0.0048543689320388345 - nodes in this community are weakly interconnected._
- **Why does `Club` connect `Community 9` to `Community 16`, `Community 3`, `Community 7`?**
  _High betweenness centrality (0.006) - this node is a cross-community bridge._
- **Are the 44 inferred relationships involving `c()` (e.g. with `aA()` and `aC()`) actually correct?**
  _`c()` has 44 INFERRED edges - model-reasoned connections that need verification._
- **Should `Community 1` be split into smaller, more focused modules?**
  _Cohesion score 0.0392156862745098 - nodes in this community are weakly interconnected._