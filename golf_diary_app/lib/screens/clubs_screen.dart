import 'package:flutter/material.dart';

import '../models/golf_models.dart';
import '../models/golfer_profile.dart';
import '../services/golfer_profile_store.dart';
import '../services/local_database_service.dart';
import '../theme/app_theme.dart';
import '../ui/yardage_display_copy.dart';
import '../widgets/range_session_log.dart';
import '../ui/header_action_policy.dart';
import '../widgets/shared_header_actions.dart';

class ClubsScreen extends StatefulWidget {
  const ClubsScreen({super.key, this.onProfileSettingsChanged});

  final VoidCallback? onProfileSettingsChanged;

  @override
  State<ClubsScreen> createState() => ClubsScreenState();
}

class ClubsScreenState extends State<ClubsScreen> {
  static const categories = ['wood', 'hybrid', 'iron', 'wedge', 'putter', 'other'];

  String _selectedCategory = 'wood';
  List<Club> _clubs = [];
  Map<String, List<double>> _trends = {};
  GolferProfile _profile = const GolferProfile();
  GolferProfileStore? _profileStore;

  /// For MGDV-203 progressive disclosure.
  YardageUiDensity get yardageDensity => resolveYardageUiDensity(_profile);

  @override
  void initState() {
    super.initState();
    reload();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = GolferProfileScope.maybeOf(context);
    if (identical(next, _profileStore)) return;
    _profileStore?.removeListener(_onProfileStoreChanged);
    _profileStore = next;
    _profileStore?.addListener(_onProfileStoreChanged);
    if (_profileStore != null && _profileStore!.profile.updatedAtMs > 0) {
      _profile = _profileStore!.profile;
    }
  }

  @override
  void dispose() {
    _profileStore?.removeListener(_onProfileStoreChanged);
    super.dispose();
  }

  void _onProfileStoreChanged() {
    final store = _profileStore;
    if (store == null || !mounted) return;
    setState(() => _profile = store.profile);
  }

  Future<void> reload() async {
    final clubs = await LocalDatabaseService.instance.getClubsByCategory(_selectedCategory);
    final profile = await LocalDatabaseService.instance.getGolferProfile();
    final trends = <String, List<double>>{};
    for (final club in clubs) {
      trends[club.id] = await LocalDatabaseService.instance.getClubYardageTrend(club.id);
    }
    if (!mounted) return;
    setState(() {
      _profile = profile;
      _clubs = clubs;
      _trends = trends;
    });
  }

