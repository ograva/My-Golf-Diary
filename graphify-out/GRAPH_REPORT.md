# Graph Report - My-Golf-Diary  (2026-11-19)

## Corpus Check
- 185 files · ~169,584 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 59 file(s) not represented in the graph (top: (none) 9, .xml 9, .xcconfig 8)

## Summary
- 3303 nodes · 4559 edges · 190 communities (131 shown, 59 thin omitted)
- Extraction: 94% EXTRACTED · 6% INFERRED · 0% AMBIGUOUS · INFERRED: 265 edges (avg confidence: 0.86)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `9fbb3cb4`
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
- course_map_manifest.dart
- my_application.cc
- b
- caddy_session.dart
- p
- utils.cpp
- clubs_screen.dart
- swing_diary_prompt.dart
- win32_window.cpp
- main.dart
- round_summary.dart
- FlutterWindow
- b9
- @visibleForTesting
- caddy_golfer_merge_host.dart
- package:golf_diary_app/services/local_database_service.dart
- manifest.json
- Win32Window
- .MessageHandler
- golfer_profile.dart
- windows/flutter/generated_plugin_registrant.cc
- analysis_options.yaml
- caddy_shell.dart
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
- caddy_pairing_service.dart
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
- local_database_service_test.dart
- home_shell.dart
- ph_golf_catalog.dart
- range_session_log.dart
- account_auth_controller.dart
- caddy_pairing_gate.dart
- golfer_profile_store.dart
- pin_distance.dart
- diary_remote.dart
- shared_header_actions.dart
- onboarding_gate.dart
- StatelessWidget
- diary_model.dart
- diary_context_note.dart
- json
- pwa_update_test.dart
- on_course_crse_035_test.dart
- vertex_diary_model.dart
- app_check_config.dart
- hole_map_geo.dart
- scorecard_cart_panel.dart
- flutter_launcher_icons
- pwa_update_client_web.dart
- return
- practice_drill_seed.dart
- sync_cloud_button.dart
- pubspec.yaml
- pwa_update_client.dart
- ../models/golf_models.dart
- ../models/golfer_profile.dart
- static const
- sync_identity.dart
- practice_drill_metadata.dart
- dev_dependencies
- caddy_on_course_screen.dart
- pwa_update_client_stub.dart
- web
- pwa_service_worker.js
- cloud-agent-install.sh
- pwa_published_build.dart
- DiaryModel
- caddy_round_channel_store.dart
- windows
- caddy_invite_sheet.dart
- LocalDatabaseService
- _ClubSortKey
- State
- app_build_id.dart
- steps
- build_web.sh
- recaptcha_assessment.sh
- caddy_scorecard_screen.dart
- courses.py
- on_course_header_test.dart
- mgdv_501_caddy_pairing_test.dart
- HoleFrame
- coverage.py
- hole_map_marker_painter.dart
- LocalFrame
- package:golf_diary_app/models/golfer_profile.dart
- course_map_cache_service.dart
- hole_frame.py
- oncourse_map_pane.dart
- on_course_test_helpers.dart
- account_avatar_app_bar_menu.dart
- oncourse_satellite_hole_map.dart
- on_course_shot_segment_test.dart
- account_login_sheet.dart
- account_sync_settings_screen.dart
- render.py
- package:flutter_test/flutter_test.dart
- account_session.dart
- on_course_crse_033_test.dart
- account_profile_screen.dart
- on_course_shot_segment.dart
- ../data/ph_golf_hole_coords.dart
- Hole
- caddy_invite_app_bar_button.dart
- VoidCallback?
- course_map_pack_local.dart
- sync_merge.dart
- package:golf_diary_app/services/local_database_service.dart
- ../models/caddy_session.dart
- ScorecardScreenState
- _MinIntrinsicHeight
- _RenderMinIntrinsicHeight
- _NewRoundDialog
- flutter

## God Nodes (most connected - your core abstractions)
1. `b()` - 70 edges
2. `c()` - 45 edges
3. `HoleFrame` - 28 edges
4. `p()` - 28 edges
5. `d()` - 23 edges
6. `o()` - 22 edges
7. `Win32Window` - 21 edges
8. `dependencies` - 21 edges
9. `j()` - 20 edges
10. `build()` - 16 edges

