# Graph Report - My-Golf-Diary  (2026-11-20)

## Corpus Check
- 200 files · ~199,189 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 59 file(s) not represented in the graph (top: (none) 9, .xml 9, .xcconfig 8)

## Summary
- 3668 nodes · 5054 edges · 200 communities (137 shown, 63 thin omitted)
- Extraction: 95% EXTRACTED · 5% INFERRED · 0% AMBIGUOUS · INFERRED: 265 edges (avg confidence: 0.86)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `67a36ebd`
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
- sync_account_shards_test.dart
- caddy_golfer_merge_host.dart
- package:golf_diary_app/services/local_database_service.dart
- manifest.json
- Win32Window
- diary_context_note.dart
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
- package:flutter_test/flutter_test.dart
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
- fwy_hole_map.dart
- json
- pwa_update_test.dart
- on_course_crse_036_test.dart
- on_course_header_test.dart
- app_check_config.dart
- hole_map_geo.dart
- scorecard_cart_panel.dart
- flutter_launcher_icons
- pwa_update_client_web.dart
- vertex_diary_model.dart
- practice_drill_seed.dart
- sync_cloud_button.dart
- pubspec.yaml
- ../models/golfer_profile.dart
- ../models/golf_models.dart
- on_course_crse_036_test.dart
- static const
- sync_identity.dart
- practice_drill_metadata.dart
- dev_dependencies
- caddy_on_course_screen.dart
- fwy_aim.dart
- web
- pwa_service_worker.js
- cloud-agent-install.sh
- fwy_overlays.dart
- hole_projection.dart
- caddy_round_channel_store.dart
- windows
- caddy_invite_sheet.dart
- golfer_avatar.dart
- _ClubSortKey
- State
- app_build_id.dart
- steps
- build_web.sh
- recaptcha_assessment.sh
- caddy_scorecard_screen.dart
- courses.py
- hole_map_pack_source.dart
- package:sqflite/sqflite.dart
- HoleFrame
- coverage.py
- hole_map_marker_painter.dart
- range_shot_total_test.dart
- DiaryModel
- @visibleForTesting
- course_map_cache_service.dart
- hole_frame.py
- oncourse_map_pane.dart
- on_course_test_helpers.dart
- account_avatar_app_bar_menu.dart
- oncourse_satellite_hole_map.dart
- on_course_settings.dart
- account_login_sheet.dart
- account_sync_settings_screen.dart
- build_pack.py
- golfer_avatar_test.dart
- bool get
- course_map_cache_service_test.dart
- account_profile_screen.dart
- on_course_shot_segment.dart
- ../data/ph_golf_hole_coords.dart
- Hole
- caddy_invite_app_bar_button.dart
- account_session.dart
- course_map_pack_local.dart
- dart:async
- OnboardingStarterWizard
- ../models/caddy_session.dart
- golfer_avatar_circle.dart
- flutter
- .MessageHandler
- LocalDatabaseService
- _NewRoundDialog
- pwa_update_client.dart
- Size
- pwa_update_client_stub.dart
- pwa_published_build.dart
- CourseMapPackSource

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

## Communities (200 total, 63 thin omitted)

### Community 1 - "app_theme.dart"
Cohesion: 0.03
Nodes (54): amber, AppColors, birdieGold, birdieGoldDark, buildGolfTheme, _buildTextTheme, cream, creamElevated (+46 more)

### Community 2 - "dependencies"
Cohesion: 0.10
Nodes (20): dependencies, cloud_firestore, cupertino_icons, firebase_ai, firebase_app_check, firebase_auth, firebase_core, firebase_storage (+12 more)

### Community 3 - "golf_models.dart"
Cohesion: 0.03
Nodes (63): aimDirection, avgDistance, avgYards, brand, category, clubId, clubName, compareClubs (+55 more)

### Community 4 - "local_database_service.dart"
Cohesion: 0.02
Nodes (102): _addColumnIfMissing, applyCoursePar, applyRemoteRow, _backfillGolfRounds, _columns, compileRangeSession, completeRound, computeRoundTotals (+94 more)

### Community 5 - "GeneratedPluginRegistrant.swift"
Cohesion: 0.05
Nodes (23): cloud_firestore, Cocoa, firebase_ai, firebase_app_check, firebase_auth, firebase_core, firebase_storage, Flutter (+15 more)

### Community 6 - "scorecard_screen.dart"
Cohesion: 0.04
Nodes (47): build, _cartGimme, _cartHighContrast, _cartMulligan, _cartMutation, _cartPenalty, _cartPlusStroke, _cartSelectedHole (+39 more)

