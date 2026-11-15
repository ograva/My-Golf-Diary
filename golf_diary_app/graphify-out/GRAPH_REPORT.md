# Graph Report - golf_diary_app  (2026-11-15)

## Corpus Check
- 111 files · ~68,853 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 54 file(s) not represented in the graph (top: .xml 9, .xcconfig 8, (none) 7)
- WARNING: 54 of 218 files seen (25%) have no supported extractor and are missing from this graph entirely. It may look complete while representing only part of the codebase.

## Summary
- 2235 nodes · 2929 edges · 137 communities (86 shown, 51 thin omitted)
- Extraction: 92% EXTRACTED · 8% INFERRED · 0% AMBIGUOUS · INFERRED: 228 edges (avg confidence: 0.85)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `2853d956`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- local_database_service.dart
- swing_diary_prompt.dart
- p
- golf_models.dart
- fairway_tracker_screen.dart
- golfer_profile.dart
- app_theme.dart
- swing_diary_sheet.dart
- GeneratedPluginRegistrant.swift
- clubs_screen.dart
- pwa_update_host.dart
- range_drill_screen.dart
- scorecard_screen.dart
- scorecard_hole_editor.dart
- swing_diary_service.dart
- pwa_update_test.dart
- onboarding_starter_wizard.dart
- my_application.cc
- ph_golf_hole_coords.dart
- b
- practice_drill_sheet.dart
- State
- c
- cloud_sync_service.dart
- swing_diary_test.dart
- golfer_profile_service.dart
- venue_name_field.dart
- round_summary.dart
- win32_window.cpp
- range_session.dart
- diary_markdown_body.dart
- Win32Window
- golfer_baseline_sheet.dart
- ph_golf_catalog.dart
- FlutterWindow
- range_session_log.dart
- package:flutter_test/flutter_test.dart
- package:flutter/material.dart
- home_shell.dart
- dependencies
- pin_distance.dart
- diary_remote.dart
- d
- StatelessWidget
- diary_model.dart
- onboarding_gate.dart
- utils.cpp
- List
- fairway_tracker_screen_test.dart
- vertex_diary_model.dart
- app_check_config.dart
- main.dart
- practice_drill.dart
- package:sqflite/sqflite.dart
- package:golf_diary_app/services/local_database_service.dart
- flutter_launcher_icons
- manifest.json
- windows/flutter/generated_plugin_registrant.cc
- sync_cloud_button.dart
- golfer_profile_test.dart
- pubspec.yaml
- @visibleForTesting
- b9
- pwa_update_client_web.dart
- sync_identity.dart
- My Golf Diary
- range_session_wrapup_test.dart
- practice_drill_sheet_test.dart
- analysis_options.yaml
- on_course_hole_test.dart
- dev_dependencies
- aK
- copyProperties
- desktop_database.dart
- web
- pwa_service_worker.js
- ai
- eg
- installInstanceTearOff
- DiaryModel
- windows
- getTag
- Point
- Size
- MainActivity.kt
- bool get
- LocalDatabaseService
- aZ
- bx
- cE
- convertToFastObject
- X
- _ClubSortKey
- LaunchImage.imageset/README.md
- app_build_id.dart
- ShotEditDialog
- desktop_database_stub.dart
- build_web.sh
- recaptcha_assessment.sh
- an
- aR
- bF
- bP
- by
- cD
- d6
- es
- getUnknownTag
- mixinEasy
- mixinHard
- prototypeForTag

## God Nodes (most connected - your core abstractions)
1. `b()` - 70 edges
2. `c()` - 45 edges
3. `p()` - 28 edges
4. `d()` - 23 edges
5. `o()` - 22 edges
6. `Win32Window` - 21 edges
7. `j()` - 20 edges
8. `dependencies` - 16 edges
9. `i()` - 14 edges
10. `gk()` - 12 edges

