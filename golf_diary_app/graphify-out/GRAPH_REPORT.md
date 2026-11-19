# Graph Report - golf_diary_app  (2026-11-19)

## Corpus Check
- 158 files · ~86,576 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 54 file(s) not represented in the graph (top: .xml 9, .xcconfig 8, (none) 7)
- WARNING: 54 of 265 files seen (20%) have no supported extractor and are missing from this graph entirely. It may look complete while representing only part of the codebase.

## Summary
- 2905 nodes · 3869 edges · 169 communities (114 shown, 55 thin omitted)
- Extraction: 94% EXTRACTED · 6% INFERRED · 0% AMBIGUOUS · INFERRED: 228 edges (avg confidence: 0.85)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `1f586f07`
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
- caddy_session.dart
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
- shared_header_actions.dart
- StatelessWidget
- diary_model.dart
- onboarding_gate.dart
- utils.cpp
- List
- account_auth_controller.dart
- golfer_profile_test.dart
- app_check_config.dart
- main.dart
- practice_drill.dart
- golfer_profile_settings_screen.dart
- range_session_wrapup_test.dart
- flutter_launcher_icons
- manifest.json
- windows/flutter/generated_plugin_registrant.cc
- sync_cloud_button.dart
- golfer_profile_store.dart
- pubspec.yaml
- dart:async
- b9
- sync_merge.dart
- sync_identity.dart
- My Golf Diary
- scorecard_cart_panel.dart
- List
- analysis_options.yaml
- FairwayTrackerScreenState
- dev_dependencies
- package:sqflite/sqflite.dart
- copyProperties
- desktop_database.dart
- web
- pwa_service_worker.js
- ai
- eg
- installInstanceTearOff
- SwingDiarySheet
- windows
- getTag
- Point
- Size
- MainActivity.kt
- caddy_golfer_merge_host.dart
- LocalDatabaseService
- aZ
- bx
- caddy_pairing_service.dart
- convertToFastObject
- X
- _ClubSortKey
- LaunchImage.imageset/README.md
- app_build_id.dart
- account_avatar_app_bar_menu.dart
- desktop_database_stub.dart
- build_web.sh
- recaptcha_assessment.sh
- an
- aR
- bF
- bP
- ../models/golfer_profile.dart
- account_login_sheet.dart
- d6
- es
- getUnknownTag
- mixinEasy
- mixinHard
- prototypeForTag
- shared_header_actions_test.dart
- caddy_round_channel_store.dart
- account_sync_settings_screen.dart
- caddy_pairing_gate.dart
- caddy_on_course_screen.dart
- diary_context_note.dart
- account_session.dart
- caddy_invite_sheet.dart
- caddy_shell.dart
- account_profile_screen.dart
- @visibleForTesting
- vertex_diary_model.dart
- static const
- VoidCallback
- ../services/local_database_service.dart
- pwa_update_client.dart
- ../models/golf_models.dart
- mgdv_501_caddy_pairing_test.dart
- pwa_update_client_web.dart
- caddy_connected_banner.dart
- account_avatar_menu_test.dart
- caddy_invite_app_bar_button.dart
- practice_drill_metadata.dart
- ../models/caddy_session.dart
- pwa_update_client_stub.dart
- pwa_published_build.dart
- DiaryModel
- _NewRoundDialog
- ScorecardScreenState

## God Nodes (most connected - your core abstractions)
1. `b()` - 70 edges
2. `c()` - 45 edges
3. `p()` - 28 edges
4. `d()` - 23 edges
5. `o()` - 22 edges
6. `Win32Window` - 21 edges
7. `j()` - 20 edges
8. `dependencies` - 19 edges
9. `i()` - 14 edges
10. `DiaryModel` - 13 edges

## Surprising Connections (you probably didn't know these)
- `wWinMain()` --calls--> `CreateAndAttachConsole()`  [INFERRED]
  golf_diary_app/windows/runner/main.cpp → golf_diary_app/windows/runner/utils.cpp
