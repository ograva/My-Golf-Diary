# Graph Report - My-Golf-Diary  (2026-11-15)

## Corpus Check
- 123 files · ~134,518 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 57 file(s) not represented in the graph (top: .xml 9, (none) 8, .xcconfig 8)

## Summary
- 2402 nodes · 3189 edges · 152 communities (94 shown, 58 thin omitted)
- Extraction: 93% EXTRACTED · 7% INFERRED · 0% AMBIGUOUS · INFERRED: 228 edges (avg confidence: 0.85)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `757bacf5`
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
- dart:async
- my_application.cc
- b
- c
- p
- utils.cpp
- clubs_screen.dart
- swing_diary_prompt.dart
- win32_window.cpp
- main.dart
- round_summary.dart
- FlutterWindow
- b9
- State
- d
- package:sqflite/sqflite.dart
- manifest.json
- Win32Window
- .MessageHandler
- golfer_profile.dart
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
- swing_diary_sheet.dart
- FlutterActivity
- swing_diary_service.dart
- aZ
- bx
- cE
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
- onboarding_starter_wizard.dart
- golfer_profile_settings_screen.dart
- ph_golf_hole_coords.dart
- pwa_update_host.dart
- practice_drill_sheet.dart
- swing_diary_test.dart
- golfer_profile_service.dart
- cloud_sync_service.dart
- venue_name_field.dart
- range_session.dart
- diary_markdown_body.dart
- golfer_baseline_sheet.dart
- package:flutter_test/flutter_test.dart
- home_shell.dart
- ph_golf_catalog.dart
- range_session_log.dart
- mgdv_203_progressive_disclosure_test.dart
- package:flutter/material.dart
- golfer_profile_store.dart
- pin_distance.dart
- diary_remote.dart
- diary_launcher.dart
- onboarding_gate.dart
- StatelessWidget
- diary_model.dart
- diary_context_note.dart
- range_session_wrapup_test.dart
- pwa_update_test.dart
- fairway_tracker_screen_test.dart
- vertex_diary_model.dart
- app_check_config.dart
- practice_drill.dart
- flutter_launcher_icons
- pwa_update_client_web.dart
- @visibleForTesting
- practice_drill_seed.dart
- sync_cloud_button.dart
- pubspec.yaml
- pwa_update_client.dart
- ../models/golf_models.dart
- ../models/golfer_profile.dart
- golfer_profile_test.dart
- sync_identity.dart
- practice_drill_metadata.dart
- dev_dependencies
- swing_diary_prompt_test.dart
- pwa_update_client_stub.dart
- web
- pwa_service_worker.js
- cloud-agent-install.sh
- pwa_published_build.dart
- DiaryModel
- List
- windows
- bool get
- LocalDatabaseService
- _ClubSortKey
- _SparklinePainter
- app_build_id.dart
- SwingDiarySheet
- build_web.sh
- recaptcha_assessment.sh
- by
- cD

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
10. `DiaryModel` - 12 edges

## Surprising Connections (you probably didn't know these)
- `wWinMain()` --calls--> `CreateAndAttachConsole()`  [INFERRED]
  golf_diary_app/windows/runner/main.cpp → golf_diary_app/windows/runner/utils.cpp
- `VertexDiaryModel` --implements--> `DiaryModel`  [EXTRACTED]
  golf_diary_app/lib/services/vertex_diary_model.dart → golf_diary_app/lib/services/diary_model.dart
- `_SilentModel` --implements--> `DiaryModel`  [EXTRACTED]
  golf_diary_app/test/golfer_profile_test.dart → golf_diary_app/lib/services/diary_model.dart
- `FakeDiaryModel` --implements--> `DiaryModel`  [EXTRACTED]
  golf_diary_app/test/swing_diary_test.dart → golf_diary_app/lib/services/diary_model.dart
- `FlutterWindow` --inherits--> `Win32Window`  [EXTRACTED]
  golf_diary_app/windows/runner/flutter_window.h → golf_diary_app/windows/runner/win32_window.h

## Import Cycles
- None detected.

## Communities (152 total, 58 thin omitted)

### Community 1 - "app_theme.dart"
Cohesion: 0.04
Nodes (47): amber, AppColors, birdieGold, birdieGoldDark, buildGolfTheme, _buildTextTheme, cream, creamElevated (+39 more)

### Community 2 - "dependencies"
Cohesion: 0.12
Nodes (17): dependencies, cloud_firestore, cupertino_icons, firebase_ai, firebase_app_check, firebase_auth, firebase_core, flutter (+9 more)

