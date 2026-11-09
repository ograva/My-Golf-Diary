# Graph Report - My-Golf-Diary  (2026-11-09)

## Corpus Check
- 88 files · ~100,853 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 57 file(s) not represented in the graph (top: .xml 9, (none) 8, .xcconfig 8)
- WARNING: 57 of 248 files seen (23%) have no supported extractor and are missing from this graph entirely. It may look complete while representing only part of the codebase.

## Summary
- 1657 nodes · 2182 edges · 119 communities (67 shown, 52 thin omitted)
- Extraction: 90% EXTRACTED · 10% INFERRED · 0% AMBIGUOUS · INFERRED: 228 edges (avg confidence: 0.85)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `0c151da5`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- app_theme.dart
- dependencies
- golf_models.dart
- local_database_service.dart
- GeneratedPluginRegistrant.swift
- scorecard_screen.dart
- fairway_tracker_screen.dart
- scorecard_hole_editor.dart
- range_drill_screen.dart
- flutter_test_config.dart
- my_application.cc
- b
- c
- p
- utils.cpp
- clubs_screen.dart
- j
- win32_window.cpp
- main.dart
- round_summary.dart
- FlutterWindow
- cJ
- State
- d
- range_session_log_test.dart
- manifest.json
- Win32Window
- .MessageHandler
- gk
- windows/flutter/generated_plugin_registrant.cc
- analysis_options.yaml
- aK
- copyProperties
- desktop_database.dart
- ai
- eg
- installInstanceTearOff
- getTag
- Point
- Size
- FlutterActivity
- a3
- aZ
- bx
- pwa_update_host.dart
- convertToFastObject
- X
- desktop_database_stub.dart
- an
- aR
- bF
- bP
- d6
- es
- getUnknownTag
- mixinEasy
- mixinHard
- prototypeForTag
- venue_name_field.dart
- cloud_sync_service.dart
- pwa_update_client.dart
- ph_golf_catalog.dart
- diary_remote.dart
- cloud_sync_service_test.dart
- pwa_update_test.dart
- List
- range_session_log.dart
- StatelessWidget
- sync_merge.dart
- flutter_launcher_icons
- sync_cloud_button.dart
- pubspec.yaml
- @visibleForTesting
- ph_golf_hole_coords.dart
- on_course_hole_test.dart
- sync_identity.dart
- package:flutter/material.dart
- clubs_screen_test.dart
- package:flutter_test/flutter_test.dart
- firebase_options.dart
- dev_dependencies
- web
- pwa_service_worker.js
- cloud-agent-install.sh
- pwa_published_build.dart
- windows
- bool get
- _ClubSortKey
- app_build_id.dart
- build_web.sh
- aV
- cX
- fY

## God Nodes (most connected - your core abstractions)
1. `b()` - 70 edges
2. `c()` - 45 edges
3. `p()` - 28 edges
4. `d()` - 23 edges
5. `o()` - 22 edges
6. `Win32Window` - 21 edges
7. `j()` - 20 edges
8. `i()` - 14 edges
9. `dependencies` - 13 edges
10. `gk()` - 12 edges

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

## Communities (119 total, 52 thin omitted)

### Community 1 - "app_theme.dart"
Cohesion: 0.04
Nodes (46): amber, AppColors, birdieGold, birdieGoldDark, buildGolfTheme, _buildTextTheme, cream, creamElevated (+38 more)

### Community 2 - "dependencies"
Cohesion: 0.14
Nodes (14): dependencies, cloud_firestore, cupertino_icons, firebase_auth, firebase_core, flutter, geolocator, google_fonts (+6 more)

### Community 3 - "golf_models.dart"
Cohesion: 0.03
Nodes (64): avgDistance, avgYards, brand, category, clubId, clubName, compareClubs, compareTo (+56 more)

### Community 4 - "local_database_service.dart"
Cohesion: 0.03
Nodes (69): applyCoursePar, applyRemoteRow, _backfillGolfRounds, _columns, completeRound, computeRoundTotals, concedeHole, _createDB (+61 more)

### Community 5 - "GeneratedPluginRegistrant.swift"
Cohesion: 0.06
Nodes (18): cloud_firestore, Cocoa, firebase_auth, firebase_core, Flutter, FlutterMacOS, Foundation, geolocator_apple (+10 more)

