import 'package:flutter/material.dart';

import '../models/golf_models.dart';
import '../services/local_database_service.dart';
import '../theme/app_theme.dart';

class ClubsScreen extends StatefulWidget {
  const ClubsScreen({super.key});

  @override
  State<ClubsScreen> createState() => ClubsScreenState();
}

/// Public so [HomeShell] can refresh after a range drill updates distances.
class ClubsScreenState extends State<ClubsScreen> {
  static const _categories = ['wood', 'hybrid', 'iron', 'wedge', 'putter'];

  String _selectedCategory = 'wood';
  List<Club> _clubs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    reloadClubs();
  }

  Future<void> reloadClubs() => _loadClubs();

  Future<void> _loadClubs() async {
    final clubs = await LocalDatabaseService.instance.getClubsByCategory(_selectedCategory);
    if (!mounted) return;
    setState(() {
      _clubs = clubs;
      _loading = false;
    });
  }

  Future<void> _openNotes(Club club) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
        child: _NotesSheet(club: club),
      ),
    );
    if (saved == true) {
      await _loadClubs();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Bag')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 56,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              children: _categories.map((cat) {
                final label = cat[0].toUpperCase() + cat.substring(1);
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    key: ValueKey('bag-category-chip-$cat'),
                    label: Text(label),
                    selected: _selectedCategory == cat,
                    onSelected: _loading
                        ? null
                        : (_) {
                            setState(() => _selectedCategory = cat);
                            _loadClubs();
                          },
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _clubs.isEmpty
                    ? const Center(
                        child: Text(
                          'No clubs in this category',
                          key: ValueKey('bag-empty-category'),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        itemCount: _clubs.length,
                        itemBuilder: (context, index) {
                          final club = _clubs[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _ClubGlanceCard(
                              club: club,
                              onTap: () => _openNotes(club),
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

class _ClubGlanceCard extends StatelessWidget {
  const _ClubGlanceCard({required this.club, required this.onTap});

  final Club club;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final note = club.swingNotes.trim();
    final scheme = Theme.of(context).colorScheme;
    return Card(
      key: ValueKey('bag-club-card-${club.id}'),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(club.name, style: Theme.of(context).textTheme.headlineSmall),
                  ),
                  Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _StatCol(label: 'MIN', yards: club.minDistance),
                  _StatCol(label: 'AVG', yards: club.avgDistance),
                  _StatCol(label: 'MAX', yards: club.maxDistance),
                ],
              ),
              if (club.minDistance == 0 && club.avgDistance == 0 && club.maxDistance == 0) ...[
                const SizedBox(height: 8),
                Text('No distances yet', style: Theme.of(context).textTheme.bodySmall),
              ],
              const SizedBox(height: 8),
              Text(
                note.isEmpty ? 'Add swing note' : note,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: note.isEmpty ? scheme.onSurfaceVariant : scheme.onSurface,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCol extends StatelessWidget {
  const _StatCol({required this.label, required this.yards});

  final String label;
  final double yards;

  @override
  Widget build(BuildContext context) {
    final value = yards == 0 ? '—' : '${yards.round()}';
    return Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: 2),
        Text(value, style: GolfTextStyles.yardage(context, fontSize: 20)),
        Text('yds', style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}

class _NotesSheet extends StatefulWidget {
  const _NotesSheet({required this.club});

  final Club club;

  @override
  State<_NotesSheet> createState() => _NotesSheetState();
}

class _NotesSheetState extends State<_NotesSheet> {
  late final TextEditingController _controller = TextEditingController(text: widget.club.swingNotes);
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await LocalDatabaseService.instance.updateClubSwingNotes(widget.club.id, _controller.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved swing notes for ${widget.club.name}')),
      );
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Couldn’t save notes for ${widget.club.name}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.club.name, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            TextField(
              key: ValueKey('bag-notes-field-${widget.club.id}'),
              controller: _controller,
              minLines: 3,
              maxLines: 6,
              decoration: const InputDecoration(labelText: 'Swing notes'),
            ),
            const SizedBox(height: 16),
            FilledButton(
              key: ValueKey('bag-save-notes-btn-${widget.club.id}'),
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Saving…' : 'Save notes'),
            ),
          ],
        ),
      ),
    );
  }
}