### Community 3 - "golf_models.dart"
Cohesion: 0.03
Nodes (59): avgDistance, avgYards, brand, category, clubId, clubName, compareClubs, compareTo (+51 more)

### Community 4 - "local_database_service.dart"
Cohesion: 0.02
Nodes (84): applyCoursePar, applyRemoteRow, _backfillGolfRounds, _columns, compileRangeSession, completeRound, computeRoundTotals, concedeHole (+76 more)

### Community 5 - "GeneratedPluginRegistrant.swift"
Cohesion: 0.06
Nodes (20): cloud_firestore, Cocoa, firebase_ai, firebase_app_check, firebase_auth, firebase_core, Flutter, FlutterMacOS (+12 more)

### Community 6 - "scorecard_screen.dart"
Cohesion: 0.05
Nodes (31): build, _controller, _courseName, createState, _deltaStyle, diary, dispose, _editHole (+23 more)

### Community 7 - "fairway_tracker_screen.dart"
Cohesion: 0.03
Nodes (57): _appliedCourseName, _beginPinWatch, _bootstrap, build, _busy, _clubId, _clubName, _clubs (+49 more)

### Community 8 - "scorecard_hole_editor.dart"
Cohesion: 0.06
Nodes (31): RoundScore, _adjustPenalties, _adjustStrokes, build, _conceded, courseName, createState, decKey (+23 more)

### Community 9 - "range_drill_screen.dart"
Cohesion: 0.04
Nodes (40): Club, _allClubs, _applyClubStrip, _applyLeadIn, _avgController, build, _buildYardageInputs, _clubs (+32 more)

### Community 10 - "dart:async"
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
Nodes (25): A(), aA(), aC(), aG(), aV(), bj(), bZ(), c() (+17 more)

### Community 14 - "p"
Cohesion: 0.05
Nodes (65): $0(), $1(), a1(), a3(), a4(), a5(), aH(), aU() (+57 more)

### Community 15 - "utils.cpp"
Cohesion: 0.19
Nodes (4): wWinMain(), CreateAndAttachConsole(), GetCommandLineArguments(), Utf8FromUtf16()

### Community 16 - "clubs_screen.dart"
Cohesion: 0.04
Nodes (48): YardageUiDensity, _addClub, _brand, build, categories, _category, club, _clubs (+40 more)

### Community 17 - "swing_diary_prompt.dart"
Cohesion: 0.03
Nodes (77): brief, buffer, buildDiarySystemInstruction, clubName, clubs, ClubTally, compiledIds, _compose (+69 more)

### Community 18 - "win32_window.cpp"
Cohesion: 0.14
Nodes (8): EnableNonClientDpiScaling, Scale(), Win32Window::Win32Window(), WindowClassRegistrar, class_registered_, WindowClassRegistrar::GetWindowClass(), instance_, WindowClassRegistrar::UnregisterWindowClass()

### Community 19 - "main.dart"
Cohesion: 0.18
Nodes (6): build, GolfDiaryApp, initDesktopDatabase, initializeFirebase, main, preparePwaSession

### Community 20 - "round_summary.dart"
Cohesion: 0.09
Nodes (19): backNinePar, backNineScore, backNineToPar, completedAtMs, courseName, frontNinePar, frontNineScore, frontNineToPar (+11 more)

### Community 21 - "FlutterWindow"
Cohesion: 0.11
Nodes (4): FlutterWindow, flutter_controller_, FlutterWindow::FlutterWindow(), project_

### Community 22 - "b9"
Cohesion: 0.22
Nodes (9): aP(), b9(), bL(), cF(), cV(), cX(), dh(), gbZ() (+1 more)

### Community 23 - "State"
Cohesion: 0.14
Nodes (18): PwaUpdateHost, _PwaUpdateHostState, _AddClubDialog, _AddClubDialogState, ClubsScreen, ClubsScreenState, FairwayTrackerScreen, FairwayTrackerScreenState (+10 more)

### Community 24 - "d"
Cohesion: 0.13
Nodes (16): bt(), cb(), cG(), d(), eB(), eC(), eP(), fA() (+8 more)

### Community 25 - "package:sqflite/sqflite.dart"
Cohesion: 0.11
Nodes (7): initDesktopDatabase, db, main, main, main, waitForGate, main

### Community 26 - "manifest.json"
Cohesion: 0.18
Nodes (10): background_color, description, display, icons, name, orientation, prefer_related_applications, short_name (+2 more)

### Community 27 - "Win32Window"
Cohesion: 0.16
Nodes (7): Size, height, width, Win32Window, child_content_, quit_on_close_, window_handle_