- `FakeDiaryModel` --implements--> `DiaryModel`  [EXTRACTED]
  golf_diary_app/test/swing_diary_test.dart → golf_diary_app/lib/services/diary_model.dart
- `FlutterWindow` --inherits--> `Win32Window`  [EXTRACTED]
  golf_diary_app/windows/runner/flutter_window.h → golf_diary_app/windows/runner/win32_window.h
- `my_application_activate()` --calls--> `fl_register_plugins()`  [INFERRED]
  golf_diary_app/linux/my_application.cc → golf_diary_app/linux/flutter/generated_plugin_registrant.cc
- `main()` --calls--> `my_application_new()`  [INFERRED]
  golf_diary_app/linux/main.cc → golf_diary_app/linux/my_application.cc

## Import Cycles
- None detected.

## Communities (169 total, 55 thin omitted)

### Community 1 - "local_database_service.dart"
Cohesion: 0.02
Nodes (100): applyCoursePar, applyRemoteRow, _backfillGolfRounds, _columns, compileRangeSession, completeRound, computeRoundTotals, concedeHole (+92 more)

### Community 2 - "swing_diary_prompt.dart"
Cohesion: 0.03
Nodes (77): brief, buffer, buildDiarySystemInstruction, clubName, clubs, ClubTally, compiledIds, _compose (+69 more)

### Community 3 - "p"
Cohesion: 0.05
Nodes (65): $0(), $1(), a1(), a3(), a4(), a5(), aH(), aU() (+57 more)

### Community 4 - "golf_models.dart"
Cohesion: 0.03
Nodes (61): avgDistance, avgYards, brand, category, clubId, clubName, compareClubs, compareTo (+53 more)

### Community 5 - "fairway_tracker_screen.dart"
Cohesion: 0.02
Nodes (78): _activeCoords, _appliedCourseName, _beginPinWatch, _bootstrap, build, _busy, _carryController, _clampMapPane (+70 more)

### Community 6 - "golfer_profile.dart"
Cohesion: 0.03
Nodes (62): age, amateur, any, bagNickname, baselineLabel, beginner, blurb, clubsMissingEquipmentSpecs (+54 more)

### Community 7 - "app_theme.dart"
Cohesion: 0.04
Nodes (46): amber, AppColors, birdieGold, birdieGoldDark, buildGolfTheme, _buildTextTheme, cream, creamElevated (+38 more)

### Community 8 - "swing_diary_sheet.dart"
Cohesion: 0.04
Nodes (45): _appCheck, _applyLeadIn, _baselineSummary, _baselineUpdated, build, _busy, _cancel, _chunks (+37 more)

### Community 9 - "GeneratedPluginRegistrant.swift"
Cohesion: 0.05
Nodes (22): cloud_firestore, Cocoa, firebase_ai, firebase_app_check, firebase_auth, firebase_core, Flutter, FlutterMacOS (+14 more)

### Community 10 - "clubs_screen.dart"
Cohesion: 0.04
Nodes (49): YardageUiDensity, _addClub, _brand, build, categories, _category, club, _clubs (+41 more)

### Community 11 - "pwa_update_host.dart"
Cohesion: 0.07
Nodes (22): _applying, build, _check, _checking, child, client, createState, dialogKey (+14 more)

### Community 12 - "range_drill_screen.dart"
Cohesion: 0.04
Nodes (41): Club, _allClubs, _applyClubStrip, _applyLeadIn, _avgController, build, _buildYardageInputs, _clubs (+33 more)

### Community 13 - "scorecard_screen.dart"
Cohesion: 0.04
Nodes (47): build, _cartGimme, _cartHighContrast, _cartMulligan, _cartMutation, _cartPenalty, _cartPlusStroke, _cartSelectedHole (+39 more)

### Community 14 - "scorecard_hole_editor.dart"
Cohesion: 0.06
Nodes (31): RoundScore, _adjustPenalties, _adjustStrokes, build, _conceded, courseName, createState, decKey (+23 more)

