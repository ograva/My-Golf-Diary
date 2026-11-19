# Graph Report - golf_diary_app  (2026-11-19)

## Corpus Check
- 169 files · ~89,700 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 54 file(s) not represented in the graph (top: .xml 9, .xcconfig 8, (none) 7)

## Summary
- 825 nodes · 667 edges · 258 communities (17 shown, 241 thin omitted)
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `5103599f`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- hole_map_marker_painter.dart
- local_database_service.dart
- golf_models.dart
- fairway_tracker_screen.dart
- GeneratedPluginRegistrant.swift
- course_map_pack_local.dart
- FairwayTrackerScreenState
- dependencies
- on_course_crse_033_test.dart
- OncourseSatelliteHoleMap
- course_map_cache_service.dart
- flutter_launcher_icons
- windows/flutter/generated_plugin_registrant.cc
- course_map_manifest.dart
- oncourse_vector_hole_map.dart
- oncourse_satellite_hole_map.dart
- LocalDatabaseService
- hole_map_geo.dart
- _ClubSortKey
- oncourse_map_pane.dart
- on_course_shot_segment.dart

## God Nodes (most connected - your core abstractions)
1. `dependencies` - 21 edges
2. `flutter_launcher_icons` - 11 edges
3. `dev_dependencies` - 5 edges
4. `web` - 5 edges
5. `HoleMapFrame` - 4 edges
6. `FairwayTrackerScreenState` - 4 edges
7. `ShotEditDialog` - 4 edges
8. `windows` - 4 edges
9. `ShotRecord` - 3 edges
10. `FairwayTrackerScreen` - 3 edges

## Surprising Connections (you probably didn't know these)
- `OncourseMapPane` --inherits--> `StatefulWidget`  [EXTRACTED]
  lib/widgets/oncourse_map_pane.dart → None  _Bridges community 22 → community 150_
- `_VectorHarness` --inherits--> `StatefulWidget`  [EXTRACTED]
  test/on_course_crse_033_test.dart → None  _Bridges community 22 → community 41_

## Import Cycles
- None detected.

## Communities (258 total, 241 thin omitted)

### Community 0 - "hole_map_marker_painter.dart"
Cohesion: 0.15
Nodes (9): HoleMapBounds, bounds, colorScheme, coords, HoleMapMarkerPainter, paint, player, shots (+1 more)

### Community 1 - "local_database_service.dart"
Cohesion: 0.02
Nodes (101): _addColumnIfMissing, applyCoursePar, applyRemoteRow, _backfillGolfRounds, _columns, compileRangeSession, completeRound, computeRoundTotals (+93 more)

### Community 4 - "golf_models.dart"
Cohesion: 0.03
Nodes (64): aimDirection, avgDistance, avgYards, brand, category, Club, clubId, clubName (+56 more)

### Community 5 - "fairway_tracker_screen.dart"
Cohesion: 0.02
Nodes (81): _activeCoords, _aim, _aimDirection, _appliedCourseName, _beginPinWatch, _bootstrap, build, _busy (+73 more)

### Community 9 - "GeneratedPluginRegistrant.swift"
Cohesion: 0.12
Nodes (14): cloud_firestore, firebase_ai, firebase_app_check, firebase_auth, firebase_core, firebase_storage, FlutterMacOS, Foundation (+6 more)

### Community 19 - "course_map_pack_local.dart"
Cohesion: 0.33
Nodes (3): CourseMapPackLocal, hasPackForCourse, instance

### Community 22 - "FairwayTrackerScreenState"
Cohesion: 0.22
Nodes (6): FairwayTrackerScreen, FairwayTrackerScreenState, ShotEditDialog, _ShotEditDialogState, debugClose, debugSetFileName

### Community 40 - "dependencies"
Cohesion: 0.09
Nodes (22): dependencies, cloud_firestore, cupertino_icons, firebase_ai, firebase_app_check, firebase_auth, firebase_core, firebase_storage (+14 more)

### Community 41 - "on_course_crse_033_test.dart"
Cohesion: 0.06
Nodes (22): current, _FakePinDistance, fix, live, main, waitForBag, watch, main (+14 more)

### Community 51 - "course_map_cache_service.dart"
Cohesion: 0.06
Nodes (21): kOnCourseAimCenter, kOnCourseAimChoices, kOnCourseAimLeft, kOnCourseAimRight, normalizeOnCourseAim, canonicalCourseName, CourseMapCacheService, courseMapPackIdFromName (+13 more)

### Community 57 - "flutter_launcher_icons"
Cohesion: 0.06
Nodes (35): description, dev_dependencies, flutter_launcher_icons, flutter_lints, flutter_test, sqlite3, environment, sdk (+27 more)

### Community 63 - "course_map_manifest.dart"
Cohesion: 0.08
Nodes (20): courseId, CourseMapManifest, entry, fromJson, hasSatelliteImage, heightPx, hole, HoleMapManifestEntry (+12 more)

### Community 68 - "oncourse_vector_hole_map.dart"
Cohesion: 0.22
Nodes (4): build, coords, player, shots

### Community 69 - "oncourse_satellite_hole_map.dart"
Cohesion: 0.20
Nodes (6): HoleMapFrame, build, coords, frame, player, shots

### Community 92 - "hole_map_geo.dart"
Cohesion: 0.07
Nodes (26): boundsForHole, fromManifest, latPad, lats, latSpan, lonPad, lons, lonSpan (+18 more)

### Community 150 - "oncourse_map_pane.dart"
Cohesion: 0.09
Nodes (18): build, coords, courseName, createState, didUpdateWidget, _downloading, _frame, holeNumber (+10 more)

### Community 153 - "on_course_shot_segment.dart"
Cohesion: 0.18
Nodes (8): ShotRecord, hasCurrentStart, hasPriorStart, meters, prior, segment, segmentYardsEndingAt, shotDistanceLabel

## Knowledge Gaps
- **385 isolated node(s):** `HoleMapManifestEntry`, `CourseMapManifest`, `holeNumber`, `imagePath`, `swLat` (+380 more)
  These have ≤1 connection - possible missing edges. (Counts symbols only; 735 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **241 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `ShotRecord` connect `on_course_shot_segment.dart` to `golf_models.dart`, `fairway_tracker_screen.dart`?**
  _High betweenness centrality (0.014) - this node is a cross-community bridge._
- **What connects `HoleMapManifestEntry`, `CourseMapManifest`, `holeNumber` to the rest of the system?**
  _385 weakly-connected nodes found - possible missing edges._
- **Should `local_database_service.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.017857142857142856 - nodes in this community are weakly interconnected._
- **Why does `Club` connect `golf_models.dart` to `fairway_tracker_screen.dart`?**
  _High betweenness centrality (0.010) - this node is a cross-community bridge._
- **Should `golf_models.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.029411764705882353 - nodes in this community are weakly interconnected._
- **Why does `RoundScore` connect `golf_models.dart` to `fairway_tracker_screen.dart`?**
  _High betweenness centrality (0.010) - this node is a cross-community bridge._
- **Should `fairway_tracker_screen.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.019230769230769232 - nodes in this community are weakly interconnected._