### Community 29 - "golfer_profile.dart"
Cohesion: 0.03
Nodes (59): age, amateur, any, bagNickname, baselineLabel, beginner, blurb, clubsMissingEquipmentSpecs (+51 more)

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

### Community 40 - "swing_diary_sheet.dart"
Cohesion: 0.04
Nodes (45): _appCheck, _applyLeadIn, _baselineSummary, _baselineUpdated, build, _busy, _cancel, _chunks (+37 more)

### Community 43 - "swing_diary_service.dart"
Cohesion: 0.06
Nodes (31): appendContextNote, ask, content, _database, day, _db, DiaryExchange, DiaryMessage (+23 more)

### Community 44 - "aZ"
Cohesion: 0.67
Nodes (3): aq(), aZ(), dg()

### Community 45 - "bx"
Cohesion: 0.67
Nodes (3): bx(), c8(), c9()

### Community 46 - "cE"
Cohesion: 0.67
Nodes (3): c1(), cE(), f0()

### Community 48 - "X"
Cohesion: 0.67
Nodes (3): gcn(), X(), z()

### Community 81 - "onboarding_starter_wizard.dart"
Cohesion: 0.06
Nodes (28): _ageController, _ageError, build, controller, createState, dispose, _draftProfile, errorText (+20 more)

### Community 82 - "golfer_profile_settings_screen.dart"
Cohesion: 0.07
Nodes (25): _ageController, _ageError, _base, build, _busy, createState, diary, dispose (+17 more)

### Community 83 - "ph_golf_hole_coords.dart"
Cohesion: 0.07
Nodes (23): _byCourse, canonicalCourseName, direct, greenLat, greenLon, hallow, hasHoleCoordinates, HoleCoordinates (+15 more)

### Community 84 - "pwa_update_host.dart"
Cohesion: 0.07
Nodes (19): _applying, build, _check, _checking, child, client, createState, dialogKey (+11 more)

### Community 85 - "practice_drill_sheet.dart"
Cohesion: 0.08
Nodes (25): _add, build, _category, copyTitleToNote, createState, _delete, _description, dispose (+17 more)

### Community 86 - "swing_diary_test.dart"
Cohesion: 0.08
Nodes (19): available, calls, db, error, generate, generateJson, hold, jsonReply (+11 more)

### Community 87 - "golfer_profile_service.dart"
Cohesion: 0.08
Nodes (22): changed, collectUndistilledNotes, _database, decoded, distillIfNeeded, DistillResult, GolferProfileService, isEmpty (+14 more)

### Community 88 - "cloud_sync_service.dart"
Cohesion: 0.09
Nodes (16): alreadyRunning, CloudSyncService, _db, failed, initializeFirebase, isAvailable, pullAll, pulled (+8 more)

### Community 89 - "venue_name_field.dart"
Cohesion: 0.09
Nodes (19): autofocus, build, catalogNames, controller, createState, didUpdateWidget, dispose, focusNode (+11 more)

### Community 90 - "range_session.dart"
Cohesion: 0.10
Nodes (20): avgYards, blocks, clubId, clubName, drillId, drillSteps, drillTitle, fromJson (+12 more)

### Community 91 - "diary_markdown_body.dart"
Cohesion: 0.10
Nodes (17): baseStyle, build, _CodeDiagramBox, data, DiaryMarkdownBody, header, _InlineMarkdownText, _isDiagramLine (+9 more)

### Community 92 - "golfer_baseline_sheet.dart"
Cohesion: 0.10
Nodes (18): build, _busy, createState, diary, dispose, _distill, _edited, _equipment (+10 more)

### Community 93 - "package:flutter_test/flutter_test.dart"
Cohesion: 0.11
Nodes (9): main, db, main, saveBlock, main, bag, _drillById, main (+1 more)

### Community 94 - "home_shell.dart"
Cohesion: 0.11
Nodes (13): _bagKey, build, _courseKey, createState, HomeShell, _HomeShellState, _index, _onTabSelected (+5 more)

### Community 95 - "ph_golf_catalog.dart"
Cohesion: 0.11
Nodes (17): courseCaption, courseNames, courses, hasCard, holeCount, holePars, holes, matchCourse (+9 more)

### Community 96 - "range_session_log.dart"
Cohesion: 0.11
Nodes (16): RangeDrillSummary, build, compiled, CompiledRangeSessionCard, date, emptyMessage, entry, formatRangeSessionWhen (+8 more)

### Community 97 - "mgdv_203_progressive_disclosure_test.dart"
Cohesion: 0.13
Nodes (12): main, restoreDatabase, useFreshDatabase, yardageLabel, db, main, restoreDatabase, useFreshDatabase (+4 more)