### Community 7 - "fairway_tracker_screen.dart"
Cohesion: 0.01
Nodes (143): _activeCoords, _aim, _aimMode, _aimTarget, _appliedCourseName, _bannerButton, _beginPinWatch, _bootstrap (+135 more)

### Community 8 - "scorecard_hole_editor.dart"
Cohesion: 0.06
Nodes (32): RoundScore, _adjustPenalties, _adjustStrokes, build, _conceded, _CounterRow, courseName, createState (+24 more)

### Community 9 - "range_drill_screen.dart"
Cohesion: 0.04
Nodes (45): Club, _allClubs, _applyClubStrip, _applyLeadIn, _avgController, build, _buildYardageInputs, _clubs (+37 more)

### Community 10 - "course_map_manifest.dart"
Cohesion: 0.05
Nodes (37): attribution, bearingDeg, centerLat, centerLon, courseId, CourseMapManifest, coverage, entry (+29 more)

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
Nodes (50): YardageUiDensity, _addClub, _brand, build, categories, _category, club, clubId (+42 more)

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

### Community 23 - "sync_account_shards_test.dart"
Cohesion: 0.13
Nodes (6): main, db, main, main, _pumpSettings, pumpWidget

### Community 24 - "caddy_golfer_merge_host.dart"
Cohesion: 0.10
Nodes (16): applier, _attach, _bootstrap, build, CaddyGolferMergeHost, _CaddyGolferMergeHostState, child, createState (+8 more)

### Community 25 - "package:golf_diary_app/services/local_database_service.dart"
Cohesion: 0.07
Nodes (23): SaveRoundBeforeNewChoice, showSaveRoundBeforeNewDialog, main, restoreDatabase, useFreshDatabase, yardageLabel, db, main (+15 more)

### Community 26 - "manifest.json"
Cohesion: 0.18
Nodes (10): background_color, description, display, icons, name, orientation, prefer_related_applications, short_name (+2 more)

### Community 27 - "Win32Window"
Cohesion: 0.24
Nodes (4): Win32Window, child_content_, quit_on_close_, window_handle_

### Community 28 - "diary_context_note.dart"
Cohesion: 0.17
Nodes (10): content, contextDate, DiaryContextNote, fromStorage, id, promptLabel, roundId, source (+2 more)

### Community 29 - "golfer_profile.dart"
Cohesion: 0.03
Nodes (63): age, amateur, any, avatarChoice, bagNickname, baselineLabel, beginner, blurb (+55 more)

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
Cohesion: 0.06
Nodes (30): _ageController, _ageError, build, controller, createState, dispose, _draftProfile, errorText (+22 more)

### Community 82 - "golfer_profile_settings_screen.dart"
Cohesion: 0.06
Nodes (32): _ageController, _ageError, avatar, _avatarChoice, _base, build, _busy, createState (+24 more)

### Community 83 - "ph_golf_hole_coords.dart"
Cohesion: 0.06
Nodes (28): _byCourse, canonicalCourseName, direct, greenLat, greenLon, hallow, hasHoleCoordinates, lower (+20 more)

### Community 84 - "pwa_update_host.dart"
Cohesion: 0.07
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
Cohesion: 0.10
Nodes (18): build, _busy, createState, diary, dispose, _distill, _edited, _equipment (+10 more)

### Community 93 - "package:flutter_test/flutter_test.dart"
Cohesion: 0.07
Nodes (17): main, db, main, saveBlock, distanceYards, lat, lon, main (+9 more)

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
Cohesion: 0.05
Nodes (33): DiaryContextSource, DiaryContextSourceLabels, SwingDiaryService, build, diary, DiaryEntryButton, diaryStore, entryKey (+25 more)

### Community 103 - "onboarding_gate.dart"
Cohesion: 0.13
Nodes (12): build, _caddyRequestToken, createState, _enterShell, initState, _loading, OnboardingGate, _OnboardingGateState (+4 more)

### Community 104 - "StatelessWidget"
Cohesion: 0.10
Nodes (19): _ClubBagCard, _StatTile, _TrendTile, _AvatarOption, _AvatarPicker, _AgeStep, _YearsStep, _HoleTile (+11 more)

### Community 105 - "diary_model.dart"
Cohesion: 0.14
Nodes (12): available, bindAbort, cancel, _cancelled, DiaryCancel, DiaryCancelled, generate, generateJson (+4 more)