### Community 6 - "scorecard_screen.dart"
Cohesion: 0.06
Nodes (30): build, _controller, _courseName, createState, _deltaStyle, dispose, _editHole, hole (+22 more)

### Community 7 - "fairway_tracker_screen.dart"
Cohesion: 0.04
Nodes (45): ShotRecord, _appliedCourseName, _bootstrap, build, _busy, _clubId, _clubName, _clubs (+37 more)

### Community 8 - "scorecard_hole_editor.dart"
Cohesion: 0.06
Nodes (31): RoundScore, _adjustPenalties, _adjustStrokes, build, _conceded, courseName, createState, decKey (+23 more)

### Community 9 - "range_drill_screen.dart"
Cohesion: 0.08
Nodes (18): Club, _avgController, build, _clubs, createState, dispose, initState, _log (+10 more)

### Community 10 - "flutter_test_config.dart"
Cohesion: 0.20
Nodes (5): initDesktopDatabase, useGoogleFonts, setDatabasesPath, testExecutable, testMain

### Community 11 - "my_application.cc"
Cohesion: 0.09
Nodes (13): fl_register_plugins(), main(), my_application_activate(), my_application_class_init(), my_application_dispose(), my_application_init(), my_application_local_command_line(), my_application_new() (+5 more)

### Community 12 - "b"
Cohesion: 0.07
Nodes (28): aE(), aS(), ax(), b(), bN(), bv(), c5(), cK() (+20 more)

### Community 13 - "c"
Cohesion: 0.09
Nodes (26): A(), aA(), aC(), aG(), bj(), by(), bZ(), c() (+18 more)

### Community 14 - "p"
Cohesion: 0.10
Nodes (24): $0(), $1(), b4(), bk(), bs(), cR(), dL(), dU() (+16 more)

### Community 15 - "utils.cpp"
Cohesion: 0.19
Nodes (4): wWinMain(), CreateAndAttachConsole(), GetCommandLineArguments(), Utf8FromUtf16()

### Community 16 - "clubs_screen.dart"
Cohesion: 0.05
Nodes (35): _addClub, _brand, build, categories, _category, _categoryLabel, club, _clubs (+27 more)

### Community 17 - "j"
Cohesion: 0.14
Nodes (21): a1(), aU(), c6(), cb(), cs(), dF(), eE(), ei() (+13 more)

### Community 18 - "win32_window.cpp"
Cohesion: 0.16
Nodes (8): EnableNonClientDpiScaling, Scale(), Win32Window::Win32Window(), WindowClassRegistrar, class_registered_, WindowClassRegistrar::GetWindowClass(), instance_, WindowClassRegistrar::UnregisterWindowClass()

### Community 19 - "main.dart"
Cohesion: 0.09
Nodes (15): _bagKey, build, _courseKey, createState, HomeShell, _HomeShellState, _index, initDesktopDatabase (+7 more)

### Community 20 - "round_summary.dart"
Cohesion: 0.09
Nodes (19): backNinePar, backNineScore, backNineToPar, completedAtMs, courseName, frontNinePar, frontNineScore, frontNineToPar (+11 more)

### Community 21 - "FlutterWindow"
Cohesion: 0.11
Nodes (4): FlutterWindow, flutter_controller_, FlutterWindow::FlutterWindow(), project_

### Community 22 - "cJ"
Cohesion: 0.12
Nodes (16): a4(), aP(), b9(), bL(), cF(), cJ(), cM(), cU() (+8 more)

### Community 23 - "State"
Cohesion: 0.15
Nodes (16): PwaUpdateHost, _PwaUpdateHostState, _AddClubDialog, _AddClubDialogState, ClubsScreen, ClubsScreenState, FairwayTrackerScreen, FairwayTrackerScreenState (+8 more)

### Community 24 - "d"
Cohesion: 0.13
Nodes (16): bt(), cD(), cG(), d(), de(), eB(), eC(), eP() (+8 more)

### Community 25 - "range_session_log_test.dart"
Cohesion: 0.22
Nodes (5): main, db, main, restoreDatabase, useFreshDatabase

### Community 26 - "manifest.json"
Cohesion: 0.18
Nodes (10): background_color, description, display, icons, name, orientation, prefer_related_applications, short_name (+2 more)

