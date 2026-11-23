import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/scoring_format.dart';

/// Format, rating, attestation, and handicap line for the scorecard.
class ScorecardFormatBar extends StatelessWidget {
  const ScorecardFormatBar({
    super.key,
    required this.settings,
    required this.summary,
    required this.handicap,
    required this.onFormat,
    required this.onDoubleEagle,
    required this.onRating,
    required this.onAttest,
  });

  final RoundFormatSettings settings;
  final String summary;
  final double? handicap;
  final ValueChanged<ScoringFormat> onFormat;
  final ValueChanged<int> onDoubleEagle;
  final void Function(double? courseRating, int? slope) onRating;
  final VoidCallback onAttest;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentedButton<ScoringFormat>(
          key: const ValueKey('scorecard-format-toggle'),
          showSelectedIcon: false,
          segments: [
            for (final format in ScoringFormat.values)
              ButtonSegment(
                value: format,
                label: Text(format.label),
              ),
          ],
          selected: {settings.format},
          onSelectionChanged: (selection) => onFormat(selection.first),
        ),
        const SizedBox(height: 8),
        Text(summary, key: const ValueKey('scorecard-format-total')),
        if (settings.format == ScoringFormat.molave)
          Wrap(
            spacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text('Double eagle'),
              ChoiceChip(
                key: const ValueKey('scorecard-double-eagle-7'),
                label: const Text('7'),
                selected: settings.molaveDoubleEaglePoints != 6,
                onSelected: (_) => onDoubleEagle(7),
              ),
              ChoiceChip(
                key: const ValueKey('scorecard-double-eagle-6'),
                label: const Text('6'),
                selected: settings.molaveDoubleEaglePoints == 6,
                onSelected: (_) => onDoubleEagle(6),
              ),
            ],
          ),
        const SizedBox(height: 8),
        _RatingRow(settings: settings, onRating: onRating),
        const SizedBox(height: 8),
        Text(
          settings.attestationLabel,
          key: const ValueKey('scorecard-attest-badge'),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            key: const ValueKey('scorecard-attest-btn'),
            onPressed: onAttest,
            child: const Text('Attest card'),
          ),
        ),
        if (handicap != null)
          Text(
            'Unofficial estimate $handicap',
            key: const ValueKey('scorecard-handicap-estimate'),
          ),
      ],
    );
  }
}

class _RatingRow extends StatefulWidget {
  const _RatingRow({required this.settings, required this.onRating});

  final RoundFormatSettings settings;
  final void Function(double? courseRating, int? slope) onRating;

  @override
  State<_RatingRow> createState() => _RatingRowState();
}

class _RatingRowState extends State<_RatingRow> {
  late final TextEditingController _rating;
  late final TextEditingController _slope;

  @override
  void initState() {
    super.initState();
    _rating = TextEditingController(
      text: widget.settings.courseRating?.toString() ?? '',
    );
    _slope = TextEditingController(
      text: widget.settings.slopeRating?.toString() ?? '',
    );
  }

  @override
  void didUpdateWidget(covariant _RatingRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextRating = widget.settings.courseRating?.toString() ?? '';
    final nextSlope = widget.settings.slopeRating?.toString() ?? '';
    if (_rating.text != nextRating &&
        oldWidget.settings.courseRating != widget.settings.courseRating) {
      _rating.text = nextRating;
    }
    if (_slope.text != nextSlope &&
        oldWidget.settings.slopeRating != widget.settings.slopeRating) {
      _slope.text = nextSlope;
    }
  }

  @override
  void dispose() {
    _rating.dispose();
    _slope.dispose();
    super.dispose();
  }

  void _commit() {
    final rating = double.tryParse(_rating.text.trim());
    final slope = int.tryParse(_slope.text.trim());
    widget.onRating(rating, slope);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            key: const ValueKey('scorecard-course-rating'),
            controller: _rating,
            decoration: const InputDecoration(
              labelText: 'Course rating',
              isDense: true,
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            onSubmitted: (_) => _commit(),
            onEditingComplete: _commit,
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
            onSubmitted: (_) => _commit(),
            onEditingComplete: _commit,
          ),
        ),
      ],
    );
  }
}
