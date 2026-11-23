import 'package:flutter/material.dart';

import '../models/golf_models.dart';
import '../models/round_summary.dart';
import '../services/pin_distance.dart';
import '../theme/app_theme.dart';

/// Sun-friendly cart scoring layout for [ScorecardScreen] (MGDV-401).
class ScorecardCartPanel extends StatelessWidget {
  const ScorecardCartPanel({
    super.key,
    required this.courseName,
    required this.holeCount,
    required this.selectedHole,
    required this.totals,
    required this.holeRow,
    required this.highContrast,
    required this.onHoleSelected,
    required this.onPlusStroke,
    required this.onPenalty,
    required this.onMulligan,
    required this.onGimme,
    required this.onHighContrastChanged,
    this.formatSummary,
  });

  final String courseName;
  final int holeCount;
  final int selectedHole;
  final RoundTotals? totals;
  final RoundScore? Function(int holeNumber) holeRow;
  final bool highContrast;
  final ValueChanged<int> onHoleSelected;
  final VoidCallback onPlusStroke;
  final VoidCallback onPenalty;
  final VoidCallback onMulligan;
  final VoidCallback onGimme;
  final ValueChanged<bool> onHighContrastChanged;
  final String? formatSummary;

  static const _actionMinSize = Size(56, 64);

  @override
  Widget build(BuildContext context) {
    final row = holeRow(selectedHole);
    final par = row?.par ?? 4;
    final played = row != null && isHolePlayed(row);
    final gross = row != null ? effectiveHoleScore(row) : 0;
    final yardage = catalogTeeToGreenYards(courseName, selectedHole);
    final holeLine = yardage == null
        ? 'Hole $selectedHole · Par $par'
        : 'Hole $selectedHole · Par $par · $yardage yds';

    final fg = highContrast ? Colors.white : null;
    final bg = highContrast ? const Color(0xFF121212) : null;

    return Material(
      color: bg ?? Theme.of(context).colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (totals != null) _CartTotalsBar(totals: totals!, highContrast: highContrast),
          if (formatSummary != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: Text(
                formatSummary!,
                key: const ValueKey('scorecard-cart-format-total'),
                textAlign: TextAlign.center,
              ),
            ),
          SwitchListTile(
            key: const ValueKey('scorecard-cart-high-contrast-switch'),
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
            title: Text('High contrast (sun)', style: TextStyle(color: fg)),
            value: highContrast,
            onChanged: onHighContrastChanged,
          ),
          SizedBox(
            height: 52,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: holeCount,
              itemBuilder: (context, index) {
                final hole = index + 1;
                final holeData = holeRow(hole);
                final isSelected = hole == selectedHole;
                final complete =
                    holeData != null && isHolePlayed(holeData);
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    key: ValueKey('scorecard-cart-hole-strip-$hole'),
                    label: Text('$hole'),
                    selected: isSelected,
                    visualDensity: VisualDensity.compact,
                    onSelected: (_) => onHoleSelected(hole),
                    avatar: complete
                        ? Icon(
                            Icons.check,
                            size: 16,
                            color: isSelected
                                ? Theme.of(context).colorScheme.onPrimary
                                : AppColors.green,
                          )
                        : null,
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              holeLine,
              key: ValueKey('scorecard-cart-hole-$selectedHole'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          Text(
            played ? '$gross' : '—',
            key: const ValueKey('scorecard-cart-stroke-count'),
            textAlign: TextAlign.center,
            style: GolfTextStyles.tabularNum(context, fontSize: 72).copyWith(
              color: fg ?? Theme.of(context).colorScheme.onSurface,
            ),
          ),
          if (row != null && (row.penalties > 0 || row.mulligans > 0))
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'Penalties ${row.penalties} · Mulligans ${row.mulligans}',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: fg?.withValues(alpha: 0.85)),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: FilledButton(
              key: const ValueKey('scorecard-cart-stroke-plus'),
              onPressed: onPlusStroke,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(72),
                textStyle:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                backgroundColor: highContrast ? AppColors.green : null,
              ),
              child: const Text('+1 stroke'),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    key: const ValueKey('scorecard-cart-penalty'),
                    onPressed: onPenalty,
                    style: OutlinedButton.styleFrom(minimumSize: _actionMinSize),
                    child: const Text('Penalty +1'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    key: const ValueKey('scorecard-cart-mulligan'),
                    onPressed: onMulligan,
                    style: OutlinedButton.styleFrom(minimumSize: _actionMinSize),
                    child: Text('Mulligan${row != null ? ' ${row.mulligans}' : ''}'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton(
              key: const ValueKey('scorecard-cart-gimme'),
              onPressed: onGimme,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
              ),
              child: const Text('Gimme / concede'),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _CartTotalsBar extends StatelessWidget {
  const _CartTotalsBar({required this.totals, required this.highContrast});

  final RoundTotals totals;
  final bool highContrast;

  @override
  Widget build(BuildContext context) {
    final fg = highContrast ? Colors.white : null;
    return Card(
      key: const ValueKey('scorecard-cart-totals-banner'),
      color: highContrast ? const Color(0xFF1E1E1E) : null,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _Cell(
              label: 'OUT',
              score: totals.frontNineScore,
              toPar: totals.frontNineToPar,
              fg: fg,
            ),
            _Cell(
              label: 'IN',
              score: totals.backNineScore,
              toPar: totals.backNineToPar,
              fg: fg,
            ),
            _Cell(
              label: 'TOT',
              score: totals.totalScore,
              toPar: totals.totalToPar,
              fg: fg,
            ),
          ],
        ),
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({
    required this.label,
    required this.score,
    required this.toPar,
    this.fg,
  });

  final String label;
  final int score;
  final int toPar;
  final Color? fg;

  @override
  Widget build(BuildContext context) {
    final toParLabel = toPar == 0 ? 'E' : (toPar > 0 ? '+$toPar' : '$toPar');
    return Column(
      children: [
        Text(label, style: TextStyle(color: fg)),
        Text(
          '$score',
          style: GolfTextStyles.tabularNum(context, fontSize: 28)
              .copyWith(color: fg),
        ),
        Text(toParLabel, style: TextStyle(color: fg, fontSize: 12)),
      ],
    );
  }
}