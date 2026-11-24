import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/ph_golf_catalog.dart';
import '../models/scoring_format.dart';
import 'venue_name_field.dart';

/// Values the shared Course dialog reads and writes.
class CourseRoundValues {
  const CourseRoundValues({
    required this.courseName,
    this.format = ScoringFormat.gross,
    this.molaveDoubleEaglePoints = 7,
    this.courseRating,
    this.slopeRating,
  });

  final String courseName;
  final ScoringFormat format;
  final int molaveDoubleEaglePoints;
  final double? courseRating;
  final int? slopeRating;
}

bool _sameRating(double? a, double? b) {
  if (a == null || b == null) return a == null && b == null;
  return (a - b).abs() < 0.001;
}

/// True when [next] would change the stored course name or format settings.
bool courseRoundChanged({
  required String courseName,
  required RoundFormatSettings settings,
  required CourseRoundValues next,
}) {
  return courseName.trim() != next.courseName.trim() ||
      settings.format != next.format ||
      normalizeDoubleEaglePoints(settings.molaveDoubleEaglePoints) !=
          normalizeDoubleEaglePoints(next.molaveDoubleEaglePoints) ||
      !_sameRating(settings.courseRating, next.courseRating) ||
      settings.slopeRating != next.slopeRating;
}

RoundFormatSettings applyCourseRoundValues(
  RoundFormatSettings settings,
  CourseRoundValues next,
) {
  return settings.copyWith(
    format: next.format,
    molaveDoubleEaglePoints: next.molaveDoubleEaglePoints,
    courseRating: next.courseRating,
    slopeRating: next.slopeRating,
    clearCourseRating: next.courseRating == null,
    clearSlope: next.slopeRating == null,
  );
}

/// Same confirm Scorecard and On Course show before writing an attested round.
Future<bool> showAttestedEditConfirm(BuildContext context) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Edit attested card?'),
      content: const Text(
        'This clears the attestation until the card is attested again.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const ValueKey('scorecard-attest-edit-confirm'),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Edit'),
        ),
      ],
    ),
  );
  return ok == true;
}

/// One course dialog for Scorecard and On Course.
///
/// Cancel returns null and writes nothing. Save returns the course name,
/// format, Molave double-eagle points, and optional rating and slope.
Future<CourseRoundValues?> showCourseRoundDialog({
  required BuildContext context,
  required CourseRoundValues initial,
  required List<String> recentNames,
}) {
  return showDialog<CourseRoundValues>(
    context: context,
    builder: (context) => _CourseRoundDialog(
      initial: initial,
      recentNames: recentNames,
    ),
  );
}

class _CourseRoundDialog extends StatefulWidget {
  const _CourseRoundDialog({
    required this.initial,
    required this.recentNames,
  });

  final CourseRoundValues initial;
  final List<String> recentNames;

  @override
  State<_CourseRoundDialog> createState() => _CourseRoundDialogState();
}

class _CourseRoundDialogState extends State<_CourseRoundDialog> {
  late final TextEditingController _name;
  late final TextEditingController _rating;
  late final TextEditingController _slope;
  late ScoringFormat _format;
  late int _doubleEagle;

  @override
  void initState() {
    super.initState();
    final initialName = widget.initial.courseName.trim();
    _name = TextEditingController(
      text: initialName.isEmpty ? 'Local Course' : initialName,
    );
    _rating = TextEditingController(
      text: widget.initial.courseRating?.toString() ?? '',
    );
    _slope = TextEditingController(
      text: widget.initial.slopeRating?.toString() ?? '',
    );
    _format = widget.initial.format;
    _doubleEagle = normalizeDoubleEaglePoints(
      widget.initial.molaveDoubleEaglePoints,
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _rating.dispose();
    _slope.dispose();
    super.dispose();
  }

  void _save() {
    final name = _name.text.trim();
    final rating = double.tryParse(_rating.text.trim());
    final slope = int.tryParse(_slope.text.trim());
    Navigator.pop(
      context,
      CourseRoundValues(
        courseName: name.isEmpty ? 'Local Course' : name,
        format: _format,
        molaveDoubleEaglePoints: _doubleEagle,
        courseRating: rating,
        slopeRating: slope,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      key: const ValueKey('oncourse-course-sheet'),
      title: const Text('Course'),
      scrollable: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          VenueNameField(
            key: const ValueKey('oncourse-course-name-field'),
            fieldKey: const ValueKey('scorecard-new-round-course'),
            controller: _name,
            labelText: 'Course name',
            recentNames: widget.recentNames,
            catalogNames: PhGolfCatalog.courseNames,
            captionFor: PhGolfCatalog.courseCaption,
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SegmentedButton<ScoringFormat>(
              key: const ValueKey('scorecard-format-toggle'),
              showSelectedIcon: false,
              segments: [
                for (final format in ScoringFormat.values)
                  ButtonSegment(
                    value: format,
                    label: Text(format.label),
                  ),
              ],
              selected: {_format},
              onSelectionChanged: (selection) {
                setState(() => _format = selection.first);
              },
            ),
          ),
          if (_format == ScoringFormat.molave) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text('Double eagle'),
                ChoiceChip(
                  key: const ValueKey('scorecard-double-eagle-7'),
                  label: const Text('7'),
                  selected: _doubleEagle != 6,
                  onSelected: (_) => setState(() => _doubleEagle = 7),
                ),
                ChoiceChip(
                  key: const ValueKey('scorecard-double-eagle-6'),
                  label: const Text('6'),
                  selected: _doubleEagle == 6,
                  onSelected: (_) => setState(() => _doubleEagle = 6),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  key: const ValueKey('scorecard-course-rating'),
                  controller: _rating,
                  decoration: const InputDecoration(
                    labelText: 'Course rating',
                    isDense: true,
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  key: const ValueKey('scorecard-slope'),
                  controller: _slope,
                  decoration: const InputDecoration(
                    labelText: 'Slope',
                    isDense: true,
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          key: const ValueKey('scorecard-new-round-cancel'),
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const ValueKey('scorecard-new-round-start'),
          onPressed: _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