### Community 15 - "swing_diary_service.dart"
Cohesion: 0.06
Nodes (31): appendContextNote, ask, content, _database, day, _db, DiaryExchange, DiaryMessage (+23 more)

### Community 16 - "pwa_update_test.dart"
Cohesion: 0.14
Nodes (9): applyCount, applyUpdate, fetchPublishedBuild, main, published, pump, pumpAndSettle, _pumpHost (+1 more)

### Community 17 - "onboarding_starter_wizard.dart"
Cohesion: 0.07
Nodes (28): _ageController, _ageError, build, controller, createState, dispose, _draftProfile, errorText (+20 more)

### Community 18 - "my_application.cc"
Cohesion: 0.09
Nodes (13): fl_register_plugins(), main(), my_application_activate(), my_application_class_init(), my_application_dispose(), my_application_init(), my_application_local_command_line(), my_application_new() (+5 more)

### Community 19 - "ph_golf_hole_coords.dart"
Cohesion: 0.05
Nodes (34): _byCourse, canonicalCourseName, direct, greenLat, greenLon, hallow, hasHoleCoordinates, HoleCoordinates (+26 more)

### Community 20 - "b"
Cohesion: 0.04
Nodes (82): A(), a0(), aA(), aC(), aD(), aE(), aG(), aK() (+74 more)

### Community 21 - "practice_drill_sheet.dart"
Cohesion: 0.08
Nodes (25): _add, build, _category, copyTitleToNote, createState, _delete, _description, dispose (+17 more)

### Community 22 - "State"
Cohesion: 0.12
Nodes (22): CaddyOnCourseScreen, _CaddyOnCourseScreenState, CaddyPairingGate, _CaddyPairingGateState, CaddyScorecardScreen, _CaddyScorecardScreenState, _AddClubDialog, _AddClubDialogState (+14 more)

### Community 23 - "caddy_session.dart"
Cohesion: 0.05
Nodes (34): authorUid, caddy, CaddyEventType, CaddyRoundEvent, CaddySessionRole, CaddySessionStatus, caddyUid, channelId (+26 more)

### Community 24 - "cloud_sync_service.dart"
Cohesion: 0.09
Nodes (16): alreadyRunning, CloudSyncService, _db, failed, initializeFirebase, isAvailable, pullAll, pulled (+8 more)

### Community 25 - "swing_diary_test.dart"
Cohesion: 0.08
Nodes (20): available, calls, db, error, generate, generateJson, hold, jsonReply (+12 more)

### Community 26 - "golfer_profile_service.dart"
Cohesion: 0.08
Nodes (22): changed, collectUndistilledNotes, _database, decoded, distillIfNeeded, DistillResult, GolferProfileService, isEmpty (+14 more)

### Community 27 - "venue_name_field.dart"
Cohesion: 0.09
Nodes (19): autofocus, build, catalogNames, controller, createState, didUpdateWidget, dispose, focusNode (+11 more)

### Community 28 - "round_summary.dart"
Cohesion: 0.10
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
Nodes (18): build, _busy, createState, diary, dispose, _distill, _edited, _equipment (+10 more)

### Community 34 - "ph_golf_catalog.dart"
Cohesion: 0.11
Nodes (17): courseCaption, courseNames, courses, hasCard, holeCount, holePars, holes, matchCourse (+9 more)

### Community 35 - "FlutterWindow"
Cohesion: 0.12
Nodes (4): FlutterWindow, flutter_controller_, FlutterWindow::FlutterWindow(), project_

### Community 36 - "range_session_log.dart"
Cohesion: 0.11
Nodes (16): RangeDrillSummary, build, compiled, CompiledRangeSessionCard, date, emptyMessage, entry, formatRangeSessionWhen (+8 more)

### Community 37 - "package:flutter_test/flutter_test.dart"
Cohesion: 0.08
Nodes (14): db, main, club, main, openDialog, main, db, main (+6 more)

