import 'package:flutter/material.dart';

import '../data/ph_golf_hole_coords.dart';
import '../models/course_map_manifest.dart';
import '../models/golf_models.dart';
import '../services/course_map_cache_service.dart';
import '../services/pin_distance.dart';
import 'oncourse_satellite_hole_map.dart';
import 'oncourse_vector_hole_map.dart';

/// Resolves course map packs and renders satellite or vector fallback.
class OncourseMapPane extends StatefulWidget {
  const OncourseMapPane({
    super.key,
    required this.courseName,
    required this.holeNumber,
    required this.coords,
    required this.shots,
    this.player,
    this.onVectorFallback,
  });

  final String courseName;
  final int holeNumber;
  final HoleCoordinates coords;
  final List<ShotRecord> shots;
  final PinFix? player;
  final VoidCallback? onVectorFallback;

  @override
  State<OncourseMapPane> createState() => _OncourseMapPaneState();
}

class _OncourseMapPaneState extends State<OncourseMapPane> {
  HoleMapFrame? _frame;
  var _downloading = false;
  var _resolved = false;
  var _vectorSnackSignaled = false;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void didUpdateWidget(covariant OncourseMapPane oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.courseName != widget.courseName ||
        oldWidget.holeNumber != widget.holeNumber) {
      _vectorSnackSignaled = false;
      _resolve();
    }
  }

  Future<void> _resolve() async {
    setState(() {
      _frame = null;
      _downloading = false;
      _resolved = false;
    });
    CourseMapResolveResult result;
    try {
      result = await CourseMapCacheService.instance.resolveHoleMap(
        courseName: widget.courseName,
        holeNumber: widget.holeNumber,
        coords: widget.coords,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _frame = null;
        _resolved = true;
      });
      return;
    }
    if (!mounted) return;
    if (result.kind == CourseMapResolveKind.satellite) {
      setState(() {
        _frame = result.frame;
        _resolved = true;
      });
      return;
    }
    if (result.kind == CourseMapResolveKind.downloading) {
      setState(() {
        _downloading = true;
        _resolved = true;
      });
      final after = await CourseMapCacheService.instance.resolveHoleMap(
        courseName: widget.courseName,
        holeNumber: widget.holeNumber,
        coords: widget.coords,
        allowDownload: true,
      );
      if (!mounted) return;
      setState(() => _downloading = false);
      if (after.kind == CourseMapResolveKind.satellite) {
        setState(() {
          _frame = after.frame;
          _resolved = true;
        });
        return;
      }
      setState(() {
        _frame = null;
        _resolved = true;
      });
      return;
    }
    setState(() {
      _frame = null;
      _resolved = true;
    });
  }

  void _signalVectorFallback() {
    if (_vectorSnackSignaled) return;
    _vectorSnackSignaled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Showing the hole line without the course photo.'),
        ),
      );
      widget.onVectorFallback?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_resolved) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator.adaptive()),
      );
    }
    if (_downloading) {
      return Column(
        key: const ValueKey('oncourse-map-download'),
        children: const [
          LinearProgressIndicator(),
          SizedBox(height: 8),
          Text('Downloading this course…', textAlign: TextAlign.center),
        ],
      );
    }
    if (_frame != null) {
      return OncourseSatelliteHoleMap(
        key: const ValueKey('oncourse-hole-map'),
        frame: _frame!,
        coords: widget.coords,
        shots: widget.shots,
        player: widget.player,
      );
    }
    _signalVectorFallback();
    return OncourseVectorHoleMap(
      coords: widget.coords,
      shots: widget.shots,
      player: widget.player,
    );
  }
}