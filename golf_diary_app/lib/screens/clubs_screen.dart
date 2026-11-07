import 'package:flutter/material.dart';

import '../models/golf_models.dart';
import '../services/local_database_service.dart';
import '../theme/app_theme.dart';

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
  final Map<String, TextEditingController> _noteControllers = {};

  @override
  void initState() {
    super.initState();
    reload();
  }

  @override
  void dispose() {
    for (final c in _noteControllers.values) {
      c.dispose();
    }
    super.dispose();
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
      for (final club in clubs) {
        _noteControllers.putIfAbsent(club.id, () => TextEditingController(text: club.swingNotes));
      }
    });
  }

  Future<void> _saveNotes(Club club) async {
    final notes = _noteControllers[club.id]?.text ?? '';
    await LocalDatabaseService.instance.updateClubSwingNotes(club.id, notes);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved swing notes for ${club.name}'), backgroundColor: AppColors.green),
      );
    }
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

  Future<void> _removeClub(Club club) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove club'),
        content: Text('Remove ${club.name} from your bag?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Remove')),
        ],
      ),
    );
    if (confirmed != true) return;
    await LocalDatabaseService.instance.deleteClub(club.id);
    _noteControllers.remove(club.id)?.dispose();
    await reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Bag')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addClub,
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
                final label = cat[0].toUpperCase() + cat.substring(1);
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
                      final controller = _noteControllers[club.id]!;
                      final identity = [club.brand, club.model].where((part) => part.trim().isNotEmpty).join(' · ');
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Expanded(child: Text(club.name, style: Theme.of(context).textTheme.titleLarge)),
                                  IconButton(
                                    tooltip: 'Remove club',
                                    onPressed: () => _removeClub(club),
                                    icon: const Icon(Icons.delete_outline),
                                  ),
                                ],
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
                              TextField(
                                controller: controller,
                                decoration: const InputDecoration(
                                  labelText: 'Swing notes',
                                  border: OutlineInputBorder(),
                                ),
                                minLines: 1,
                                maxLines: 3,
                                onSubmitted: (_) => _saveNotes(club),
                              ),
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () => _saveNotes(club),
                                  child: const Text('Save notes'),
                                ),
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
                  .map((cat) => DropdownMenuItem(value: cat, child: Text(cat[0].toUpperCase() + cat.substring(1))))
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