### Community 106 - "fwy_hole_map.dart"
Cohesion: 0.05
Nodes (34): aimRingFaint, aimRingMeters, aimTarget, ball, build, clearInsets, _dashed, drawHole (+26 more)

### Community 107 - "json"
Cohesion: 0.23
Nodes (6): write_index(), _client(), main(), _merged_index(), _put(), validate()

### Community 108 - "pwa_update_test.dart"
Cohesion: 0.14
Nodes (9): applyCount, applyUpdate, fetchPublishedBuild, main, published, pump, pumpAndSettle, _pumpHost (+1 more)

### Community 109 - "on_course_crse_036_test.dart"
Cohesion: 0.11
Nodes (10): ClubEditResult, club, main, openDialog, fold, key, kNavBarHeight, main (+2 more)

### Community 110 - "on_course_header_test.dart"
Cohesion: 0.06
Nodes (24): available, generate, generateJson, location, main, modelName, amateur, beginner (+16 more)

### Community 111 - "app_check_config.dart"
Cohesion: 0.12
Nodes (11): activateWebAppCheck, appCheckDebugState, kRecaptchaSiteKey, shouldActivateAppCheck, DefaultFirebaseOptions, web, buildInviteUrl, CaddyLaunchConfig (+3 more)

### Community 112 - "hole_map_geo.dart"
Cohesion: 0.07
Nodes (26): boundsForHole, fromManifest, latPad, lats, latSpan, lonPad, lons, lonSpan (+18 more)

### Community 113 - "scorecard_cart_panel.dart"
Cohesion: 0.09
Nodes (20): _actionMinSize, build, _CartTotalsBar, _Cell, courseName, fg, highContrast, holeCount (+12 more)

### Community 114 - "flutter_launcher_icons"
Cohesion: 0.18
Nodes (11): flutter_launcher_icons, adaptive_icon_background, adaptive_icon_foreground, android, image_path, ios, macos, min_sdk_android (+3 more)

### Community 115 - "pwa_update_client_web.dart"
Cohesion: 0.24
Nodes (6): applyPwaUpdate, _applyPwaUpdate, _disableServiceWorker, fetchPublishedBuild, _fetchPublishedBuild, preparePwaSession

### Community 116 - "vertex_diary_model.dart"
Cohesion: 0.17
Nodes (7): available, defaultLocation, generate, generateJson, location, modelId, modelName

### Community 117 - "practice_drill_seed.dart"
Cohesion: 0.14
Nodes (11): category, id, kPracticeDrillSeed, practiceArea, PracticeDrillSeed, recommendedClubs, shortDescription, steps (+3 more)

### Community 118 - "sync_cloud_button.dart"
Cohesion: 0.12
Nodes (12): failure, messenger, result, runDiarySync, uid, build, failure, messenger (+4 more)

### Community 119 - "pubspec.yaml"
Cohesion: 0.20
Nodes (9): description, environment, sdk, flutter, assets, uses-material-design, name, publish_to (+1 more)

### Community 120 - "../models/golfer_profile.dart"
Cohesion: 0.12
Nodes (14): HeaderActionPolicy, HeaderTabContext, resolve, showCaddyInOverflow, showCaddyPinned, showDiaryPinned, usePlayOverflow, bagCategoryLabel (+6 more)

### Community 121 - "../models/golf_models.dart"
Cohesion: 0.22
Nodes (6): clubsForRangeStrip, defaultClubForRangeStrip, list, rangeDrillApproachMode, rangeDrillFocusLabel, rangeDrillShowsPutter

### Community 122 - "on_course_crse_036_test.dart"
Cohesion: 0.06
Nodes (26): PinFix, current, fix, live, main, waitForBag, watch, main (+18 more)

### Community 123 - "static const"
Cohesion: 0.22
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

### Community 128 - "fwy_aim.dart"
Cohesion: 0.06
Nodes (29): angle, _categoryDefaultYards, centerDegrees, cross, custom, d, deriveAimDirection, dot (+21 more)

### Community 129 - "web"
Cohesion: 0.40
Nodes (5): web, background_color, generate, image_path, theme_color

### Community 131 - "cloud-agent-install.sh"
Cohesion: 0.67
Nodes (3): DEBIAN_FRONTEND, flutter_meets_version(), cloud-agent-install.sh script

### Community 132 - "fwy_overlays.dart"
Cohesion: 0.06
Nodes (33): box, build, _busy, _count, _CounterEntry, _CounterEntryState, createState, edgeX (+25 more)

