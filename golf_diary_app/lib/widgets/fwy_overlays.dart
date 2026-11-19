import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

const kFwyOverlayShadow = [Shadow(blurRadius: 2, color: Colors.black87)];

/// White w600 text with a shadow for rows drawn over the map.
TextStyle fwyOverlayText(BuildContext context, {double fontSize = 14}) {
  return TextStyle(
    color: Colors.white,
    fontSize: fontSize,
    fontWeight: FontWeight.w600,
    shadows: kFwyOverlayShadow,
  );
}

/// Solid (no blur) surface used for rail tiles and map badges.
BoxDecoration fwySurface(BuildContext context, {bool selected = false}) {
  final scheme = Theme.of(context).colorScheme;
  return BoxDecoration(
    color: selected
        ? GolfPalette.fairwayGreen
        : scheme.surface.withValues(alpha: 0.92),
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: scheme.outlineVariant),
  );
}

/// One square button on the FWY Club/Lie/Aim/Pen/Mul rail.
class FwyRailTile extends StatelessWidget {
  const FwyRailTile({
    super.key,
    required this.size,
    required this.label,
    required this.onTap,
    this.value,
    this.icon,
    this.height,
    this.selected = false,
    this.onLongPress,
    this.tooltip,
    this.valueKey,
  });

  final double size;
  final double? height;
  final String label;
  final String? value;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final String? tooltip;
  final Key? valueKey;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = selected ? Colors.white : scheme.onSurface;
    return Tooltip(
      message: tooltip ?? label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          onLongPress: onLongPress,
          child: Ink(
            width: size,
            height: height ?? size,
            decoration: fwySurface(context, selected: selected),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (label.isNotEmpty)
                      Text(label,
                          maxLines: 1,
                          style: TextStyle(
                              fontSize: 10,
                              color: fg,
                              fontWeight: FontWeight.w500)),
                    if (icon != null)
                      Icon(icon, size: 20, color: fg)
                    else if (value != null)
                      Text(
                        value!,
                        key: valueKey,
                        maxLines: 1,
                        style: TextStyle(
                            fontSize: 13,
                            color: fg,
                            fontWeight: FontWeight.w700),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Small rounded label drawn over the map (Line only, Sample hole, ...).
class FwyMapBadge extends StatelessWidget {
  const FwyMapBadge({super.key, required this.text, this.icon});

  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: fwySurface(context).copyWith(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14),
              const SizedBox(width: 4),
            ],
            Flexible(
              child: Text(text,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }
}

/// − n + popover anchored to a rail tile (Pen / Mul).
Future<void> showFwyCounterPopover({
  required BuildContext anchor,
  required String label,
  required String keyPrefix,
  required int initial,
  required Future<int> Function(int delta) onStep,
}) async {
  final box = anchor.findRenderObject() as RenderBox?;
  final overlay =
      Overlay.of(anchor).context.findRenderObject() as RenderBox?;
  if (box == null || overlay == null) return;
  final topLeft = box.localToGlobal(Offset.zero, ancestor: overlay);
  final onRight = topLeft.dx + box.size.width / 2 > overlay.size.width / 2;
  final edgeX =
      onRight ? topLeft.dx - 8 : topLeft.dx + box.size.width + 8;
  final rect = Rect.fromLTWH(edgeX, topLeft.dy, 0, box.size.height);
  await showMenu<void>(
    context: anchor,
    position: RelativeRect.fromRect(rect, Offset.zero & overlay.size),
    items: [
      _CounterEntry(
        label: label,
        keyPrefix: keyPrefix,
        initial: initial,
        onStep: onStep,
      ),
    ],
  );
}

class _CounterEntry extends PopupMenuEntry<void> {
  const _CounterEntry({
    required this.label,
    required this.keyPrefix,
    required this.initial,
    required this.onStep,
  });

  final String label;
  final String keyPrefix;
  final int initial;
  final Future<int> Function(int delta) onStep;

  @override
  double get height => 56;

  @override
  bool represents(void value) => false;

  @override
  State<_CounterEntry> createState() => _CounterEntryState();
}

class _CounterEntryState extends State<_CounterEntry> {
  late int _count = widget.initial;
  var _busy = false;

  Future<void> _step(int delta) async {
    if (_busy) return;
    setState(() => _busy = true);
    final next = await widget.onStep(delta);
    if (!mounted) return;
    setState(() {
      _count = next;
      _busy = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final lower = widget.label.toLowerCase();
    return Padding(
      key: ValueKey('${widget.keyPrefix}-popover'),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(widget.label, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(width: 4),
          IconButton(
            key: ValueKey('${widget.keyPrefix}-step-down'),
            tooltip: 'Remove $lower',
            onPressed: _count > 0 && !_busy ? () => _step(-1) : null,
            icon: const Icon(Icons.remove_circle_outline),
          ),
          Text(
            '$_count',
            key: ValueKey('${widget.keyPrefix}-count'),
            semanticsLabel: '${widget.label} $_count',
            style: GolfTextStyles.tabularNum(context, fontSize: 18),
          ),
          IconButton(
            key: ValueKey('${widget.keyPrefix}-step-up'),
            tooltip: 'Add $lower',
            onPressed: _busy ? null : () => _step(1),
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
    );
  }
}