### Community 38 - "package:flutter/material.dart"
Cohesion: 0.15
Nodes (6): SaveRoundBeforeNewChoice, showSaveRoundBeforeNewDialog, main, finishAction, main, pumpCourse

### Community 39 - "home_shell.dart"
Cohesion: 0.11
Nodes (12): _bagKey, build, _courseKey, createState, HomeShell, _HomeShellState, _index, _onProfileSettingsChanged (+4 more)

### Community 40 - "dependencies"
Cohesion: 0.10
Nodes (20): dependencies, cloud_firestore, cupertino_icons, firebase_ai, firebase_app_check, firebase_auth, firebase_core, flutter (+12 more)

### Community 41 - "pin_distance.dart"
Cohesion: 0.07
Nodes (24): catalogTeeToGreenYards, current, fromLat, fromLon, GeolocatorPinDistanceClient, hole, latitude, locationSettings (+16 more)

### Community 42 - "diary_remote.dart"
Cohesion: 0.15
Nodes (10): _collection, DiaryRemote, docs, failOnSet, _firestore, FirestoreDiaryRemote, _key, listDocuments (+2 more)

### Community 43 - "shared_header_actions.dart"
Cohesion: 0.06
Nodes (24): SwingDiaryService, build, diary, DiaryEntryButton, diaryStore, entryKey, entrySource, model (+16 more)

### Community 44 - "StatelessWidget"
Cohesion: 0.12
Nodes (15): _ClubBagCard, _StatChip, _YardageTrend, _AgeStep, _GenderStep, _SkillTierStep, _YearsStep, _CounterRow (+7 more)

### Community 45 - "diary_model.dart"
Cohesion: 0.14
Nodes (12): available, bindAbort, cancel, _cancelled, DiaryCancel, DiaryCancelled, generate, generateJson (+4 more)

### Community 46 - "onboarding_gate.dart"
Cohesion: 0.13
Nodes (12): build, _caddyRequestToken, createState, _enterShell, initState, _loading, OnboardingGate, _OnboardingGateState (+4 more)

### Community 47 - "utils.cpp"
Cohesion: 0.19
Nodes (4): wWinMain(), CreateAndAttachConsole(), GetCommandLineArguments(), Utf8FromUtf16()

### Community 48 - "List"
Cohesion: 0.20
Nodes (9): category, id, kPracticeDrillSeed, practiceArea, PracticeDrillSeed, recommendedClubs, shortDescription, steps (+1 more)

### Community 49 - "account_auth_controller.dart"
Cohesion: 0.07
Nodes (22): _auth, _authOverride, _ConflictMarker, disposeController, _fromUser, _googleOverride, _googleSignIn, instance (+14 more)

### Community 50 - "golfer_profile_test.dart"
Cohesion: 0.11
Nodes (10): main, available, generate, generateJson, location, main, modelName, main (+2 more)

### Community 51 - "app_check_config.dart"
Cohesion: 0.12
Nodes (11): activateWebAppCheck, appCheckDebugState, kRecaptchaSiteKey, shouldActivateAppCheck, DefaultFirebaseOptions, web, buildInviteUrl, CaddyLaunchConfig (+3 more)

### Community 53 - "main.dart"
Cohesion: 0.18
Nodes (6): build, GolfDiaryApp, initDesktopDatabase, initializeFirebase, main, preparePwaSession

### Community 54 - "practice_drill.dart"
Cohesion: 0.18
Nodes (10): category, fromMap, id, isCustom, PracticeDrill, recommendedClubs, shortDescription, steps (+2 more)

### Community 55 - "golfer_profile_settings_screen.dart"
Cohesion: 0.07
Nodes (25): _ageController, _ageError, _base, build, _busy, createState, diary, dispose (+17 more)

### Community 56 - "range_session_wrapup_test.dart"
Cohesion: 0.10
Nodes (13): db, main, restoreDatabase, useFreshDatabase, db, main, restoreDatabase, useFreshDatabase (+5 more)