## Surprising Connections (you probably didn't know these)
- `wWinMain()` --calls--> `CreateAndAttachConsole()`  [INFERRED]
  golf_diary_app/windows/runner/main.cpp → golf_diary_app/windows/runner/utils.cpp
- `VertexDiaryModel` --implements--> `DiaryModel`  [EXTRACTED]
  golf_diary_app/lib/services/vertex_diary_model.dart → golf_diary_app/lib/services/diary_model.dart
- `_SilentModel` --implements--> `DiaryModel`  [EXTRACTED]
  golf_diary_app/test/golfer_profile_test.dart → golf_diary_app/lib/services/diary_model.dart
- `FakeDiaryModel` --implements--> `DiaryModel`  [EXTRACTED]
  golf_diary_app/test/swing_diary_test.dart → golf_diary_app/lib/services/diary_model.dart
- `my_application_activate()` --calls--> `fl_register_plugins()`  [INFERRED]
  golf_diary_app/linux/my_application.cc → golf_diary_app/linux/flutter/generated_plugin_registrant.cc

## Import Cycles
- None detected.

## Communities (137 total, 51 thin omitted)

### Community 1 - "local_database_service.dart"
Cohesion: 0.02
Nodes (82): applyCoursePar, applyRemoteRow, _backfillGolfRounds, _columns, compileRangeSession, completeRound, computeRoundTotals, concedeHole (+74 more)

### Community 2 - "swing_diary_prompt.dart"
Cohesion: 0.03
Nodes (73): brief, buffer, buildDiarySystemInstruction, clubName, clubs, ClubTally, compiledIds, _compose (+65 more)

### Community 3 - "p"
Cohesion: 0.05
Nodes (65): $0(), $1(), a1(), a3(), a4(), a5(), aH(), aU() (+57 more)

### Community 4 - "golf_models.dart"
Cohesion: 0.03
Nodes (59): avgDistance, avgYards, brand, category, clubId, clubName, compareClubs, compareTo (+51 more)

### Community 5 - "fairway_tracker_screen.dart"
Cohesion: 0.03
Nodes (56): _appliedCourseName, _beginPinWatch, _bootstrap, build, _busy, _clubId, _clubName, _clubs (+48 more)

### Community 6 - "golfer_profile.dart"
Cohesion: 0.04
Nodes (52): age, amateur, any, bagNickname, baselineLabel, beginner, blurb, clubsMissingEquipmentSpecs (+44 more)

### Community 7 - "app_theme.dart"
Cohesion: 0.04
Nodes (46): amber, AppColors, birdieGold, birdieGoldDark, buildGolfTheme, _buildTextTheme, cream, creamElevated (+38 more)

### Community 8 - "swing_diary_sheet.dart"
Cohesion: 0.04
Nodes (42): _appCheck, _applyLeadIn, _baselineSummary, _baselineUpdated, build, _busy, _cancel, _chunks (+34 more)

### Community 9 - "GeneratedPluginRegistrant.swift"
Cohesion: 0.06
Nodes (20): cloud_firestore, Cocoa, firebase_ai, firebase_app_check, firebase_auth, firebase_core, Flutter, FlutterMacOS (+12 more)

### Community 10 - "clubs_screen.dart"
Cohesion: 0.05
Nodes (36): Club, _addClub, _brand, build, categories, _category, _categoryLabel, club (+28 more)

### Community 11 - "pwa_update_host.dart"
Cohesion: 0.06
Nodes (24): _applying, build, _check, _checking, child, client, createState, dialogKey (+16 more)

### Community 12 - "range_drill_screen.dart"
Cohesion: 0.05
Nodes (31): _applyLeadIn, _avgController, build, _clubs, _clubsMissingSpecs, _compiled, createState, diary (+23 more)

### Community 13 - "scorecard_screen.dart"
Cohesion: 0.06
Nodes (30): build, _controller, _courseName, createState, _deltaStyle, dispose, _editHole, hole (+22 more)

