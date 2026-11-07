import 'package:flutter/material.dart';

import '../models/golf_models.dart';
import '../services/local_database_service.dart';
import '../theme/app_theme.dart';
import '../widgets/range_session_log.dart';

class ClubsScreen extends StatefulWidget {
  const ClubsScreen({super.key});

  @override
  State<ClubsScreen> createState() => ClubsScreenState();
}

class ClubsScreenState extends State<ClubsScreen> {
  static const categories = ['wood', 'hybrid', 'iron', 'wedge', 'putter', 'other'];

  String _selectedCategory = 'wood';
  List<Club> _clubs = [];
  Map<String, List<double>> _trends = {};

  @override
  void initState() {
    super.initState();
    reload();
  }

  Future<void> reload() async {
    final clubs = await LocalDatabaseService.instance.getClubsByCategory(_selectedCategory);
    final trends = <String, List<double>>{};
    for (final club in clubs) {
      trends[club.id] = await LocalDatabaseService.instance.getClubYardageTrend(club.id);
    }
    if (!mounted) return;
    setState(() {
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
      appBar: AppBar(title: const Text('My Bag')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addClub,
        tooltip: 'Add club',
        shape: const StadiumBorder(),
        icon: const Icon(Icons.add),
        label: const Text('Add club'),
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
                final label = _categoryLabel(cat);
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
                ? const Center(child: Text('No clubs in this category yet. Add a club to get started.'))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                    itemCount: _clubs.length,
                    itemBuilder: (context, index) {
                      final club = _clubs[index];
                      final identity = [club.brand, club.model].where((part) => part.trim().isNotEmpty).join(' · ');
                      final notes = club.swingNotes.trim();
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Align(
                                alignment: Alignment.centerLeft,
                                child: InkWell(
                                  onTap: () => _editClub(club),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                    child: Text(
                                      club.name,
                                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                            color: Theme.of(context).colorScheme.primary,
                                            decoration: TextDecoration.underline,
                                            decorationColor: Theme.of(context).colorScheme.primary,
                                          ),
                                    ),
                                  ),
                                ),
                              ),
                              if (identity.isNotEmpty) ...[
                                Text(identity, style: Theme.of(context).textTheme.bodyMedium),
                                const SizedBox(height: 8),
                              ] else
                                const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _StatChip(label: 'Min', value: '${club.minDistance.round()} yds'),
                                  _StatChip(label: 'Avg', value: '${club.avgDistance.round()} yds'),
                                  _StatChip(label: 'Max', value: '${club.maxDistance.round()} yds'),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _YardageTrend(yards: _trends[club.id] ?? const []),
                              const SizedBox(height: 12),
                              Text('Swing notes', style: Theme.of(context).textTheme.labelMedium),
                              const SizedBox(height: 4),
                              Text(
                                notes.isEmpty ? 'No swing notes' : club.swingNotes,
                                style: notes.isEmpty
                                    ? Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                                        )
                                    : Theme.of(context).textTheme.bodyMedium,
                              ),
                              Row(
                                children: [
                                  Flexible(
                                    child: TextButton.icon(
                                      key: ValueKey('bag-range-logs-${club.id}'),
                                      onPressed: () => _showRangeLogs(club),
                                      icon: const Icon(Icons.history),
                                      label: Text(
                                        'Range logs (${_trends[club.id]?.length ?? 0})',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                  TextButton.icon(
                                    onPressed: () => _editNotes(club),
                                    icon: const Icon(Icons.edit_outlined),
                                    label: const Text('Edit notes'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
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
                  .map((cat) => DropdownMenuItem(value: cat, child: Text(_categoryLabel(cat))))
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

String _categoryLabel(String cat) => cat.isEmpty ? cat : cat[0].toUpperCase() + cat.substring(1);

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
                  .map((cat) => DropdownMenuItem(value: cat, child: Text(_categoryLabel(cat))))
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

class _YardageTrend extends StatelessWidget {
  const _YardageTrend({required this.yards});

  final List<double> yards;

  @override
  Widget build(BuildContext context) {
    if (yards.length < 2) {
      return Text(
        'Not enough range sessions for a trend.',
        style: Theme.of(context).textTheme.bodySmall,
      );
    }
    final first = yards.first.round();
    final last = yards.last.round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Range trend', style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 4),
        SizedBox(
          height: 48,
          width: double.infinity,
          child: CustomPaint(
            painter: _SparklinePainter(yards: yards, color: AppColors.green),
          ),
        ),
        const SizedBox(height: 4),
        Text('$first → $last yds', style: Theme.of(context).textTheme.bodySmall),
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
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.yards != yards || oldDelegate.color != color;
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.labelSmall),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