### Community 27 - "Win32Window"
Cohesion: 0.19
Nodes (4): Win32Window, child_content_, quit_on_close_, window_handle_

### Community 29 - "gk"
Cohesion: 0.36
Nodes (10): aH(), e_(), ga9(), gcZ(), gG(), gk(), gP(), gu() (+2 more)

### Community 31 - "analysis_options.yaml"
Cohesion: 0.33
Nodes (5): analyzer, exclude, include, linter, rules

### Community 32 - "aK"
Cohesion: 0.33
Nodes (6): a0(), aD(), aK(), ba(), cc(), U()

### Community 33 - "copyProperties"
Cohesion: 0.33
Nodes (6): copyProperties(), inherit(), inheritMany(), setOrUpdateInterceptorsByTag(), setOrUpdateLeafTags(), updateHolder()

### Community 35 - "ai"
Cohesion: 0.40
Nodes (5): ai(), bO(), cO(), d7(), e3()

### Community 36 - "eg"
Cohesion: 0.40
Nodes (5): c2(), cL(), ef(), eg(), r_()

### Community 37 - "installInstanceTearOff"
Cohesion: 0.40
Nodes (5): installInstanceTearOff(), installStaticTearOff(), instanceTearOffGetter(), staticTearOffGetter(), tearOffParameters()

### Community 38 - "getTag"
Cohesion: 0.50
Nodes (4): getTag(), getTagFirefox(), getTagFixed(), getTagIE()

### Community 39 - "Point"
Cohesion: 0.50
Nodes (3): Point, x, y

### Community 40 - "Size"
Cohesion: 0.50
Nodes (3): Size, height, width

### Community 43 - "a3"
Cohesion: 0.67
Nodes (3): a3(), a5(), nB()

### Community 44 - "aZ"
Cohesion: 0.67
Nodes (3): aq(), aZ(), dg()

### Community 45 - "bx"
Cohesion: 0.67
Nodes (3): bx(), c8(), c9()

### Community 46 - "pwa_update_host.dart"
Cohesion: 0.07
Nodes (19): _applying, build, _check, _checking, child, client, createState, dialogKey (+11 more)

### Community 48 - "X"
Cohesion: 0.67
Nodes (3): gcn(), X(), z()

### Community 81 - "venue_name_field.dart"
Cohesion: 0.09
Nodes (19): autofocus, build, catalogNames, controller, createState, didUpdateWidget, dispose, focusNode (+11 more)

### Community 82 - "cloud_sync_service.dart"
Cohesion: 0.09
Nodes (16): CloudSyncService, _db, failed, initializeFirebase, isAvailable, pullAll, pulled, pushed (+8 more)

### Community 83 - "pwa_update_client.dart"
Cohesion: 0.10
Nodes (13): applyUpdate, fetchPublishedBuild, PlatformPwaUpdateClient, preparePwaSession, PwaUpdateClient, applyPwaUpdate, fetchPublishedBuild, preparePwaSession (+5 more)

### Community 84 - "ph_golf_catalog.dart"
Cohesion: 0.11
Nodes (17): courseCaption, courseNames, courses, hasCard, holeCount, holePars, holes, matchCourse (+9 more)

### Community 85 - "diary_remote.dart"
Cohesion: 0.14
Nodes (10): _collection, DiaryRemote, docs, failOnSet, _firestore, FirestoreDiaryRemote, _key, listDocuments (+2 more)

### Community 86 - "cloud_sync_service_test.dart"
Cohesion: 0.14
Nodes (5): initDesktopDatabase, db, main, db, main

### Community 87 - "pwa_update_test.dart"
Cohesion: 0.14
Nodes (9): applyCount, applyUpdate, fetchPublishedBuild, main, published, pump, pumpAndSettle, _pumpHost (+1 more)

### Community 88 - "List"
Cohesion: 0.15
Nodes (10): category, id, PracticeDrillSeed, practiceDrillSeeds, recommendedClubs, shortDescription, steps, title (+2 more)

### Community 89 - "range_session_log.dart"
Cohesion: 0.15
Nodes (11): RangeDrillSummary, build, date, emptyMessage, entry, formatRangeSessionWhen, hour, minute (+3 more)

### Community 90 - "StatelessWidget"
Cohesion: 0.17
Nodes (11): GolfDiaryApp, PwaUpdateDialog, _StatChip, _YardageTrend, _CounterRow, _HoleTile, _NineGrid, _SummaryBanner (+3 more)