### Community 14 - "scorecard_hole_editor.dart"
Cohesion: 0.06
Nodes (31): RoundScore, _adjustPenalties, _adjustStrokes, build, _conceded, courseName, createState, decKey (+23 more)

### Community 15 - "swing_diary_service.dart"
Cohesion: 0.06
Nodes (29): ask, content, _database, day, _db, DiaryExchange, DiaryMessage, evaluationId (+21 more)

### Community 16 - "pwa_update_test.dart"
Cohesion: 0.06
Nodes (21): buildId, PwaPublishedBuild, version, applyUpdate, fetchPublishedBuild, PlatformPwaUpdateClient, preparePwaSession, PwaUpdateClient (+13 more)

### Community 17 - "onboarding_starter_wizard.dart"
Cohesion: 0.06
Nodes (28): _ageController, _ageError, build, controller, createState, dispose, _draftProfile, errorText (+20 more)

### Community 18 - "my_application.cc"
Cohesion: 0.09
Nodes (13): fl_register_plugins(), main(), my_application_activate(), my_application_class_init(), my_application_dispose(), my_application_init(), my_application_local_command_line(), my_application_new() (+5 more)

### Community 19 - "ph_golf_hole_coords.dart"
Cohesion: 0.07
Nodes (23): _byCourse, canonicalCourseName, direct, greenLat, greenLon, hallow, hasHoleCoordinates, HoleCoordinates (+15 more)

### Community 20 - "b"
Cohesion: 0.07
Nodes (28): aE(), aS(), ax(), b(), bN(), bv(), c5(), cK() (+20 more)

### Community 21 - "practice_drill_sheet.dart"
Cohesion: 0.08
Nodes (25): _add, build, _category, copyTitleToNote, createState, _delete, _description, dispose (+17 more)

### Community 22 - "State"
Cohesion: 0.12
Nodes (22): PwaUpdateHost, _PwaUpdateHostState, _AddClubDialog, _AddClubDialogState, ClubsScreen, ClubsScreenState, FairwayTrackerScreen, FairwayTrackerScreenState (+14 more)

### Community 23 - "c"
Cohesion: 0.09
Nodes (25): A(), aA(), aC(), aG(), aV(), bj(), bZ(), c() (+17 more)

### Community 24 - "cloud_sync_service.dart"
Cohesion: 0.08
Nodes (16): alreadyRunning, CloudSyncService, _db, failed, initializeFirebase, isAvailable, pullAll, pulled (+8 more)

### Community 25 - "swing_diary_test.dart"
Cohesion: 0.08
Nodes (19): available, calls, db, error, generate, generateJson, hold, jsonReply (+11 more)

### Community 26 - "golfer_profile_service.dart"
Cohesion: 0.08
Nodes (22): changed, collectUndistilledNotes, _database, decoded, distillIfNeeded, DistillResult, GolferProfileService, isEmpty (+14 more)

### Community 27 - "venue_name_field.dart"
Cohesion: 0.09
Nodes (19): autofocus, build, catalogNames, controller, createState, didUpdateWidget, dispose, focusNode (+11 more)

### Community 28 - "round_summary.dart"
Cohesion: 0.09
Nodes (19): backNinePar, backNineScore, backNineToPar, completedAtMs, courseName, frontNinePar, frontNineScore, frontNineToPar (+11 more)

### Community 29 - "win32_window.cpp"
Cohesion: 0.14
Nodes (8): EnableNonClientDpiScaling, Scale(), Win32Window::Win32Window(), WindowClassRegistrar, class_registered_, WindowClassRegistrar::GetWindowClass(), instance_, WindowClassRegistrar::UnregisterWindowClass()

### Community 30 - "range_session.dart"
Cohesion: 0.10
Nodes (20): avgYards, blocks, clubId, clubName, drillId, drillSteps, drillTitle, fromJson (+12 more)