### Community 98 - "package:flutter/material.dart"
Cohesion: 0.13
Nodes (9): SaveRoundBeforeNewChoice, showSaveRoundBeforeNewDialog, club, main, openDialog, db, main, restoreDatabase (+1 more)

### Community 99 - "golfer_profile_store.dart"
Cohesion: 0.13
Nodes (10): GolferProfile, GolferProfileScope, GolferProfileStore, load, maybeOf, of, persist, profile (+2 more)

### Community 100 - "pin_distance.dart"
Cohesion: 0.13
Nodes (13): current, fromLat, fromLon, GeolocatorPinDistanceClient, latitude, locationSettings, longitude, meters (+5 more)

### Community 101 - "diary_remote.dart"
Cohesion: 0.14
Nodes (10): _collection, DiaryRemote, docs, failOnSet, _firestore, FirestoreDiaryRemote, _key, listDocuments (+2 more)

### Community 102 - "diary_launcher.dart"
Cohesion: 0.12
Nodes (10): SwingDiaryService, build, diary, DiaryEntryButton, diaryStore, entryKey, entrySource, model (+2 more)

### Community 103 - "onboarding_gate.dart"
Cohesion: 0.13
Nodes (11): build, createState, _enterShell, initState, _loading, OnboardingGate, _OnboardingGateState, _profile (+3 more)

### Community 104 - "StatelessWidget"
Cohesion: 0.13
Nodes (14): PwaUpdateDialog, _ClubBagCard, _StatChip, _YardageTrend, _AgeStep, _GenderStep, _SkillTierStep, _YearsStep (+6 more)

### Community 105 - "diary_model.dart"
Cohesion: 0.14
Nodes (12): available, bindAbort, cancel, _cancelled, DiaryCancel, DiaryCancelled, generate, generateJson (+4 more)

### Community 106 - "diary_context_note.dart"
Cohesion: 0.15
Nodes (12): content, contextDate, DiaryContextNote, DiaryContextSource, DiaryContextSourceLabels, fromStorage, id, promptLabel (+4 more)

### Community 107 - "range_session_wrapup_test.dart"
Cohesion: 0.14
Nodes (8): finishAction, main, pumpCourse, clearSnackBars, main, restoreDatabase, useFreshDatabase, usualYardsField

### Community 108 - "pwa_update_test.dart"
Cohesion: 0.14
Nodes (9): applyCount, applyUpdate, fetchPublishedBuild, main, published, pump, pumpAndSettle, _pumpHost (+1 more)

### Community 109 - "fairway_tracker_screen_test.dart"
Cohesion: 0.17
Nodes (8): PinFix, current, fix, live, main, waitForBag, watch, main

### Community 110 - "vertex_diary_model.dart"
Cohesion: 0.17
Nodes (7): available, defaultLocation, generate, generateJson, location, modelId, modelName

### Community 111 - "app_check_config.dart"
Cohesion: 0.18
Nodes (6): activateWebAppCheck, appCheckDebugState, kRecaptchaSiteKey, shouldActivateAppCheck, DefaultFirebaseOptions, web

### Community 113 - "practice_drill.dart"
Cohesion: 0.18
Nodes (10): category, fromMap, id, isCustom, PracticeDrill, recommendedClubs, shortDescription, steps (+2 more)

### Community 114 - "flutter_launcher_icons"
Cohesion: 0.18
Nodes (11): flutter_launcher_icons, adaptive_icon_background, adaptive_icon_foreground, android, image_path, ios, macos, min_sdk_android (+3 more)

### Community 115 - "pwa_update_client_web.dart"
Cohesion: 0.24
Nodes (6): applyPwaUpdate, _applyPwaUpdate, _disableServiceWorker, fetchPublishedBuild, _fetchPublishedBuild, preparePwaSession

### Community 116 - "@visibleForTesting"
Cohesion: 0.20
Nodes (9): ClubBagDetailsSheet, ClubEditResult, ClubRangeLogSheet, EditClubDialog, _EditClubDialogState, SwingNotesDialog, _SwingNotesDialogState, debugClose (+1 more)

### Community 117 - "practice_drill_seed.dart"
Cohesion: 0.20
Nodes (9): category, id, kPracticeDrillSeed, practiceArea, PracticeDrillSeed, recommendedClubs, shortDescription, steps (+1 more)

### Community 118 - "sync_cloud_button.dart"
Cohesion: 0.20
Nodes (7): build, failure, messenger, result, runDiarySync, SyncCloudButton, userId