## Surprising Connections (you probably didn't know these)
- `build()` --uses--> `Course`  [INFERRED]
  tools/map_pack/build_pack.py → tools/map_pack/courses.py
- `hole_matches()` --uses--> `Course`  [INFERRED]
  tools/map_pack/coverage.py → tools/map_pack/courses.py
- `build_frame()` --uses--> `Feature`  [INFERRED]
  tools/map_pack/hole_frame.py → tools/map_pack/geo.py
- `HoleFrame` --uses--> `Feature`  [INFERRED]
  tools/map_pack/hole_frame.py → tools/map_pack/geo.py
- `_match_hole_line()` --uses--> `Feature`  [INFERRED]
  tools/map_pack/hole_frame.py → tools/map_pack/geo.py

## Import Cycles
- None detected.

## Communities (190 total, 59 thin omitted)

### Community 1 - "app_theme.dart"
Cohesion: 0.04
Nodes (47): amber, AppColors, birdieGold, birdieGoldDark, buildGolfTheme, _buildTextTheme, cream, creamElevated (+39 more)

### Community 2 - "dependencies"
Cohesion: 0.10
Nodes (20): dependencies, cloud_firestore, cupertino_icons, firebase_ai, firebase_app_check, firebase_auth, firebase_core, firebase_storage (+12 more)

### Community 3 - "golf_models.dart"
Cohesion: 0.03
Nodes (61): aimDirection, avgDistance, avgYards, brand, category, clubId, clubName, compareClubs (+53 more)

### Community 4 - "local_database_service.dart"
Cohesion: 0.02
Nodes (101): _addColumnIfMissing, applyCoursePar, applyRemoteRow, _backfillGolfRounds, _columns, compileRangeSession, completeRound, computeRoundTotals (+93 more)

### Community 5 - "GeneratedPluginRegistrant.swift"
Cohesion: 0.05
Nodes (23): cloud_firestore, Cocoa, firebase_ai, firebase_app_check, firebase_auth, firebase_core, firebase_storage, Flutter (+15 more)

### Community 6 - "scorecard_screen.dart"
Cohesion: 0.04
Nodes (47): build, _cartGimme, _cartHighContrast, _cartMulligan, _cartMutation, _cartPenalty, _cartPlusStroke, _cartSelectedHole (+39 more)

### Community 7 - "fairway_tracker_screen.dart"
Cohesion: 0.02
Nodes (107): _activeCoords, _aim, _aimDirection, _aimLabel, _appliedCourseName, _beginPinWatch, _bootstrap, build (+99 more)

### Community 8 - "scorecard_hole_editor.dart"
Cohesion: 0.06
Nodes (32): RoundScore, _adjustPenalties, _adjustStrokes, build, _conceded, _CounterRow, courseName, createState (+24 more)

### Community 9 - "range_drill_screen.dart"
Cohesion: 0.04
Nodes (41): Club, _allClubs, _applyClubStrip, _applyLeadIn, _avgController, build, _buildYardageInputs, _clubs (+33 more)

### Community 10 - "course_map_manifest.dart"
Cohesion: 0.06
Nodes (25): courseId, CourseMapManifest, entry, fromJson, hasSatelliteImage, heightPx, hole, HoleMapManifestEntry (+17 more)

### Community 11 - "my_application.cc"
Cohesion: 0.09
Nodes (13): fl_register_plugins(), main(), my_application_activate(), my_application_class_init(), my_application_dispose(), my_application_init(), my_application_local_command_line(), my_application_new() (+5 more)

### Community 12 - "b"
Cohesion: 0.04
Nodes (82): A(), a0(), aA(), aC(), aD(), aE(), aG(), aK() (+74 more)

### Community 13 - "caddy_session.dart"
Cohesion: 0.05
Nodes (34): authorUid, caddy, CaddyEventType, CaddyRoundEvent, CaddySessionRole, CaddySessionStatus, caddyUid, channelId (+26 more)

### Community 14 - "p"
Cohesion: 0.05
Nodes (65): $0(), $1(), a1(), a3(), a4(), a5(), aH(), aU() (+57 more)

### Community 15 - "utils.cpp"
Cohesion: 0.19
Nodes (4): wWinMain(), CreateAndAttachConsole(), GetCommandLineArguments(), Utf8FromUtf16()

