# Graph Report - My-Golf-Diary  (2026-11-19)

## Corpus Check
- 187 files · ~171,081 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 59 file(s) not represented in the graph (top: (none) 9, .xml 9, .xcconfig 8)

## Summary
- 3346 nodes · 4626 edges · 193 communities (134 shown, 59 thin omitted)
- Extraction: 94% EXTRACTED · 6% INFERRED · 0% AMBIGUOUS · INFERRED: 265 edges (avg confidence: 0.86)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `15ba5ab7`
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
- diary_launcher.dart
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
- header_action_policy.dart
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
- package:flutter/material.dart
- Size
- practice_drill.dart
- course_map_cache_service.dart
- hole_frame.py
- oncourse_map_pane.dart
- on_course_test_helpers.dart
- account_avatar_app_bar_menu.dart
- oncourse_satellite_hole_map.dart
- on_course_shot_segment_test.dart
- account_login_sheet.dart
- account_sync_settings_screen.dart
- build_pack.py
- package:flutter_test/flutter_test.dart
- account_session.dart
- course_map_cache_service_test.dart
- account_profile_screen.dart
- on_course_shot_segment.dart
- ../data/ph_golf_hole_coords.dart
- Hole
- caddy_invite_app_bar_button.dart
- VoidCallback?
- course_map_pack_local.dart
- ../models/golfer_profile.dart
- mgdv_401_cart_scoring_test.dart
- golfer_profile_test.dart
- ShotEditDialog
- _MinIntrinsicHeight
- _RenderMinIntrinsicHeight
- _NewRoundDialog
- flutter
- package:flutter/foundation.dart
- sync_merge.dart
- ../models/caddy_session.dart

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
- `HoleFrame` --uses--> `Hole`  [INFERRED]
  tools/map_pack/hole_frame.py → tools/map_pack/courses.py
- `HoleFrame` --uses--> `Feature`  [INFERRED]
  tools/map_pack/hole_frame.py → tools/map_pack/geo.py
- `HoleFrame` --uses--> `LocalFrame`  [INFERRED]
  tools/map_pack/hole_frame.py → tools/map_pack/geo.py

## Import Cycles
- None detected.

## Communities (193 total, 59 thin omitted)

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
Nodes (31): RoundScore, _adjustPenalties, _adjustStrokes, build, _conceded, courseName, createState, decKey (+23 more)

### Community 9 - "range_drill_screen.dart"
Cohesion: 0.04
Nodes (41): Club, _allClubs, _applyClubStrip, _applyLeadIn, _avgController, build, _buildYardageInputs, _clubs (+33 more)

### Community 10 - "course_map_manifest.dart"
Cohesion: 0.09
Nodes (20): courseId, CourseMapManifest, entry, fromJson, hasSatelliteImage, heightPx, hole, HoleMapManifestEntry (+12 more)

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
Cohesion: 0.12
Nodes (4): wWinMain(), CreateAndAttachConsole(), GetCommandLineArguments(), Utf8FromUtf16()

### Community 16 - "clubs_screen.dart"
Cohesion: 0.04
Nodes (49): YardageUiDensity, _addClub, _brand, build, categories, _category, club, _clubs (+41 more)

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
Cohesion: 0.10
Nodes (19): backNinePar, backNineScore, backNineToPar, completedAtMs, courseName, frontNinePar, frontNineScore, frontNineToPar (+11 more)

### Community 21 - "FlutterWindow"
Cohesion: 0.11
Nodes (4): FlutterWindow, flutter_controller_, FlutterWindow::FlutterWindow(), project_

### Community 22 - "b9"
Cohesion: 0.22
Nodes (9): aP(), b9(), bL(), cF(), cV(), cX(), dh(), gbZ() (+1 more)

### Community 23 - "diary_launcher.dart"
Cohesion: 0.11
Nodes (12): DiaryContextSource, DiaryContextSourceLabels, SwingDiaryService, build, diary, DiaryEntryButton, diaryStore, entryKey (+4 more)

### Community 24 - "caddy_golfer_merge_host.dart"
Cohesion: 0.10
Nodes (14): applier, _attach, _bootstrap, build, child, createState, _db, dispose (+6 more)

### Community 25 - "package:golf_diary_app/services/local_database_service.dart"
Cohesion: 0.06
Nodes (20): initDesktopDatabase, db, main, main, db, main, restoreDatabase, useFreshDatabase (+12 more)

### Community 26 - "manifest.json"
Cohesion: 0.18
Nodes (10): background_color, description, display, icons, name, orientation, prefer_related_applications, short_name (+2 more)

### Community 27 - "Win32Window"
Cohesion: 0.24
Nodes (4): Win32Window, child_content_, quit_on_close_, window_handle_