### Community 91 - "sync_merge.dart"
Cohesion: 0.17
Nodes (9): published, shouldOfferPwaUpdate, true, decideMerge, MergeAction, readDeleted, readUpdatedAtMs, tryParse (+1 more)

### Community 93 - "flutter_launcher_icons"
Cohesion: 0.18
Nodes (11): flutter_launcher_icons, adaptive_icon_background, adaptive_icon_foreground, android, image_path, ios, macos, min_sdk_android (+3 more)

### Community 94 - "sync_cloud_button.dart"
Cohesion: 0.20
Nodes (7): build, failure, messenger, result, runDiarySync, SyncCloudButton, userId

### Community 95 - "pubspec.yaml"
Cohesion: 0.20
Nodes (9): description, environment, sdk, flutter, assets, uses-material-design, name, publish_to (+1 more)

### Community 96 - "@visibleForTesting"
Cohesion: 0.22
Nodes (8): ClubEditResult, ClubRangeLogSheet, EditClubDialog, _EditClubDialogState, SwingNotesDialog, _SwingNotesDialogState, debugClose, debugSetFileName

### Community 97 - "ph_golf_hole_coords.dart"
Cohesion: 0.22
Nodes (7): _courses, greenLat, greenLon, HoleCoordinates, PhGolfHoleCoords, teeLat, teeLon

### Community 98 - "on_course_hole_test.dart"
Cohesion: 0.25
Nodes (4): main, finishAction, main, pumpCourse

### Community 99 - "sync_identity.dart"
Cohesion: 0.25
Nodes (4): canSync, currentUserId, ensureSignedIn, SyncIdentity

### Community 100 - "package:flutter/material.dart"
Cohesion: 0.25
Nodes (3): SaveRoundBeforeNewChoice, showSaveRoundBeforeNewDialog, main

### Community 101 - "clubs_screen_test.dart"
Cohesion: 0.29
Nodes (3): club, main, openDialog

### Community 104 - "dev_dependencies"
Cohesion: 0.33
Nodes (6): dev_dependencies, flutter_launcher_icons, flutter_lints, flutter_test, sqlite3, sdk

### Community 105 - "web"
Cohesion: 0.40
Nodes (5): web, background_color, generate, image_path, theme_color

### Community 107 - "cloud-agent-install.sh"
Cohesion: 0.67
Nodes (3): DEBIAN_FRONTEND, flutter_meets_version(), cloud-agent-install.sh script

### Community 108 - "pwa_published_build.dart"
Cohesion: 0.50
Nodes (3): buildId, PwaPublishedBuild, version

### Community 109 - "windows"
Cohesion: 0.50
Nodes (4): windows, generate, icon_size, image_path

## Knowledge Gaps
- **556 isolated node(s):** `DEBIAN_FRONTEND`, `PhGolfCourse`, `PhGolfCatalog`, `name`, `region` (+551 more)
  These have ≤1 connection - possible missing edges. (Counts symbols only; 1172 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **52 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Win32Window` connect `Win32Window` to `Point`, `Size`, `.MessageHandler`, `win32_window.cpp`, `FlutterWindow`, `String?`?**
  _High betweenness centrality (0.018) - this node is a cross-community bridge._
- **Are the 60 inferred relationships involving `b()` (e.g. with `a0()` and `aA()`) actually correct?**
  _`b()` has 60 INFERRED edges - model-reasoned connections that need verification._
- **What connects `DEBIAN_FRONTEND`, `PhGolfCourse`, `PhGolfCatalog` to the rest of the system?**
  _556 weakly-connected nodes found - possible missing edges._
- **Should `sqflite_sw.js` be split into smaller, more focused modules?**
  _Cohesion score 0.0048543689320388345 - nodes in this community are weakly interconnected._
- **Why does `PwaUpdateClient` connect `pwa_update_client.dart` to `pwa_update_host.dart`?**
  _High betweenness centrality (0.009) - this node is a cross-community bridge._
- **Are the 44 inferred relationships involving `c()` (e.g. with `aA()` and `aC()`) actually correct?**
  _`c()` has 44 INFERRED edges - model-reasoned connections that need verification._
- **Should `app_theme.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.0392156862745098 - nodes in this community are weakly interconnected._