### Community 16 - "clubs_screen.dart"
Cohesion: 0.04
Nodes (49): YardageUiDensity, _addClub, _brand, build, categories, _category, club, _clubs (+41 more)

### Community 17 - "swing_diary_prompt.dart"
Cohesion: 0.03
Nodes (77): brief, buffer, buildDiarySystemInstruction, clubName, clubs, ClubTally, compiledIds, _compose (+69 more)

### Community 18 - "win32_window.cpp"
Cohesion: 0.15
Nodes (8): EnableNonClientDpiScaling, Scale(), Win32Window::Win32Window(), WindowClassRegistrar, class_registered_, WindowClassRegistrar::GetWindowClass(), instance_, WindowClassRegistrar::UnregisterWindowClass()

### Community 19 - "main.dart"
Cohesion: 0.18
Nodes (6): build, GolfDiaryApp, initDesktopDatabase, initializeFirebase, main, preparePwaSession

### Community 20 - "round_summary.dart"
Cohesion: 0.10
Nodes (19): backNinePar, backNineScore, backNineToPar, completedAtMs, courseName, frontNinePar, frontNineScore, frontNineToPar (+11 more)

### Community 21 - "FlutterWindow"
Cohesion: 0.11
Nodes (4): FlutterWindow, flutter_controller_, FlutterWindow::FlutterWindow(), project_

### Community 22 - "b9"
Cohesion: 0.22
Nodes (9): aP(), b9(), bL(), cF(), cV(), cX(), dh(), gbZ() (+1 more)

### Community 23 - "@visibleForTesting"
Cohesion: 0.18
Nodes (10): ClubBagDetailsSheet, ClubRangeLogSheet, EditClubDialog, _EditClubDialogState, SwingNotesDialog, _SwingNotesDialogState, debugSetInstance, debugSetSession (+2 more)

### Community 24 - "caddy_golfer_merge_host.dart"
Cohesion: 0.10
Nodes (16): applier, _attach, _bootstrap, build, CaddyGolferMergeHost, _CaddyGolferMergeHostState, child, createState (+8 more)

### Community 25 - "package:golf_diary_app/services/local_database_service.dart"
Cohesion: 0.06
Nodes (27): ClubEditResult, SaveRoundBeforeNewChoice, showSaveRoundBeforeNewDialog, club, main, openDialog, main, restoreDatabase (+19 more)

### Community 26 - "manifest.json"
Cohesion: 0.18
Nodes (10): background_color, description, display, icons, name, orientation, prefer_related_applications, short_name (+2 more)

### Community 27 - "Win32Window"
Cohesion: 0.21
Nodes (4): Win32Window, child_content_, quit_on_close_, window_handle_

### Community 29 - "golfer_profile.dart"
Cohesion: 0.03
Nodes (62): age, amateur, any, bagNickname, baselineLabel, beginner, blurb, clubsMissingEquipmentSpecs (+54 more)

### Community 31 - "analysis_options.yaml"
Cohesion: 0.33
Nodes (5): analyzer, exclude, include, linter, rules

### Community 32 - "caddy_shell.dart"
Cohesion: 0.12
Nodes (14): CaddySessionRecord, build, CaddyShell, _CaddyShellState, createState, _index, pairing, session (+6 more)

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
Cohesion: 0.21
Nodes (6): Point, x, y, Size, height, width

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

### Community 46 - "caddy_pairing_service.dart"
Cohesion: 0.11
Nodes (15): _channelStore, _db, _defaultStore, expiresAt, flushOfflineQueue, getCaddyActiveSession, getGolferActiveSession, mintInvite (+7 more)

### Community 48 - "X"
Cohesion: 0.67
Nodes (3): gcn(), X(), z()

### Community 81 - "onboarding_starter_wizard.dart"
Cohesion: 0.06
Nodes (30): _ageController, _ageError, build, controller, createState, dispose, _draftProfile, errorText (+22 more)

### Community 82 - "golfer_profile_settings_screen.dart"
Cohesion: 0.07
Nodes (25): _ageController, _ageError, _base, build, _busy, createState, diary, dispose (+17 more)

### Community 83 - "ph_golf_hole_coords.dart"
Cohesion: 0.13
Nodes (13): _byCourse, canonicalCourseName, direct, greenLat, greenLon, hallow, hasHoleCoordinates, lower (+5 more)

