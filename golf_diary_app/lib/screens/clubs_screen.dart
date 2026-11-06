import 'package:flutter/material.dart';

import '../models/golf_models.dart';
import '../services/local_database_service.dart';
import '../theme/app_theme.dart';

class ClubsScreen extends StatefulWidget {
  const ClubsScreen({super.key});

  @override
  State<ClubsScreen> createState() => _ClubsScreenState();
}

class _ClubsScreenState extends State<ClubsScreen> {
  static const _categories = ['wood', 'hybrid', 'iron', 'wedge', 'putter'];

  String _selectedCategory = 'wood';
  List<Club> _clubs = [];
  final Map<String, TextEditingController> _noteControllers = {};

  @override
  void initState() {
    super.initState();
    _loadClubs();
  }

  @override
  void dispose() {
    for (final c in _noteControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadClubs() async {
    final clubs = await LocalDatabaseService.instance.getClubsByCategory(_selectedCategory);
    setState(() {
      _clubs = clubs;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Bag')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: _categories.map((cat) {
                final label = cat[0].toUpperCase() + cat.substring(1);
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(label),
                    selected: _selectedCategory == cat,
                    onSelected: (_) {
                      setState(() => _selectedCategory = cat);
                      _loadClubs();
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _clubs.length,
              itemBuilder: (context, index) {
                final club = _clubs[index];
                final controller = _noteControllers[club.id]!;
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                      Text(club.name, style: Theme.of(context).textTheme.titleLarge),
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