### Community 31 - "diary_markdown_body.dart"
Cohesion: 0.10
Nodes (17): baseStyle, build, _CodeDiagramBox, data, DiaryMarkdownBody, header, _InlineMarkdownText, _isDiagramLine (+9 more)

### Community 32 - "Win32Window"
Cohesion: 0.18
Nodes (5): EnableFullDpiSupportIfAvailable(), Win32Window, child_content_, quit_on_close_, window_handle_

### Community 33 - "golfer_baseline_sheet.dart"
Cohesion: 0.10
Nodes (16): build, _busy, createState, diary, dispose, _distill, _edited, _equipment (+8 more)

### Community 34 - "ph_golf_catalog.dart"
Cohesion: 0.11
Nodes (17): courseCaption, courseNames, courses, hasCard, holeCount, holePars, holes, matchCourse (+9 more)

### Community 35 - "FlutterWindow"
Cohesion: 0.12
Nodes (4): FlutterWindow, flutter_controller_, FlutterWindow::FlutterWindow(), project_

### Community 36 - "range_session_log.dart"
Cohesion: 0.11
Nodes (15): RangeDrillSummary, build, compiled, date, emptyMessage, entry, formatRangeSessionWhen, hour (+7 more)

### Community 37 - "package:flutter_test/flutter_test.dart"
Cohesion: 0.12
Nodes (6): db, main, main, main, drill, main

### Community 38 - "package:flutter/material.dart"
Cohesion: 0.13
Nodes (9): SaveRoundBeforeNewChoice, showSaveRoundBeforeNewDialog, club, main, openDialog, db, main, restoreDatabase (+1 more)

### Community 39 - "home_shell.dart"
Cohesion: 0.12
Nodes (11): _bagKey, build, _courseKey, createState, HomeShell, _HomeShellState, _index, _onTabSelected (+3 more)

### Community 40 - "dependencies"
Cohesion: 0.12
Nodes (17): dependencies, cloud_firestore, cupertino_icons, firebase_ai, firebase_app_check, firebase_auth, firebase_core, flutter (+9 more)

### Community 41 - "pin_distance.dart"
Cohesion: 0.13
Nodes (13): current, fromLat, fromLon, GeolocatorPinDistanceClient, latitude, locationSettings, longitude, meters (+5 more)

### Community 42 - "diary_remote.dart"
Cohesion: 0.14
Nodes (10): _collection, DiaryRemote, docs, failOnSet, _firestore, FirestoreDiaryRemote, _key, listDocuments (+2 more)

### Community 43 - "d"
Cohesion: 0.13
Nodes (16): bt(), cb(), cG(), d(), eB(), eC(), eP(), fA() (+8 more)

### Community 44 - "StatelessWidget"
Cohesion: 0.13
Nodes (14): PwaUpdateDialog, _StatChip, _YardageTrend, _AgeStep, _GenderStep, _SkillTierStep, _YearsStep, _CounterRow (+6 more)

### Community 45 - "diary_model.dart"
Cohesion: 0.14
Nodes (12): available, bindAbort, cancel, _cancelled, DiaryCancel, DiaryCancelled, generate, generateJson (+4 more)

### Community 46 - "onboarding_gate.dart"
Cohesion: 0.14
Nodes (9): GolferProfile, build, createState, _enterShell, initState, _loading, _profile, _refresh (+1 more)

### Community 47 - "utils.cpp"
Cohesion: 0.19
Nodes (4): wWinMain(), CreateAndAttachConsole(), GetCommandLineArguments(), Utf8FromUtf16()

### Community 48 - "List"
Cohesion: 0.15
Nodes (10): category, id, kPracticeDrillSeed, PracticeDrillSeed, recommendedClubs, shortDescription, steps, title (+2 more)