### Community 57 - "flutter_launcher_icons"
Cohesion: 0.18
Nodes (11): flutter_launcher_icons, adaptive_icon_background, adaptive_icon_foreground, android, image_path, ios, macos, min_sdk_android (+3 more)

### Community 58 - "manifest.json"
Cohesion: 0.18
Nodes (10): background_color, description, display, icons, name, orientation, prefer_related_applications, short_name (+2 more)

### Community 60 - "sync_cloud_button.dart"
Cohesion: 0.12
Nodes (12): failure, messenger, result, runDiarySync, uid, build, failure, messenger (+4 more)

### Community 61 - "golfer_profile_store.dart"
Cohesion: 0.13
Nodes (11): GolferProfile, AccountAuthController, GolferProfileScope, GolferProfileStore, load, maybeOf, of, persist (+3 more)

### Community 62 - "pubspec.yaml"
Cohesion: 0.20
Nodes (9): description, environment, sdk, flutter, assets, uses-material-design, name, publish_to (+1 more)

### Community 63 - "dart:async"
Cohesion: 0.15
Nodes (6): initDesktopDatabase, useGoogleFonts, useGoogleFonts, setDatabasesPath, testExecutable, testMain

### Community 64 - "b9"
Cohesion: 0.22
Nodes (9): aP(), b9(), bL(), cF(), cV(), cX(), dh(), gbZ() (+1 more)

### Community 65 - "sync_merge.dart"
Cohesion: 0.17
Nodes (9): published, shouldOfferPwaUpdate, true, decideMerge, MergeAction, readDeleted, readUpdatedAtMs, tryParse (+1 more)

### Community 66 - "sync_identity.dart"
Cohesion: 0.25
Nodes (4): canSync, currentUserId, ensureSignedIn, SyncIdentity

### Community 67 - "My Golf Diary"
Cohesion: 0.25
Nodes (7): Browser / PWA storage, My Bag, My Golf Diary, On Course, Range, Run it, Scorecard

### Community 68 - "scorecard_cart_panel.dart"
Cohesion: 0.09
Nodes (18): _actionMinSize, build, _Cell, courseName, fg, highContrast, holeCount, label (+10 more)

### Community 70 - "analysis_options.yaml"
Cohesion: 0.33
Nodes (5): analyzer, exclude, include, linter, rules

### Community 72 - "dev_dependencies"
Cohesion: 0.33
Nodes (6): dev_dependencies, flutter_launcher_icons, flutter_lints, flutter_test, sqlite3, sdk

### Community 73 - "package:sqflite/sqflite.dart"
Cohesion: 0.10
Nodes (12): initDesktopDatabase, main, restoreDatabase, useFreshDatabase, yardageLabel, main, restoreDatabase, useFreshDatabase (+4 more)

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

### Community 87 - "caddy_golfer_merge_host.dart"
Cohesion: 0.10
Nodes (14): applier, _attach, _bootstrap, build, child, createState, _db, dispose (+6 more)

### Community 89 - "LocalDatabaseService"
Cohesion: 0.67
Nodes (3): RangeSessionBlock, LocalDatabaseService, _snapshotBlocks

### Community 90 - "aZ"
Cohesion: 0.67
Nodes (3): aq(), aZ(), dg()

### Community 91 - "bx"
Cohesion: 0.67
Nodes (3): bx(), c8(), c9()

### Community 92 - "caddy_pairing_service.dart"
Cohesion: 0.11
Nodes (15): _channelStore, _db, _defaultStore, expiresAt, flushOfflineQueue, getCaddyActiveSession, getGolferActiveSession, mintInvite (+7 more)

### Community 94 - "X"
Cohesion: 0.67
Nodes (3): gcn(), X(), z()

### Community 99 - "account_avatar_app_bar_menu.dart"
Cohesion: 0.12
Nodes (12): _openGolferProfile, AccountAvatarAppBarMenu, _AccountAvatarAppBarMenuState, build, createState, dispose, initState, _onLoginOrSignOut (+4 more)