### Community 84 - "pwa_update_host.dart"
Cohesion: 0.08
Nodes (20): _applying, build, _check, _checking, child, client, createState, dialogKey (+12 more)

### Community 85 - "practice_drill_sheet.dart"
Cohesion: 0.06
Nodes (35): category, fromMap, id, isCustom, PracticeDrill, recommendedClubs, shortDescription, steps (+27 more)

### Community 86 - "swing_diary_test.dart"
Cohesion: 0.08
Nodes (20): available, calls, db, error, generate, generateJson, hold, jsonReply (+12 more)

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
Cohesion: 0.11
Nodes (16): build, _busy, createState, diary, dispose, _distill, _edited, _equipment (+8 more)

### Community 93 - "local_database_service_test.dart"
Cohesion: 0.13
Nodes (8): main, db, main, saveBlock, bag, _drillById, main, seed

### Community 94 - "home_shell.dart"
Cohesion: 0.11
Nodes (12): _bagKey, build, _courseKey, createState, HomeShell, _HomeShellState, _index, _onProfileSettingsChanged (+4 more)

### Community 95 - "ph_golf_catalog.dart"
Cohesion: 0.11
Nodes (17): courseCaption, courseNames, courses, hasCard, holeCount, holePars, holes, matchCourse (+9 more)

### Community 96 - "range_session_log.dart"
Cohesion: 0.11
Nodes (16): RangeDrillSummary, build, compiled, CompiledRangeSessionCard, date, emptyMessage, entry, formatRangeSessionWhen (+8 more)

### Community 97 - "account_auth_controller.dart"
Cohesion: 0.07
Nodes (22): _auth, _authOverride, _ConflictMarker, disposeController, _fromUser, _googleOverride, _googleSignIn, instance (+14 more)

### Community 98 - "caddy_pairing_gate.dart"
Cohesion: 0.14
Nodes (10): build, buildCaddyLaunchRoot, config, createState, _error, initState, _loading, pairing (+2 more)

### Community 99 - "golfer_profile_store.dart"
Cohesion: 0.13
Nodes (11): GolferProfile, AccountAuthController, GolferProfileScope, GolferProfileStore, load, maybeOf, of, persist (+3 more)

### Community 100 - "pin_distance.dart"
Cohesion: 0.12
Nodes (16): catalogTeeToGreenYards, current, fromLat, fromLon, GeolocatorPinDistanceClient, hole, latitude, locationSettings (+8 more)

### Community 101 - "diary_remote.dart"
Cohesion: 0.15
Nodes (10): _collection, DiaryRemote, docs, failOnSet, _firestore, FirestoreDiaryRemote, _key, listDocuments (+2 more)

### Community 102 - "shared_header_actions.dart"
Cohesion: 0.06
Nodes (27): DiaryContextSource, DiaryContextSourceLabels, SwingDiaryService, build, diary, DiaryEntryButton, diaryStore, entryKey (+19 more)

### Community 103 - "onboarding_gate.dart"
Cohesion: 0.13
Nodes (12): build, _caddyRequestToken, createState, _enterShell, initState, _loading, OnboardingGate, _OnboardingGateState (+4 more)

### Community 104 - "StatelessWidget"
Cohesion: 0.12
Nodes (15): _ClubBagCard, _StatChip, _YardageTrend, _AgeStep, _GenderStep, _SkillTierStep, _YearsStep, _HoleTile (+7 more)

### Community 105 - "diary_model.dart"
Cohesion: 0.14
Nodes (12): available, bindAbort, cancel, _cancelled, DiaryCancel, DiaryCancelled, generate, generateJson (+4 more)

### Community 106 - "diary_context_note.dart"
Cohesion: 0.17
Nodes (10): content, contextDate, DiaryContextNote, fromStorage, id, promptLabel, roundId, source (+2 more)

### Community 107 - "json"
Cohesion: 0.26
Nodes (5): _client(), main(), _merged_index(), _put(), validate()

### Community 108 - "pwa_update_test.dart"
Cohesion: 0.14
Nodes (9): applyCount, applyUpdate, fetchPublishedBuild, main, published, pump, pumpAndSettle, _pumpHost (+1 more)

### Community 109 - "on_course_crse_035_test.dart"
Cohesion: 0.06
Nodes (23): PinFix, current, fix, live, main, waitForBag, watch, main (+15 more)