### Community 29 - "golfer_profile.dart"
Cohesion: 0.03
Nodes (62): age, amateur, any, bagNickname, baselineLabel, beginner, blurb, clubsMissingEquipmentSpecs (+54 more)

### Community 31 - "analysis_options.yaml"
Cohesion: 0.33
Nodes (5): analyzer, exclude, include, linter, rules

### Community 32 - "caddy_shell.dart"
Cohesion: 0.13
Nodes (12): CaddySessionRecord, build, createState, _index, pairing, session, CaddyPairingService, build (+4 more)

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

### Community 46 - "caddy_pairing_service.dart"
Cohesion: 0.11
Nodes (15): _channelStore, _db, _defaultStore, expiresAt, flushOfflineQueue, getCaddyActiveSession, getGolferActiveSession, mintInvite (+7 more)

### Community 48 - "X"
Cohesion: 0.67
Nodes (3): gcn(), X(), z()

### Community 81 - "onboarding_starter_wizard.dart"
Cohesion: 0.07
Nodes (28): _ageController, _ageError, build, controller, createState, dispose, _draftProfile, errorText (+20 more)

### Community 82 - "golfer_profile_settings_screen.dart"
Cohesion: 0.07
Nodes (25): _ageController, _ageError, _base, build, _busy, createState, diary, dispose (+17 more)

### Community 83 - "ph_golf_hole_coords.dart"
Cohesion: 0.12
Nodes (14): _byCourse, canonicalCourseName, direct, greenLat, greenLon, hallow, hasHoleCoordinates, lower (+6 more)

### Community 84 - "pwa_update_host.dart"
Cohesion: 0.08
Nodes (19): _applying, build, _check, _checking, child, client, createState, dialogKey (+11 more)

### Community 85 - "practice_drill_sheet.dart"
Cohesion: 0.08
Nodes (25): _add, build, _category, copyTitleToNote, createState, _delete, _description, dispose (+17 more)

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
Nodes (18): build, _busy, createState, diary, dispose, _distill, _edited, _equipment (+10 more)

### Community 93 - "local_database_service_test.dart"
Cohesion: 0.10
Nodes (10): main, db, main, saveBlock, bag, _drillById, main, seed (+2 more)

### Community 94 - "home_shell.dart"
Cohesion: 0.09
Nodes (16): ClubsScreen, ClubsScreenState, _bagKey, build, _courseKey, createState, HomeShell, _HomeShellState (+8 more)

### Community 95 - "ph_golf_catalog.dart"
Cohesion: 0.11
Nodes (17): courseCaption, courseNames, courses, hasCard, holeCount, holePars, holes, matchCourse (+9 more)

### Community 96 - "range_session_log.dart"
Cohesion: 0.11
Nodes (16): RangeDrillSummary, build, compiled, CompiledRangeSessionCard, date, emptyMessage, entry, formatRangeSessionWhen (+8 more)

### Community 97 - "account_auth_controller.dart"
Cohesion: 0.04
Nodes (34): ClubBagDetailsSheet, ClubRangeLogSheet, _auth, _authOverride, _ConflictMarker, debugSetInstance, debugSetSession, disposeController (+26 more)

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
Cohesion: 0.10
Nodes (15): build, caddyInviteKey, courseName, diary, diaryEntryKey, diaryLabel, diarySource, diaryStore (+7 more)

### Community 103 - "onboarding_gate.dart"
Cohesion: 0.13
Nodes (12): build, _caddyRequestToken, createState, _enterShell, initState, _loading, OnboardingGate, _OnboardingGateState (+4 more)

### Community 104 - "StatelessWidget"
Cohesion: 0.11
Nodes (16): PwaUpdateDialog, _ClubBagCard, _StatChip, _YardageTrend, _AgeStep, _GenderStep, _SkillTierStep, _YearsStep (+8 more)

### Community 105 - "diary_model.dart"
Cohesion: 0.14
Nodes (12): available, bindAbort, cancel, _cancelled, DiaryCancel, DiaryCancelled, generate, generateJson (+4 more)

### Community 106 - "diary_context_note.dart"
Cohesion: 0.17
Nodes (10): content, contextDate, DiaryContextNote, fromStorage, id, promptLabel, roundId, source (+2 more)

### Community 107 - "json"
Cohesion: 0.23
Nodes (6): write_index(), _client(), main(), _merged_index(), _put(), validate()

### Community 108 - "pwa_update_test.dart"
Cohesion: 0.14
Nodes (9): applyCount, applyUpdate, fetchPublishedBuild, main, published, pump, pumpAndSettle, _pumpHost (+1 more)

### Community 109 - "on_course_crse_035_test.dart"
Cohesion: 0.07
Nodes (20): PinFix, current, fix, live, main, waitForBag, watch, main (+12 more)