### Community 107 - "../models/golfer_profile.dart"
Cohesion: 0.11
Nodes (15): HeaderActionPolicy, HeaderTabContext, resolve, showCaddyInOverflow, showCaddyPinned, showDiaryInOverflow, showDiaryPinned, usePlayOverflow (+7 more)

### Community 108 - "account_login_sheet.dart"
Cohesion: 0.12
Nodes (16): AccountLoginSheet, _AccountLoginSheetState, build, _busy, _createAccount, createState, dispose, _emailController (+8 more)

### Community 137 - "shared_header_actions_test.dart"
Cohesion: 0.12
Nodes (8): amateur, beginner, main, pro, main, pumpHeader, drill, main

### Community 138 - "caddy_round_channel_store.dart"
Cohesion: 0.14
Nodes (14): appendEvent, CaddyRoundChannelStore, channels, createChannel, events, _firestore, FirestoreCaddyRoundChannelStore, flushPendingEvents (+6 more)

### Community 139 - "account_sync_settings_screen.dart"
Cohesion: 0.13
Nodes (12): AccountSyncSettingsScreen, _AccountSyncSettingsScreenState, build, createState, _dirtyCount, dispose, _formatLastSync, initState (+4 more)

### Community 140 - "caddy_pairing_gate.dart"
Cohesion: 0.14
Nodes (10): build, buildCaddyLaunchRoot, config, createState, _error, initState, _loading, pairing (+2 more)

### Community 141 - "caddy_on_course_screen.dart"
Cohesion: 0.14
Nodes (12): build, _busy, createState, _hole, initState, _loadHole, pairing, _par (+4 more)

### Community 142 - "diary_context_note.dart"
Cohesion: 0.15
Nodes (12): content, contextDate, DiaryContextNote, DiaryContextSource, DiaryContextSourceLabels, fromStorage, id, promptLabel (+4 more)

### Community 143 - "account_session.dart"
Cohesion: 0.14
Nodes (13): AccountSession, displayName, email, isAnonymous, isDurableAccount, isEmailPasswordAccount, isEmailVerified, isGoogleAccount (+5 more)

### Community 144 - "caddy_invite_sheet.dart"
Cohesion: 0.14
Nodes (12): build, courseName, createState, _error, initState, _loading, _mintOrLoad, pairing (+4 more)

### Community 145 - "caddy_shell.dart"
Cohesion: 0.20
Nodes (8): CaddySessionRecord, build, CaddyShell, _CaddyShellState, createState, _index, pairing, session

### Community 146 - "account_profile_screen.dart"
Cohesion: 0.20
Nodes (8): AccountProfileScreen, _AccountProfileScreenState, build, createState, dispose, initState, _rebuild, _signOut

### Community 147 - "@visibleForTesting"
Cohesion: 0.20
Nodes (9): ClubBagDetailsSheet, ClubEditResult, ClubRangeLogSheet, EditClubDialog, _EditClubDialogState, debugSetInstance, debugSetSession, debugClose (+1 more)

### Community 148 - "vertex_diary_model.dart"
Cohesion: 0.20
Nodes (7): available, defaultLocation, generate, generateJson, location, modelId, modelName

### Community 149 - "static const"
Cohesion: 0.20
Nodes (6): cart, classic, defaultMode, label, ScorecardViewMode, values

### Community 150 - "VoidCallback"
Cohesion: 0.22
Nodes (4): build, GolferProfileAppBarMenu, onProfileChanged, _open

### Community 151 - "../services/local_database_service.dart"
Cohesion: 0.22
Nodes (6): build, createState, _holes, initState, _reload, session

### Community 152 - "pwa_update_client.dart"
Cohesion: 0.25
Nodes (6): applyUpdate, fetchPublishedBuild, PlatformPwaUpdateClient, preparePwaSession, PwaUpdateClient, _FakePwaUpdateClient