### Community 110 - "vertex_diary_model.dart"
Cohesion: 0.14
Nodes (8): available, defaultLocation, generate, generateJson, location, modelId, modelName, useGoogleFonts

### Community 111 - "app_check_config.dart"
Cohesion: 0.12
Nodes (11): activateWebAppCheck, appCheckDebugState, kRecaptchaSiteKey, shouldActivateAppCheck, DefaultFirebaseOptions, web, buildInviteUrl, CaddyLaunchConfig (+3 more)

### Community 112 - "hole_map_geo.dart"
Cohesion: 0.07
Nodes (26): boundsForHole, fromManifest, latPad, lats, latSpan, lonPad, lons, lonSpan (+18 more)

### Community 113 - "scorecard_cart_panel.dart"
Cohesion: 0.10
Nodes (18): _actionMinSize, build, _CartTotalsBar, courseName, fg, highContrast, holeCount, label (+10 more)

### Community 114 - "flutter_launcher_icons"
Cohesion: 0.18
Nodes (11): flutter_launcher_icons, adaptive_icon_background, adaptive_icon_foreground, android, image_path, ios, macos, min_sdk_android (+3 more)

### Community 115 - "pwa_update_client_web.dart"
Cohesion: 0.24
Nodes (6): applyPwaUpdate, _applyPwaUpdate, _disableServiceWorker, fetchPublishedBuild, _fetchPublishedBuild, preparePwaSession

### Community 116 - "return"
Cohesion: 0.18
Nodes (8): kOnCourseAimCenter, kOnCourseAimChoices, kOnCourseAimLeft, kOnCourseAimRight, normalizeOnCourseAim, published, shouldOfferPwaUpdate, true

### Community 117 - "practice_drill_seed.dart"
Cohesion: 0.14
Nodes (11): category, id, kPracticeDrillSeed, practiceArea, PracticeDrillSeed, recommendedClubs, shortDescription, steps (+3 more)

### Community 118 - "sync_cloud_button.dart"
Cohesion: 0.12
Nodes (12): failure, messenger, result, runDiarySync, uid, build, failure, messenger (+4 more)

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
Cohesion: 0.11
Nodes (15): HeaderActionPolicy, HeaderTabContext, resolve, showCaddyInOverflow, showCaddyPinned, showDiaryInOverflow, showDiaryPinned, usePlayOverflow (+7 more)

### Community 123 - "static const"
Cohesion: 0.20
Nodes (6): cart, classic, defaultMode, label, ScorecardViewMode, values

### Community 124 - "sync_identity.dart"
Cohesion: 0.25
Nodes (4): canSync, currentUserId, ensureSignedIn, SyncIdentity

### Community 125 - "practice_drill_metadata.dart"
Cohesion: 0.33
Nodes (4): isBeginnerFriendlyDrill, kBeginnerFriendlyDrillIds, practiceAreaForDrill, practiceAreaLabel

### Community 126 - "dev_dependencies"
Cohesion: 0.33
Nodes (6): dev_dependencies, flutter_launcher_icons, flutter_lints, flutter_test, sqlite3, sdk

### Community 127 - "caddy_on_course_screen.dart"
Cohesion: 0.14
Nodes (12): build, _busy, createState, _hole, initState, _loadHole, pairing, _par (+4 more)

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
Cohesion: 0.40
Nodes (5): DiaryModel, VertexDiaryModel, _SilentModel, _QuietDiaryModel, FakeDiaryModel

### Community 134 - "caddy_round_channel_store.dart"
Cohesion: 0.14
Nodes (14): appendEvent, CaddyRoundChannelStore, channels, createChannel, events, _firestore, FirestoreCaddyRoundChannelStore, flushPendingEvents (+6 more)

### Community 135 - "windows"
Cohesion: 0.50
Nodes (4): windows, generate, icon_size, image_path

### Community 136 - "caddy_invite_sheet.dart"
Cohesion: 0.13
Nodes (14): build, CaddyInviteSheet, _CaddyInviteSheetState, courseName, createState, _error, initState, _loading (+6 more)

### Community 137 - "LocalDatabaseService"
Cohesion: 0.67
Nodes (3): RangeSessionBlock, LocalDatabaseService, _snapshotBlocks