### Community 110 - "vertex_diary_model.dart"
Cohesion: 0.14
Nodes (8): available, defaultLocation, generate, generateJson, location, modelId, modelName, useGoogleFonts

### Community 111 - "app_check_config.dart"
Cohesion: 0.18
Nodes (6): activateWebAppCheck, appCheckDebugState, kRecaptchaSiteKey, shouldActivateAppCheck, DefaultFirebaseOptions, web

### Community 112 - "hole_map_geo.dart"
Cohesion: 0.07
Nodes (26): boundsForHole, fromManifest, latPad, lats, latSpan, lonPad, lons, lonSpan (+18 more)

### Community 113 - "scorecard_cart_panel.dart"
Cohesion: 0.09
Nodes (19): _actionMinSize, build, _CartTotalsBar, courseName, fg, highContrast, holeCount, label (+11 more)

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

### Community 122 - "header_action_policy.dart"
Cohesion: 0.22
Nodes (8): HeaderActionPolicy, HeaderTabContext, resolve, showCaddyInOverflow, showCaddyPinned, showDiaryInOverflow, showDiaryPinned, usePlayOverflow

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
Cohesion: 0.14
Nodes (12): build, courseName, createState, _error, initState, _loading, _mintOrLoad, pairing (+4 more)

### Community 137 - "LocalDatabaseService"
Cohesion: 0.67
Nodes (3): RangeSessionBlock, LocalDatabaseService, _snapshotBlocks

### Community 139 - "State"
Cohesion: 0.08
Nodes (32): PwaUpdateHost, _PwaUpdateHostState, CaddyOnCourseScreen, _CaddyOnCourseScreenState, CaddyPairingGate, _CaddyPairingGateState, CaddyScorecardScreen, _CaddyScorecardScreenState (+24 more)

### Community 141 - "steps"
Cohesion: 0.08
Nodes (25): concurrency, cancel-in-progress, group, runs-on, steps, APP_BUILD_ID, GITHUB_TOKEN, jobs (+17 more)

### Community 144 - "caddy_scorecard_screen.dart"
Cohesion: 0.22
Nodes (6): build, createState, _holes, initState, _reload, session

### Community 145 - "courses.py"
Cohesion: 0.32
Nodes (8): Course, find_course(), _hole_pars(), load_courses(), name_based_id(), name_slug(), _unescape(), _venue_ids()

### Community 152 - "on_course_header_test.dart"
Cohesion: 0.08
Nodes (18): amateur, beginner, main, pro, available, closeDiary, dbName, generate (+10 more)

### Community 153 - "mgdv_501_caddy_pairing_test.dart"
Cohesion: 0.22
Nodes (3): main, restoreDatabase, useFreshDatabase

### Community 155 - "coverage.py"
Cohesion: 0.17
Nodes (7): coverage_rows(), grade(), hole_matches(), point(), golf_features_query(), run(), main()

### Community 156 - "hole_map_marker_painter.dart"
Cohesion: 0.14
Nodes (11): HoleCoordinates, HoleMapBounds, _SparklinePainter, bounds, colorScheme, coords, HoleMapMarkerPainter, paint (+3 more)

### Community 157 - "package:flutter/material.dart"
Cohesion: 0.09
Nodes (17): ClubEditResult, SaveRoundBeforeNewChoice, showSaveRoundBeforeNewDialog, club, main, openDialog, main, restoreDatabase (+9 more)

### Community 158 - "Size"
Cohesion: 0.50
Nodes (3): Size, height, width

### Community 159 - "practice_drill.dart"
Cohesion: 0.18
Nodes (10): category, fromMap, id, isCustom, PracticeDrill, recommendedClubs, shortDescription, steps (+2 more)

### Community 160 - "course_map_cache_service.dart"
Cohesion: 0.05
Nodes (40): cachedImageBytes, canonicalCourseName, _courseId, CourseMapCacheService, courseMapPackId, courseMapPackIdFromName, CourseMapPackSource, CourseMapResolveKind (+32 more)

### Community 161 - "hole_frame.py"
Cohesion: 0.12
Nodes (10): distance_m(), Feature, feature_geometry(), LocalFrame, along(), build_frame(), _match_hole_line(), _best() (+2 more)

### Community 162 - "oncourse_map_pane.dart"
Cohesion: 0.11
Nodes (16): build, coords, courseName, createState, didUpdateWidget, _downloading, _frame, holeNumber (+8 more)

### Community 163 - "on_course_test_helpers.dart"
Cohesion: 0.11
Nodes (18): ensureVisible, enterText, expander, expandShotList, openCourseSheet, parSummaryLabel, pickCourse, pump (+10 more)