### Community 153 - "../models/golf_models.dart"
Cohesion: 0.22
Nodes (6): clubsForRangeStrip, defaultClubForRangeStrip, list, rangeDrillApproachMode, rangeDrillFocusLabel, rangeDrillShowsPutter

### Community 154 - "mgdv_501_caddy_pairing_test.dart"
Cohesion: 0.22
Nodes (3): main, restoreDatabase, useFreshDatabase

### Community 155 - "pwa_update_client_web.dart"
Cohesion: 0.32
Nodes (4): _applyPwaUpdate, _disableServiceWorker, _fetchPublishedBuild, preparePwaSession

### Community 156 - "caddy_connected_banner.dart"
Cohesion: 0.25
Nodes (6): CaddyPairingService, build, CaddyConnectedBanner, onRevoked, pairing, session

### Community 157 - "account_avatar_menu_test.dart"
Cohesion: 0.25
Nodes (3): main, pumpMenu, main

### Community 158 - "caddy_invite_app_bar_button.dart"
Cohesion: 0.29
Nodes (5): build, CaddyInviteIconButton, courseName, roundId, valueKey

### Community 159 - "practice_drill_metadata.dart"
Cohesion: 0.33
Nodes (4): isBeginnerFriendlyDrill, kBeginnerFriendlyDrillIds, practiceAreaForDrill, practiceAreaLabel

### Community 160 - "../models/caddy_session.dart"
Cohesion: 0.33
Nodes (3): apply, CaddyEventApplier, _db

### Community 161 - "pwa_update_client_stub.dart"
Cohesion: 0.40
Nodes (3): applyPwaUpdate, fetchPublishedBuild, preparePwaSession

### Community 162 - "pwa_published_build.dart"
Cohesion: 0.50
Nodes (3): buildId, PwaPublishedBuild, version

### Community 163 - "DiaryModel"
Cohesion: 0.50
Nodes (4): DiaryModel, VertexDiaryModel, _SilentModel, FakeDiaryModel

## Knowledge Gaps
- **1482 isolated node(s):** `kBeginnerFriendlyDrillIds`, `isBeginnerFriendlyDrill`, `practiceAreaForDrill`, `practiceAreaLabel`, `PracticeDrillSeed` (+1477 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 2194 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **55 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `GolferProfile` connect `golfer_profile_store.dart` to `golfer_baseline_sheet.dart`, `swing_diary_prompt.dart`, `fairway_tracker_screen.dart`, `golfer_profile.dart`, `swing_diary_sheet.dart`, `clubs_screen.dart`, `range_drill_screen.dart`, `onboarding_gate.dart`, `onboarding_starter_wizard.dart`, `golfer_profile_settings_screen.dart`, `golfer_profile_service.dart`?**
  _High betweenness centrality (0.017) - this node is a cross-community bridge._
- **Are the 60 inferred relationships involving `b()` (e.g. with `a0()` and `aA()`) actually correct?**
  _`b()` has 60 INFERRED edges - model-reasoned connections that need verification._
- **What connects `kBeginnerFriendlyDrillIds`, `isBeginnerFriendlyDrill`, `practiceAreaForDrill` to the rest of the system?**
  _1482 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `sqflite_sw.js` be split into smaller, more focused modules?**
  _Cohesion score 0.0048543689320388345 - nodes in this community are weakly interconnected._
- **Why does `DiaryModel` connect `DiaryModel` to `golfer_baseline_sheet.dart`, `fairway_tracker_screen.dart`, `swing_diary_sheet.dart`, `shared_header_actions.dart`, `range_drill_screen.dart`, `scorecard_screen.dart`, `diary_model.dart`, `golfer_profile_settings_screen.dart`, `golfer_profile_service.dart`?**
  _High betweenness centrality (0.012) - this node is a cross-community bridge._
- **Are the 44 inferred relationships involving `c()` (e.g. with `aA()` and `aC()`) actually correct?**
  _`c()` has 44 INFERRED edges - model-reasoned connections that need verification._
- **Should `local_database_service.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.01904761904761905 - nodes in this community are weakly interconnected._