### Community 139 - "State"
Cohesion: 0.12
Nodes (22): PwaUpdateHost, _PwaUpdateHostState, CaddyOnCourseScreen, _CaddyOnCourseScreenState, CaddyPairingGate, _CaddyPairingGateState, _AddClubDialog, _AddClubDialogState (+14 more)

### Community 141 - "steps"
Cohesion: 0.08
Nodes (25): concurrency, cancel-in-progress, group, runs-on, steps, APP_BUILD_ID, GITHUB_TOKEN, jobs (+17 more)

### Community 144 - "caddy_scorecard_screen.dart"
Cohesion: 0.20
Nodes (8): build, CaddyScorecardScreen, _CaddyScorecardScreenState, createState, _holes, initState, _reload, session

### Community 145 - "courses.py"
Cohesion: 0.32
Nodes (8): Course, find_course(), _hole_pars(), load_courses(), name_based_id(), name_slug(), _unescape(), _venue_ids()

### Community 152 - "on_course_header_test.dart"
Cohesion: 0.09
Nodes (18): available, generate, generateJson, location, main, modelName, available, closeDiary (+10 more)

### Community 153 - "mgdv_501_caddy_pairing_test.dart"
Cohesion: 0.22
Nodes (3): main, restoreDatabase, useFreshDatabase

### Community 154 - "HoleFrame"
Cohesion: 0.17
Nodes (5): along(), corridor(), HoleFrame, render_preview(), synthesise()

### Community 155 - "coverage.py"
Cohesion: 0.22
Nodes (6): coverage_rows(), grade(), classify(), parse_elements(), golf_features_query(), run()

### Community 156 - "hole_map_marker_painter.dart"
Cohesion: 0.14
Nodes (10): HoleMapBounds, _SparklinePainter, bounds, colorScheme, coords, HoleMapMarkerPainter, paint, player (+2 more)

### Community 157 - "LocalFrame"
Cohesion: 0.23
Nodes (5): hole_matches(), LocalFrame, point(), build_frame(), _match_hole_line()

### Community 159 - "package:golf_diary_app/models/golfer_profile.dart"
Cohesion: 0.12
Nodes (8): amateur, beginner, main, pro, main, pumpHeader, drill, main

### Community 160 - "course_map_cache_service.dart"
Cohesion: 0.10
Nodes (16): canonicalCourseName, CourseMapCacheService, courseMapPackIdFromName, CourseMapResolveKind, CourseMapResolveResult, debugHasPack, debugHoleFrame, _downloadPackFromStorage (+8 more)

### Community 161 - "hole_frame.py"
Cohesion: 0.17
Nodes (9): distance_m(), Feature, feature_geometry(), _best(), compute_markers(), _layers(), Marker, _reason() (+1 more)

### Community 162 - "oncourse_map_pane.dart"
Cohesion: 0.10
Nodes (18): build, coords, courseName, createState, didUpdateWidget, _downloading, _frame, holeNumber (+10 more)

### Community 163 - "on_course_test_helpers.dart"
Cohesion: 0.11
Nodes (18): ensureVisible, enterText, expander, expandShotList, openCourseSheet, parSummaryLabel, pickCourse, pump (+10 more)

### Community 164 - "account_avatar_app_bar_menu.dart"
Cohesion: 0.12
Nodes (12): _openGolferProfile, AccountAvatarAppBarMenu, _AccountAvatarAppBarMenuState, build, createState, dispose, initState, _onLoginOrSignOut (+4 more)

### Community 165 - "oncourse_satellite_hole_map.dart"
Cohesion: 0.12
Nodes (13): HoleCoordinates, HoleMapFrame, build, coords, frame, OncourseSatelliteHoleMap, player, shots (+5 more)

### Community 166 - "on_course_shot_segment_test.dart"
Cohesion: 0.22
Nodes (6): distanceYards, lat, lon, main, _shot, stroke

### Community 167 - "account_login_sheet.dart"
Cohesion: 0.12
Nodes (16): AccountLoginSheet, _AccountLoginSheetState, build, _busy, _createAccount, createState, dispose, _emailController (+8 more)

### Community 168 - "account_sync_settings_screen.dart"
Cohesion: 0.13
Nodes (12): AccountSyncSettingsScreen, _AccountSyncSettingsScreenState, build, createState, _dirtyCount, dispose, _formatLastSync, initState (+4 more)