### Community 164 - "account_avatar_app_bar_menu.dart"
Cohesion: 0.12
Nodes (12): _openGolferProfile, AccountAvatarAppBarMenu, _AccountAvatarAppBarMenuState, build, createState, dispose, initState, _onLoginOrSignOut (+4 more)

### Community 165 - "oncourse_satellite_hole_map.dart"
Cohesion: 0.12
Nodes (12): HoleMapFrame, build, coords, frame, OncourseSatelliteHoleMap, player, shots, build (+4 more)

### Community 166 - "on_course_shot_segment_test.dart"
Cohesion: 0.22
Nodes (6): distanceYards, lat, lon, main, _shot, stroke

### Community 167 - "account_login_sheet.dart"
Cohesion: 0.12
Nodes (16): AccountLoginSheet, _AccountLoginSheetState, build, _busy, _createAccount, createState, dispose, _emailController (+8 more)

### Community 168 - "account_sync_settings_screen.dart"
Cohesion: 0.13
Nodes (12): AccountSyncSettingsScreen, _AccountSyncSettingsScreenState, build, createState, _dirtyCount, dispose, _formatLastSync, initState (+4 more)

### Community 169 - "build_pack.py"
Cohesion: 0.14
Nodes (17): build(), _coverage_label(), classify(), parse_elements(), corridor(), compute_markers(), Marker, collect_layers() (+9 more)

### Community 170 - "package:flutter_test/flutter_test.dart"
Cohesion: 0.14
Nodes (5): main, pumpMenu, main, main, main

### Community 171 - "account_session.dart"
Cohesion: 0.14
Nodes (13): AccountSession, displayName, email, isAnonymous, isDurableAccount, isEmailPasswordAccount, isEmailVerified, isGoogleAccount (+5 more)

### Community 172 - "course_map_cache_service_test.dart"
Cohesion: 0.08
Nodes (15): course, holes, _json, main, objects, _png, read, reads (+7 more)

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

### Community 180 - "../models/golfer_profile.dart"
Cohesion: 0.22
Nodes (7): bagCategoryLabel, forDensity, formatCarryYards, longest, shortest, usual, YardageStatLabels

### Community 181 - "mgdv_401_cart_scoring_test.dart"
Cohesion: 0.33
Nodes (3): main, restoreDatabase, useFreshDatabase

### Community 182 - "golfer_profile_test.dart"
Cohesion: 0.22
Nodes (6): available, generate, generateJson, location, main, modelName

### Community 190 - "package:flutter/foundation.dart"
Cohesion: 0.29
Nodes (5): buildInviteUrl, CaddyLaunchConfig, currentPlatformLaunch, fromUri, requestToken

### Community 191 - "sync_merge.dart"
Cohesion: 0.29
Nodes (6): decideMerge, MergeAction, readDeleted, readUpdatedAtMs, tryParse, value

### Community 192 - "../models/caddy_session.dart"
Cohesion: 0.33
Nodes (3): apply, CaddyEventApplier, _db

## Knowledge Gaps
- **1700 isolated node(s):** `teeLat`, `teeLon`, `greenLat`, `greenLon`, `_byCourse` (+1695 more)
  These have ≤1 connection - possible missing edges. (Counts symbols only; 2483 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **59 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `GolferProfile` connect `golfer_profile_store.dart` to `onboarding_gate.dart`, `swing_diary_sheet.dart`, `range_drill_screen.dart`, `clubs_screen.dart`, `onboarding_starter_wizard.dart`, `golfer_profile_settings_screen.dart`, `swing_diary_prompt.dart`, `golfer_profile_service.dart`, `golfer_baseline_sheet.dart`, `golfer_profile.dart`?**
  _High betweenness centrality (0.013) - this node is a cross-community bridge._
- **Are the 60 inferred relationships involving `b()` (e.g. with `a0()` and `aA()`) actually correct?**
  _`b()` has 60 INFERRED edges - model-reasoned connections that need verification._
- **What connects `teeLat`, `teeLon`, `greenLat` to the rest of the system?**
  _1700 weakly-connected nodes found - possible missing edges._
- **Should `sqflite_sw.js` be split into smaller, more focused modules?**
  _Cohesion score 0.0048543689320388345 - nodes in this community are weakly interconnected._
- **Why does `Win32Window` connect `Win32Window` to `Point`, `utils.cpp`, `win32_window.cpp`, `FlutterWindow`, `.MessageHandler`, `Size`?**
  _High betweenness centrality (0.012) - this node is a cross-community bridge._
- **Are the 44 inferred relationships involving `c()` (e.g. with `aA()` and `aC()`) actually correct?**
  _`c()` has 44 INFERRED edges - model-reasoned connections that need verification._
- **Should `app_theme.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.038461538461538464 - nodes in this community are weakly interconnected._