### Community 119 - "pubspec.yaml"
Cohesion: 0.20
Nodes (9): description, environment, sdk, flutter, assets, uses-material-design, name, publish_to (+1 more)

### Community 120 - "pwa_update_client.dart"
Cohesion: 0.25
Nodes (6): applyUpdate, fetchPublishedBuild, PlatformPwaUpdateClient, preparePwaSession, PwaUpdateClient, _FakePwaUpdateClient

### Community 121 - "../models/golf_models.dart"
Cohesion: 0.22
Nodes (6): clubsForRangeStrip, defaultClubForRangeStrip, list, rangeDrillApproachMode, rangeDrillFocusLabel, rangeDrillShowsPutter

### Community 122 - "../models/golfer_profile.dart"
Cohesion: 0.22
Nodes (7): bagCategoryLabel, forDensity, formatCarryYards, longest, shortest, usual, YardageStatLabels

### Community 123 - "golfer_profile_test.dart"
Cohesion: 0.22
Nodes (6): available, generate, generateJson, location, main, modelName

### Community 124 - "sync_identity.dart"
Cohesion: 0.25
Nodes (4): canSync, currentUserId, ensureSignedIn, SyncIdentity

### Community 125 - "practice_drill_metadata.dart"
Cohesion: 0.33
Nodes (4): isBeginnerFriendlyDrill, kBeginnerFriendlyDrillIds, practiceAreaForDrill, practiceAreaLabel

### Community 126 - "dev_dependencies"
Cohesion: 0.33
Nodes (6): dev_dependencies, flutter_launcher_icons, flutter_lints, flutter_test, sqlite3, sdk

### Community 128 - "pwa_update_client_stub.dart"
Cohesion: 0.40
Nodes (3): applyPwaUpdate, fetchPublishedBuild, preparePwaSession

### Community 129 - "web"
Cohesion: 0.40
Nodes (5): web, background_color, generate, image_path, theme_color

### Community 131 - "cloud-agent-install.sh"
Cohesion: 0.67
Nodes (3): DEBIAN_FRONTEND, flutter_meets_version(), cloud-agent-install.sh script

### Community 132 - "pwa_published_build.dart"
Cohesion: 0.50
Nodes (3): buildId, PwaPublishedBuild, version

### Community 133 - "DiaryModel"
Cohesion: 0.50
Nodes (4): DiaryModel, VertexDiaryModel, _SilentModel, FakeDiaryModel

### Community 135 - "windows"
Cohesion: 0.50
Nodes (4): windows, generate, icon_size, image_path

### Community 137 - "LocalDatabaseService"
Cohesion: 0.67
Nodes (3): RangeSessionBlock, LocalDatabaseService, _snapshotBlocks

## Knowledge Gaps
- **1133 isolated node(s):** `DEBIAN_FRONTEND`, `kRecaptchaSiteKey`, `shouldActivateAppCheck`, `activateWebAppCheck`, `appCheckDebugState` (+1128 more)
  These have ≤1 connection - possible missing edges. (Counts symbols only; 1794 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **58 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Win32Window` connect `Win32Window` to `Point`, `String?`, `win32_window.cpp`, `FlutterWindow`, `.MessageHandler`?**
  _High betweenness centrality (0.016) - this node is a cross-community bridge._
- **Are the 60 inferred relationships involving `b()` (e.g. with `a0()` and `aA()`) actually correct?**
  _`b()` has 60 INFERRED edges - model-reasoned connections that need verification._
- **What connects `DEBIAN_FRONTEND`, `kRecaptchaSiteKey`, `shouldActivateAppCheck` to the rest of the system?**
  _1133 weakly-connected nodes found - possible missing edges._
- **Should `sqflite_sw.js` be split into smaller, more focused modules?**
  _Cohesion score 0.0048543689320388345 - nodes in this community are weakly interconnected._
- **Why does `GolferProfile` connect `golfer_profile_store.dart` to `onboarding_gate.dart`, `swing_diary_sheet.dart`, `range_drill_screen.dart`, `clubs_screen.dart`, `onboarding_starter_wizard.dart`, `golfer_profile_settings_screen.dart`, `swing_diary_prompt.dart`, `golfer_profile_service.dart`, `golfer_baseline_sheet.dart`, `golfer_profile.dart`?**
  _High betweenness centrality (0.015) - this node is a cross-community bridge._
- **Are the 44 inferred relationships involving `c()` (e.g. with `aA()` and `aC()`) actually correct?**
  _`c()` has 44 INFERRED edges - model-reasoned connections that need verification._
- **Should `app_theme.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.038461538461538464 - nodes in this community are weakly interconnected._