  Future<void> _saveNotes(Club club, String notes) async {
    await LocalDatabaseService.instance.updateClubSwingNotes(club.id, notes);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Saved swing notes for ${club.name}'), backgroundColor: AppColors.green),
    );
    await reload();
  }

  Future<void> _showRangeLogs(Club club) async {
    final sessions = await LocalDatabaseService.instance.listRangeDrills(clubId: club.id);
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => ClubRangeLogSheet(club: club, sessions: sessions),
    );
  }

  Future<void> _editNotes(Club club) async {
    final notes = await showDialog<String>(
      context: context,
      builder: (context) => SwingNotesDialog(club: club),
    );
    if (notes == null) return;
    await _saveNotes(club, notes);
  }

  Future<void> _addClub() async {
    final created = await showDialog<Club>(
      context: context,
      builder: (context) => _AddClubDialog(initialCategory: _selectedCategory),
    );
    if (created == null) return;
    await LocalDatabaseService.instance.insertClub(created);
    if (!mounted) return;
    setState(() => _selectedCategory = created.category);
    await reload();
  }

  Future<void> _editClub(Club club) async {
    final result = await showDialog<ClubEditResult>(
      context: context,
      builder: (context) => EditClubDialog(club: club),
    );
    if (result == null || !mounted) return;
    if (result.deleted) {
      await LocalDatabaseService.instance.deleteClub(club.id);
      await reload();
      return;
    }
    final updated = result.club;
    if (updated == null) return;
    await LocalDatabaseService.instance.updateClubIdentity(updated);
    if (!mounted) return;
    if (updated.category != _selectedCategory) {
      setState(() => _selectedCategory = updated.category);
    }
    await reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          key: const Key('add-club-button'),
          tooltip: 'Add club',
          onPressed: _addClub,
          icon: const Icon(Icons.add),
        ),
        title: const Text('My Bag'),
        actions: [
          const SharedHeaderActions(tab: HeaderTabContext.bag),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: categories.map((cat) {
                final label = bagCategoryLabel(cat);
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(label),
                    selected: _selectedCategory == cat,
                    onSelected: (_) {
                      setState(() => _selectedCategory = cat);
                      reload();
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: _clubs.isEmpty
                ? const Center(
                    child: Text(
                      'No clubs in this category yet. Add a club to get started.',
                      key: ValueKey('bag-empty-category'),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    itemCount: _clubs.length,
                    itemBuilder: (context, index) {
                      final club = _clubs[index];
                      final sessionCount = _trends[club.id]?.length ?? 0;
                      return _ClubBagCard(
                        club: club,
                        sessionCount: sessionCount,
                        trendYards: _trends[club.id] ?? const [],
                        density: yardageDensity,
                        onEditClub: () => _editClub(club),
                        onRangeLogs: () => _showRangeLogs(club),
                        onEditNotes: () => _editNotes(club),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

@visibleForTesting
class ClubRangeLogSheet extends StatelessWidget {
  const ClubRangeLogSheet({super.key, required this.club, required this.sessions});

  final Club club;
  final List<RangeDrillSummary> sessions;

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height * 0.6;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: SizedBox(
          height: height,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(club.name, style: Theme.of(context).textTheme.titleLarge),
              Text(
                'Past range sessions',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  child: RangeSessionLog(
                    sessions: sessions,
                    showClubName: false,
                    emptyMessage: 'No range sessions for ${club.name} yet.',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

@visibleForTesting
class ClubEditResult {
  const ClubEditResult.saved(this.club) : deleted = false;
  const ClubEditResult.deleted() : club = null, deleted = true;

  final Club? club;
  final bool deleted;
}

@visibleForTesting
class EditClubDialog extends StatefulWidget {
  const EditClubDialog({super.key, required this.club});

  final Club club;

  @override
  State<EditClubDialog> createState() => _EditClubDialogState();
}

class _EditClubDialogState extends State<EditClubDialog> {
  late String _category = widget.club.category;
  late final TextEditingController _name = TextEditingController(text: widget.club.name);
  late final TextEditingController _brand = TextEditingController(text: widget.club.brand);
  late final TextEditingController _model = TextEditingController(text: widget.club.model);
  String? _nameError;

  @override
  void dispose() {
    _name.dispose();
    _brand.dispose();
    _model.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = 'Enter a club name');
      return;
    }
    Navigator.pop(
      context,
      ClubEditResult.saved(
        widget.club.copyWith(
          name: name,
          category: _category,
          brand: _brand.text.trim(),
          model: _model.text.trim(),
        ),
      ),
    );
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete club'),
        content: Text('Delete ${widget.club.name} from your bag? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      Navigator.pop(context, const ClubEditResult.deleted());
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit club'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _name,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Club name',
                errorText: _nameError,
              ),
              textCapitalization: TextCapitalization.words,
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: ClubsScreenState.categories.contains(_category) ? _category : 'other',
              decoration: const InputDecoration(labelText: 'Category'),
              items: ClubsScreenState.categories
                  .map((cat) => DropdownMenuItem(value: cat, child: Text(bagCategoryLabel(cat))))
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _category = value);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _brand,
              decoration: const InputDecoration(labelText: 'Brand (optional)'),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _model,
              decoration: const InputDecoration(labelText: 'Model (optional)'),
              textCapitalization: TextCapitalization.words,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _confirmDelete,
          style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
          child: const Text('Delete'),
        ),
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(onPressed: _submit, child: const Text('Save')),
      ],
    );
  }
}

@visibleForTesting
class SwingNotesDialog extends StatefulWidget {
  const SwingNotesDialog({super.key, required this.club});

  final Club club;

  @override
  State<SwingNotesDialog> createState() => _SwingNotesDialogState();
}

class _SwingNotesDialogState extends State<SwingNotesDialog> {
  late final TextEditingController _notes = TextEditingController(text: widget.club.swingNotes);

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.club.name),
      content: TextField(
        controller: _notes,
        autofocus: true,
        decoration: const InputDecoration(
          labelText: 'Swing notes',
          alignLabelWithHint: true,
        ),
        minLines: 3,
        maxLines: 6,
        textCapitalization: TextCapitalization.sentences,
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _notes.text),
          child: const Text('Save notes'),
        ),
      ],
    );
  }
}

class _ClubBagCard extends StatelessWidget {
  const _ClubBagCard({
    required this.club,
    required this.sessionCount,
    required this.trendYards,
    required this.density,
    required this.onEditClub,
    required this.onRangeLogs,
    required this.onEditNotes,
  });

  final Club club;
  final int sessionCount;
  final List<double> trendYards;
  final YardageUiDensity density;
  final VoidCallback onEditClub;
  final VoidCallback onRangeLogs;
  final VoidCallback onEditNotes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final labels = YardageStatLabels.forDensity(density);
    final identity = [club.brand, club.model].where((part) => part.trim().isNotEmpty).join(' · ');
    final notes = club.swingNotes.trim();

    return Card(
      key: ValueKey('bag-club-card-${club.id}'),
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 2, 8, 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    key: ValueKey('bag-club-edit-${club.id}'),
                    onTap: onEditClub,
                    borderRadius: BorderRadius.circular(8),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 48),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: club.name,
                                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              WidgetSpan(
                                alignment: PlaceholderAlignment.middle,
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 4),
                                  child: Icon(Icons.edit, size: 12, color: scheme.onSurfaceVariant),
                                ),
                              ),
                              if (identity.isNotEmpty)
                                TextSpan(
                                  text: '  $identity',
                                  style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                                ),
                            ],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Semantics(
                  label: 'Range logs ($sessionCount)',
                  button: true,
                  excludeSemantics: true,
                  child: ActionChip(
                    key: ValueKey('bag-range-logs-${club.id}'),
                    onPressed: onRangeLogs,
                    avatar: const Icon(Icons.history, size: 16),
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('$sessionCount', style: const TextStyle(fontWeight: FontWeight.w600)),
                        const Icon(Icons.chevron_right, size: 16),
                      ],
                    ),
                    labelPadding: const EdgeInsets.only(left: 2),
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    visualDensity: VisualDensity.compact,
                    side: BorderSide.none,
                    backgroundColor: scheme.surfaceContainerHigh,
                    shape: const StadiumBorder(),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Row(
                children: [
                  Expanded(
                    child: _StatTile(
                      label: labels.shortest,
                      value: _tileYards(club.minDistance),
                      valueKey: ValueKey('bag-min-yards-${club.id}'),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _StatTile(
                      label: labels.usual,
                      value: _tileYards(club.avgDistance),
                      valueKey: ValueKey('bag-hero-yards-${club.id}'),
                      highlighted: true,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _StatTile(
                      label: labels.longest,
                      value: _tileYards(club.maxDistance),
                      valueKey: ValueKey('bag-max-yards-${club.id}'),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(child: _TrendTile(clubId: club.id, yards: trendYards)),
                ],
              ),
            ),
            InkWell(
              key: ValueKey(notes.isEmpty ? 'bag-notes-add-${club.id}' : 'bag-notes-text-${club.id}'),
              onTap: onEditNotes,
              borderRadius: BorderRadius.circular(8),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 40),
                child: Row(
                  children: [
                    Icon(
                      notes.isEmpty ? Icons.add : Icons.edit_outlined,
                      size: 16,
                      color: notes.isEmpty ? scheme.primary : scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        notes.isEmpty ? 'Add swing note' : '“$notes”',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: notes.isEmpty
                            ? theme.textTheme.bodyMedium?.copyWith(color: scheme.primary, fontWeight: FontWeight.w500)
                            : theme.textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _tileYards(double yards) => yards <= 0 ? '—' : '${yards.round()}';
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.valueKey,
    this.highlighted = false,
  });

  final String label;
  final String value;
  final Key valueKey;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: value == '—' ? '$label, no distance yet' : '$label $value yards',
      excludeSemantics: true,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: highlighted ? scheme.primaryContainer : scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.fade,
              softWrap: false,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
                color: scheme.onSurfaceVariant,
              ),
            ),
            Text(
              value,
              key: valueKey,
              maxLines: 1,
              style: GolfTextStyles.tabularNum(context, fontSize: 16, fontWeight: highlighted ? FontWeight.w700 : FontWeight.w600)
                  .copyWith(color: highlighted ? scheme.onPrimaryContainer : scheme.onSurface),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrendTile extends StatelessWidget {
  const _TrendTile({required this.clubId, required this.yards});

  final String clubId;
  final List<double> yards;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasTrend = yards.length >= 2;
    final first = hasTrend ? yards.first.round() : 0;
    final last = hasTrend ? yards.last.round() : 0;
    final delta = last - first;
    final deltaColor = delta < 0 ? GolfPalette.negative : GolfPalette.positive;
    final message = hasTrend ? 'Range trend $first → $last yds' : 'Not enough range sessions for a trend';

    return Tooltip(
      key: ValueKey('bag-trend-$clubId'),
      message: message,
      excludeFromSemantics: true,
      child: Semantics(
        label: message,
        excludeSemantics: true,
        child: Container(
          height: 44,
          padding: const EdgeInsets.fromLTRB(6, 5, 6, 5),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text(
                    'TREND',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.4,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  if (hasTrend)
                    Text(
                      delta == 0 ? '±0' : (delta > 0 ? '+$delta' : '−${delta.abs()}'),
                      style: GolfTextStyles.tabularNum(context, fontSize: 11, fontWeight: FontWeight.w700)
                          .copyWith(color: delta == 0 ? scheme.onSurfaceVariant : deltaColor),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Expanded(
                child: hasTrend
                    ? CustomPaint(painter: _SparklinePainter(yards: yards, color: AppColors.green))
                    : Align(
                        alignment: Alignment.centerLeft,
                        child: Text('—', style: TextStyle(color: scheme.onSurfaceVariant)),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddClubDialog extends StatefulWidget {
  const _AddClubDialog({required this.initialCategory});

  final String initialCategory;

  @override
  State<_AddClubDialog> createState() => _AddClubDialogState();
}

class _AddClubDialogState extends State<_AddClubDialog> {
  late String _category = widget.initialCategory;
  final _name = TextEditingController();
  final _brand = TextEditingController();
  final _model = TextEditingController();
  String? _nameError;

  @override
  void dispose() {
    _name.dispose();
    _brand.dispose();
    _model.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = 'Enter a club name');
      return;
    }
    Navigator.pop(
      context,
      Club(
        id: 'club_${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        category: _category,
        brand: _brand.text.trim(),
        model: _model.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add club'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _name,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Club name',
                hintText: '7 iron, 60°, mini driver…',
                errorText: _nameError,
              ),
              textCapitalization: TextCapitalization.words,
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(labelText: 'Category'),
              items: ClubsScreenState.categories
                  .map((cat) => DropdownMenuItem(value: cat, child: Text(bagCategoryLabel(cat))))
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _category = value);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _brand,
              decoration: const InputDecoration(labelText: 'Brand (optional)'),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _model,
              decoration: const InputDecoration(labelText: 'Model (optional)'),
              textCapitalization: TextCapitalization.words,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(onPressed: _submit, child: const Text('Add')),
      ],
    );
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter({required this.yards, required this.color});

  final List<double> yards;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (yards.length < 2) return;
    final minY = yards.reduce((a, b) => a < b ? a : b);
    final maxY = yards.reduce((a, b) => a > b ? a : b);
    final span = (maxY - minY).abs() < 0.01 ? 1.0 : maxY - minY;
    final path = Path();
    for (var i = 0; i < yards.length; i++) {
      final x = yards.length == 1 ? size.width / 2 : size.width * i / (yards.length - 1);
      final y = size.height - ((yards[i] - minY) / span) * (size.height - 4) - 2;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.75
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.yards != yards || oldDelegate.color != color;
  }
}