### Community 133 - "hole_projection.dart"
Cohesion: 0.09
Nodes (19): bearingDeg, bearingDegrees, centerLat, centerLon, _cosLat, dEast, deg, dNorth (+11 more)

### Community 134 - "caddy_round_channel_store.dart"
Cohesion: 0.14
Nodes (14): appendEvent, CaddyRoundChannelStore, channels, createChannel, events, _firestore, FirestoreCaddyRoundChannelStore, flushPendingEvents (+6 more)

### Community 135 - "windows"
Cohesion: 0.50
Nodes (4): windows, generate, icon_size, image_path

### Community 136 - "caddy_invite_sheet.dart"
Cohesion: 0.14
Nodes (12): build, courseName, createState, _error, initState, _loading, _mintOrLoad, pairing (+4 more)

### Community 137 - "golfer_avatar.dart"
Cohesion: 0.14
Nodes (12): assetPath, defaultGolferAvatar, fromId, GolferAvatar, golferAvatarPickerOrder, GolferAvatarTier, id, label (+4 more)

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

### Community 152 - "hole_map_pack_source.dart"
Cohesion: 0.14
Nodes (11): HoleMapManifestEntry, attribution, CachedHoleMapPackSource, entry, HoleMapPack, HoleMapPackSource, imageBytes, instance (+3 more)

### Community 153 - "package:sqflite/sqflite.dart"
Cohesion: 0.07
Nodes (14): initDesktopDatabase, db, main, strokes, main, main, restoreDatabase, useFreshDatabase (+6 more)

### Community 155 - "coverage.py"
Cohesion: 0.17
Nodes (7): coverage_rows(), grade(), hole_matches(), point(), golf_features_query(), run(), main()

### Community 156 - "hole_map_marker_painter.dart"
Cohesion: 0.14
Nodes (11): HoleMapBounds, _SparklinePainter, _FwyScenePainter, bounds, colorScheme, coords, HoleMapMarkerPainter, paint (+3 more)

### Community 157 - "range_shot_total_test.dart"
Cohesion: 0.18
Nodes (9): databaseSerial, hitShotButton, main, pumpRange, releaseScreen, restoreDatabase, totalControl, useFreshDatabase (+1 more)

### Community 158 - "DiaryModel"
Cohesion: 0.40
Nodes (5): DiaryModel, VertexDiaryModel, _SilentModel, _QuietDiaryModel, FakeDiaryModel

### Community 159 - "@visibleForTesting"
Cohesion: 0.18
Nodes (10): ClubRangeLogSheet, EditClubDialog, _EditClubDialogState, SwingNotesDialog, _SwingNotesDialogState, debugSetInstance, debugSetSession, debugReset (+2 more)

### Community 160 - "course_map_cache_service.dart"
Cohesion: 0.05
Nodes (37): cachedImageBytes, canonicalCourseName, _courseId, CourseMapCacheService, courseMapPackId, courseMapPackIdFromName, CourseMapResolveKind, CourseMapResolveResult (+29 more)

### Community 161 - "hole_frame.py"
Cohesion: 0.12
Nodes (10): distance_m(), Feature, feature_geometry(), LocalFrame, along(), build_frame(), _match_hole_line(), _best() (+2 more)

### Community 162 - "oncourse_map_pane.dart"
Cohesion: 0.10
Nodes (18): build, coords, courseName, createState, didUpdateWidget, _downloading, _frame, holeNumber (+10 more)

### Community 163 - "on_course_test_helpers.dart"
Cohesion: 0.10
Nodes (20): ensureVisible, enterText, expander, expandShotList, finishHoleFromOverflow, openCourseSheet, parSummaryLabel, pickCourse (+12 more)

### Community 164 - "account_avatar_app_bar_menu.dart"
Cohesion: 0.12
Nodes (11): AccountAvatarAppBarMenu, _AccountAvatarAppBarMenuState, build, createState, dispose, initState, _onLoginOrSignOut, _openProfile (+3 more)

### Community 165 - "oncourse_satellite_hole_map.dart"
Cohesion: 0.12
Nodes (13): HoleCoordinates, HoleMapFrame, build, coords, frame, OncourseSatelliteHoleMap, player, shots (+5 more)

### Community 166 - "on_course_settings.dart"
Cohesion: 0.17
Nodes (10): _db, _get, GpsMode, instance, OnCourseSettings, RailSide, _set, setGpsMode (+2 more)