### Community 49 - "fairway_tracker_screen_test.dart"
Cohesion: 0.17
Nodes (8): PinFix, current, fix, live, main, waitForBag, watch, main

### Community 50 - "vertex_diary_model.dart"
Cohesion: 0.17
Nodes (7): available, defaultLocation, generate, generateJson, location, modelId, modelName

### Community 51 - "app_check_config.dart"
Cohesion: 0.18
Nodes (6): activateWebAppCheck, appCheckDebugState, kRecaptchaSiteKey, shouldActivateAppCheck, DefaultFirebaseOptions, web

### Community 53 - "main.dart"
Cohesion: 0.18
Nodes (6): build, GolfDiaryApp, initDesktopDatabase, initializeFirebase, main, preparePwaSession

### Community 54 - "practice_drill.dart"
Cohesion: 0.18
Nodes (10): category, fromMap, id, isCustom, PracticeDrill, recommendedClubs, shortDescription, steps (+2 more)

### Community 55 - "package:sqflite/sqflite.dart"
Cohesion: 0.18
Nodes (4): initDesktopDatabase, db, main, saveBlock

### Community 56 - "package:golf_diary_app/services/local_database_service.dart"
Cohesion: 0.20
Nodes (3): main, waitForGate, main

### Community 57 - "flutter_launcher_icons"
Cohesion: 0.18
Nodes (11): flutter_launcher_icons, adaptive_icon_background, adaptive_icon_foreground, android, image_path, ios, macos, min_sdk_android (+3 more)

### Community 58 - "manifest.json"
Cohesion: 0.18
Nodes (10): background_color, description, display, icons, name, orientation, prefer_related_applications, short_name (+2 more)

### Community 60 - "sync_cloud_button.dart"
Cohesion: 0.20
Nodes (7): build, failure, messenger, result, runDiarySync, SyncCloudButton, userId

### Community 61 - "golfer_profile_test.dart"
Cohesion: 0.20
Nodes (6): available, generate, generateJson, location, main, modelName

### Community 62 - "pubspec.yaml"
Cohesion: 0.20
Nodes (9): description, environment, sdk, flutter, assets, uses-material-design, name, publish_to (+1 more)

### Community 63 - "@visibleForTesting"
Cohesion: 0.22
Nodes (8): ClubEditResult, ClubRangeLogSheet, EditClubDialog, _EditClubDialogState, SwingNotesDialog, _SwingNotesDialogState, debugClose, debugSetFileName

### Community 64 - "b9"
Cohesion: 0.22
Nodes (9): aP(), b9(), bL(), cF(), cV(), cX(), dh(), gbZ() (+1 more)

### Community 65 - "pwa_update_client_web.dart"
Cohesion: 0.32
Nodes (4): _applyPwaUpdate, _disableServiceWorker, _fetchPublishedBuild, preparePwaSession

### Community 66 - "sync_identity.dart"
Cohesion: 0.25
Nodes (4): canSync, currentUserId, ensureSignedIn, SyncIdentity

### Community 67 - "My Golf Diary"
Cohesion: 0.25
Nodes (7): Browser / PWA storage, My Bag, My Golf Diary, On Course, Range, Run it, Scorecard

### Community 68 - "range_session_wrapup_test.dart"
Cohesion: 0.25
Nodes (5): clearSnackBars, labeled, main, restoreDatabase, useFreshDatabase

### Community 69 - "practice_drill_sheet_test.dart"
Cohesion: 0.29
Nodes (4): db, main, restoreDatabase, useFreshDatabase

### Community 70 - "analysis_options.yaml"
Cohesion: 0.33
Nodes (5): analyzer, exclude, include, linter, rules

### Community 71 - "on_course_hole_test.dart"
Cohesion: 0.33
Nodes (3): finishAction, main, pumpCourse

### Community 72 - "dev_dependencies"
Cohesion: 0.33
Nodes (6): dev_dependencies, flutter_launcher_icons, flutter_lints, flutter_test, sqlite3, sdk