### Community 169 - "render.py"
Cohesion: 0.17
Nodes (10): build(), _coverage_label(), write_index(), contact_sheet(), _dashed(), _fill(), _font(), _polys() (+2 more)

### Community 170 - "package:flutter_test/flutter_test.dart"
Cohesion: 0.14
Nodes (5): main, pumpMenu, main, main, main

### Community 171 - "account_session.dart"
Cohesion: 0.14
Nodes (13): AccountSession, displayName, email, isAnonymous, isDurableAccount, isEmailPasswordAccount, isEmailVerified, isGoogleAccount (+5 more)

### Community 172 - "on_course_crse_033_test.dart"
Cohesion: 0.15
Nodes (5): build, coords, createState, main, _shots

### Community 173 - "account_profile_screen.dart"
Cohesion: 0.20
Nodes (8): AccountProfileScreen, _AccountProfileScreenState, build, createState, dispose, initState, _rebuild, _signOut

### Community 174 - "on_course_shot_segment.dart"
Cohesion: 0.22
Nodes (8): ShotRecord, hasCurrentStart, hasPriorStart, meters, prior, segment, segmentYardsEndingAt, shotDistanceLabel

### Community 175 - "../data/ph_golf_hole_coords.dart"
Cohesion: 0.25
Nodes (6): activeHoleCoordinates, courseName, hasHoleCoordinates, holeCoordinates, holeNumber, onCourseMappedHoleFeatures

### Community 177 - "caddy_invite_app_bar_button.dart"
Cohesion: 0.29
Nodes (5): build, CaddyInviteIconButton, courseName, roundId, valueKey

### Community 178 - "VoidCallback?"
Cohesion: 0.29
Nodes (3): build, onProfileChanged, _open

### Community 179 - "course_map_pack_local.dart"
Cohesion: 0.33
Nodes (3): CourseMapPackLocal, hasPackForCourse, instance

### Community 180 - "sync_merge.dart"
Cohesion: 0.29
Nodes (6): decideMerge, MergeAction, readDeleted, readUpdatedAtMs, tryParse, value

### Community 181 - "package:golf_diary_app/services/local_database_service.dart"
Cohesion: 0.09
Nodes (10): initDesktopDatabase, db, main, main, main, restoreDatabase, useFreshDatabase, main (+2 more)

### Community 182 - "../models/caddy_session.dart"
Cohesion: 0.33
Nodes (3): apply, CaddyEventApplier, _db

## Knowledge Gaps
- **1669 isolated node(s):** `amber`, `AppColors`, `birdieGold`, `birdieGoldDark`, `buildGolfTheme` (+1664 more)
  These have ≤1 connection - possible missing edges. (Counts symbols only; 2453 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **59 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Win32Window` connect `Win32Window` to `Point`, `win32_window.cpp`, `FlutterWindow`, `.MessageHandler`, `String?`?**
  _High betweenness centrality (0.019) - this node is a cross-community bridge._
- **Are the 60 inferred relationships involving `b()` (e.g. with `a0()` and `aA()`) actually correct?**
  _`b()` has 60 INFERRED edges - model-reasoned connections that need verification._
- **What connects `amber`, `AppColors`, `birdieGold` to the rest of the system?**
  _1669 weakly-connected nodes found - possible missing edges._
- **Should `sqflite_sw.js` be split into smaller, more focused modules?**
  _Cohesion score 0.0048543689320388345 - nodes in this community are weakly interconnected._
- **Why does `GolferProfile` connect `golfer_profile_store.dart` to `onboarding_gate.dart`, `swing_diary_sheet.dart`, `range_drill_screen.dart`, `clubs_screen.dart`, `onboarding_starter_wizard.dart`, `golfer_profile_settings_screen.dart`, `swing_diary_prompt.dart`, `golfer_profile_service.dart`, `golfer_baseline_sheet.dart`, `golfer_profile.dart`?**
  _High betweenness centrality (0.011) - this node is a cross-community bridge._
- **Are the 44 inferred relationships involving `c()` (e.g. with `aA()` and `aC()`) actually correct?**
  _`c()` has 44 INFERRED edges - model-reasoned connections that need verification._
- **Should `app_theme.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.038461538461538464 - nodes in this community are weakly interconnected._