### Community 167 - "account_login_sheet.dart"
Cohesion: 0.12
Nodes (16): AccountLoginSheet, _AccountLoginSheetState, build, _busy, _createAccount, createState, dispose, _emailController (+8 more)

### Community 168 - "account_sync_settings_screen.dart"
Cohesion: 0.11
Nodes (14): AccountSyncSettingsScreen, _AccountSyncSettingsScreenState, build, createState, _dirtyCount, dispose, _formatLastSync, initState (+6 more)

### Community 169 - "build_pack.py"
Cohesion: 0.14
Nodes (17): build(), _coverage_label(), classify(), parse_elements(), corridor(), compute_markers(), Marker, collect_layers() (+9 more)

### Community 170 - "golfer_avatar_test.dart"
Cohesion: 0.14
Nodes (6): main, pumpMenu, main, _emailSession, _googleSession, main

### Community 172 - "course_map_cache_service_test.dart"
Cohesion: 0.08
Nodes (17): course, holes, _json, main, objects, _png, read, reads (+9 more)

### Community 173 - "account_profile_screen.dart"
Cohesion: 0.18
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

### Community 178 - "account_session.dart"
Cohesion: 0.15
Nodes (12): displayName, email, isAnonymous, isDurableAccount, isEmailPasswordAccount, isEmailVerified, isGoogleAccount, isSignedOut (+4 more)

### Community 179 - "course_map_pack_local.dart"
Cohesion: 0.33
Nodes (3): CourseMapPackLocal, hasPackForCourse, instance

### Community 180 - "dart:async"
Cohesion: 0.20
Nodes (5): initDesktopDatabase, useGoogleFonts, setDatabasesPath, testExecutable, testMain

### Community 182 - "../models/caddy_session.dart"
Cohesion: 0.33
Nodes (3): apply, CaddyEventApplier, _db

### Community 183 - "golfer_avatar_circle.dart"
Cohesion: 0.11
Nodes (12): AccountSession, build, GolferAvatarCircle, GolferAvatarSource, photo, profile, radius, resolveGolferAvatarSource (+4 more)

### Community 191 - "LocalDatabaseService"
Cohesion: 0.67
Nodes (3): RangeSessionBlock, LocalDatabaseService, _snapshotBlocks

### Community 196 - "pwa_update_client.dart"
Cohesion: 0.25
Nodes (6): applyUpdate, fetchPublishedBuild, PlatformPwaUpdateClient, preparePwaSession, PwaUpdateClient, _FakePwaUpdateClient

### Community 197 - "Size"
Cohesion: 0.50
Nodes (3): Size, height, width

### Community 198 - "pwa_update_client_stub.dart"
Cohesion: 0.40
Nodes (3): applyPwaUpdate, fetchPublishedBuild, preparePwaSession

### Community 199 - "pwa_published_build.dart"
Cohesion: 0.50
Nodes (3): buildId, PwaPublishedBuild, version

### Community 201 - "CourseMapPackSource"
Cohesion: 0.67
Nodes (3): CourseMapPackSource, FirebaseCourseMapPackSource, _FakeSource

## Knowledge Gaps
- **1953 isolated node(s):** `diary`, `onProfileSettingsChanged`, `kRangeShotTotals`, `index`, `_allClubs` (+1948 more)
  These have ≤1 connection - possible missing edges. (Counts symbols only; 2754 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **63 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Win32Window` connect `Win32Window` to `Size`, `Point`, `utils.cpp`, `win32_window.cpp`, `FlutterWindow`, `.MessageHandler`?**
  _High betweenness centrality (0.017) - this node is a cross-community bridge._
- **Are the 60 inferred relationships involving `b()` (e.g. with `a0()` and `aA()`) actually correct?**
  _`b()` has 60 INFERRED edges - model-reasoned connections that need verification._
- **What connects `diary`, `onProfileSettingsChanged`, `kRangeShotTotals` to the rest of the system?**
  _1953 weakly-connected nodes found - possible missing edges._
- **Should `sqflite_sw.js` be split into smaller, more focused modules?**
  _Cohesion score 0.0048543689320388345 - nodes in this community are weakly interconnected._
- **Why does `Point` connect `Point` to `win32_window.cpp`, `Win32Window`?**
  _High betweenness centrality (0.008) - this node is a cross-community bridge._
- **Are the 44 inferred relationships involving `c()` (e.g. with `aA()` and `aC()`) actually correct?**
  _`c()` has 44 INFERRED edges - model-reasoned connections that need verification._
- **Should `app_theme.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.03389830508474576 - nodes in this community are weakly interconnected._