### Community 73 - "aK"
Cohesion: 0.33
Nodes (6): a0(), aD(), aK(), ba(), cc(), U()

### Community 74 - "copyProperties"
Cohesion: 0.33
Nodes (6): copyProperties(), inherit(), inheritMany(), setOrUpdateInterceptorsByTag(), setOrUpdateLeafTags(), updateHolder()

### Community 76 - "web"
Cohesion: 0.40
Nodes (5): web, background_color, generate, image_path, theme_color

### Community 78 - "ai"
Cohesion: 0.40
Nodes (5): ai(), bO(), cO(), d7(), e3()

### Community 79 - "eg"
Cohesion: 0.40
Nodes (5): c2(), cL(), ef(), eg(), r_()

### Community 80 - "installInstanceTearOff"
Cohesion: 0.40
Nodes (5): installInstanceTearOff(), installStaticTearOff(), instanceTearOffGetter(), staticTearOffGetter(), tearOffParameters()

### Community 81 - "DiaryModel"
Cohesion: 0.50
Nodes (4): DiaryModel, VertexDiaryModel, _SilentModel, FakeDiaryModel

### Community 82 - "windows"
Cohesion: 0.50
Nodes (4): windows, generate, icon_size, image_path

### Community 83 - "getTag"
Cohesion: 0.50
Nodes (4): getTag(), getTagFirefox(), getTagFixed(), getTagIE()

### Community 84 - "Point"
Cohesion: 0.50
Nodes (3): Point, x, y

### Community 85 - "Size"
Cohesion: 0.50
Nodes (3): Size, height, width

### Community 89 - "LocalDatabaseService"
Cohesion: 0.67
Nodes (3): RangeSessionBlock, LocalDatabaseService, _snapshotBlocks

### Community 90 - "aZ"
Cohesion: 0.67
Nodes (3): aq(), aZ(), dg()

### Community 91 - "bx"
Cohesion: 0.67
Nodes (3): bx(), c8(), c9()

### Community 92 - "cE"
Cohesion: 0.67
Nodes (3): c1(), cE(), f0()

### Community 94 - "X"
Cohesion: 0.67
Nodes (3): gcn(), X(), z()

## Knowledge Gaps
- **1005 isolated node(s):** `kRecaptchaSiteKey`, `shouldActivateAppCheck`, `activateWebAppCheck`, `appCheckDebugState`, `PhGolfCourse` (+1000 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 1659 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **51 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `GolferProfile` connect `onboarding_gate.dart` to `golfer_baseline_sheet.dart`, `swing_diary_prompt.dart`, `golfer_profile.dart`, `swing_diary_sheet.dart`, `range_drill_screen.dart`, `onboarding_starter_wizard.dart`, `golfer_profile_service.dart`?**
  _High betweenness centrality (0.016) - this node is a cross-community bridge._
- **Are the 60 inferred relationships involving `b()` (e.g. with `a0()` and `aA()`) actually correct?**
  _`b()` has 60 INFERRED edges - model-reasoned connections that need verification._
- **What connects `kRecaptchaSiteKey`, `shouldActivateAppCheck`, `activateWebAppCheck` to the rest of the system?**
  _1005 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `sqflite_sw.js` be split into smaller, more focused modules?**
  _Cohesion score 0.0048543689320388345 - nodes in this community are weakly interconnected._
- **Why does `SwingDiaryService` connect `swing_diary_service.dart` to `swing_diary_sheet.dart`, `range_drill_screen.dart`?**
  _High betweenness centrality (0.008) - this node is a cross-community bridge._
- **Are the 44 inferred relationships involving `c()` (e.g. with `aA()` and `aC()`) actually correct?**
  _`c()` has 44 INFERRED edges - model-reasoned connections that need verification._
- **Should `local_database_service.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.022988505747126436 - nodes in this community are weakly interconnected._