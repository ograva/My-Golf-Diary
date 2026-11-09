import 'package:flutter/material.dart';

import '../models/practice_drill.dart';
import '../services/local_database_service.dart';

/// A drill chosen from the sheet. [copyTitleToNote] is set when the
/// golfer taps the title, which also fills the Range swing note.
class PracticeDrillPick {
  const PracticeDrillPick(this.drill, {this.copyTitleToNote = false});

  final PracticeDrill drill;
  final bool copyTitleToNote;
}

String practiceDrillChipKey(String category) {
  final slug = category
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  return 'range-drills-chip-$slug';
}

/// Practice-drill list opened from the Range header.
class PracticeDrillSheet extends StatefulWidget {
  const PracticeDrillSheet({super.key});

  @override
  State<PracticeDrillSheet> createState() => _PracticeDrillSheetState();
}

class _PracticeDrillSheetState extends State<PracticeDrillSheet> {
  List<PracticeDrill> _drills = [];
  String _category = 'All';
  String? _expandedId;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final drills = await LocalDatabaseService.instance.listPracticeDrills();
    if (!mounted) return;
    setState(() {
      _drills = drills;
      _loading = false;
      if (_expandedId != null &&
          drills.every((drill) => drill.id != _expandedId)) {
        _expandedId = null;
      }
    });
  }

  List<String> get _categories {
    final names = _drills.map((drill) => drill.category).toSet().toList()
      ..sort();
    return ['All', ...names];
  }

  List<PracticeDrill> get _visible {
    if (_category == 'All') return _drills;
    return _drills.where((drill) => drill.category == _category).toList();
  }

  Future<void> _add() async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => const PracticeDrillForm(),
    );
    if (saved == true) await _reload();
  }

  Future<void> _delete(PracticeDrill drill) async {
    final remove = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove this drill?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Remove')),
        ],
      ),
    );
    if (remove != true) return;
    await LocalDatabaseService.instance.deletePracticeDrill(drill.id);
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height * 0.85;
    final visible = _visible;
    return SafeArea(
      child: SizedBox(
        key: const ValueKey('range-drills-sheet'),
        height: height,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 8, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text('Practice drills',
                        style: Theme.of(context).textTheme.titleLarge),
                  ),
                  IconButton(
                    key: const ValueKey('range-drill-add-btn'),
                    tooltip: 'Add drill',
                    onPressed: _add,
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 48,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    for (final category in _categories)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          key: ValueKey(practiceDrillChipKey(category)),
                          label: Text(category),
                          selected: _category == category,
                          onSelected: (_) => setState(() {
                            _category = category;
                            _expandedId = null;
                          }),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : visible.isEmpty
                      ? const Center(
                          child: Text('No drills in this list. Add one.'))
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                          itemCount: visible.length,
                          itemBuilder: (context, index) {
                            final drill = visible[index];
                            final open = _expandedId == drill.id;
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: InkWell(
                                key: ValueKey('range-drill-row-${drill.id}'),
                                onTap: () => setState(
                                    () => _expandedId = open ? null : drill.id),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      InkWell(
                                        key: ValueKey(
                                            'range-drill-title-${drill.id}'),
                                        onTap: () => Navigator.pop(
                                          context,
                                          PracticeDrillPick(drill,
                                              copyTitleToNote: true),
                                        ),
                                        child: Text(drill.title,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium),
                                      ),
                                      Text(drill.category,
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelMedium),
                                      Text(drill.shortDescription),
                                      if (open) ...[
                                        const SizedBox(height: 8),
                                        for (var i = 0;
                                            i < drill.steps.length;
                                            i++)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                bottom: 4),
                                            child: Text(
                                                '${i + 1}. ${drill.steps[i]}'),
                                          ),
                                        const SizedBox(height: 8),
                                        FilledButton(
                                          key: const ValueKey(
                                              'range-drill-use-btn'),
                                          onPressed: () => Navigator.pop(
                                              context,
                                              PracticeDrillPick(drill)),
                                          child: const Text('Use this drill'),
                                        ),
                                        TextButton(
                                          key: const ValueKey(
                                              'range-drill-delete-btn'),
                                          onPressed: () => _delete(drill),
                                          child: const Text('Delete'),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class PracticeDrillForm extends StatefulWidget {
  const PracticeDrillForm({super.key});

  @override
  State<PracticeDrillForm> createState() => _PracticeDrillFormState();
}

class _PracticeDrillFormState extends State<PracticeDrillForm> {
  final _title = TextEditingController();
  final _category = TextEditingController();
  final _description = TextEditingController();
  final _steps = <TextEditingController>[TextEditingController()];
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _category.dispose();
    _description.dispose();
    for (final step in _steps) {
      step.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final steps = [for (final step in _steps) step.text.trim()]
        .where((step) => step.isNotEmpty)
        .toList();
    if (_title.text.trim().isEmpty || steps.isEmpty) {
      setState(() => _error = 'Add a title and at least one step.');
      return;
    }
    await LocalDatabaseService.instance.insertPracticeDrill(
      title: _title.text,
      category: _category.text,
      shortDescription: _description.text,
      steps: steps,
    );
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottom),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Add a drill', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            TextField(
                controller: _title,
                decoration: const InputDecoration(labelText: 'Title')),
            TextField(
                controller: _category,
                decoration: const InputDecoration(labelText: 'Category')),
            TextField(
              controller: _description,
              decoration: const InputDecoration(labelText: 'Short description'),
            ),
            const SizedBox(height: 8),
            for (var i = 0; i < _steps.length; i++)
              TextField(
                controller: _steps[i],
                decoration: InputDecoration(labelText: 'Step ${i + 1}'),
              ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () =>
                    setState(() => _steps.add(TextEditingController())),
                child: const Text('Add step'),
              ),
            ),
            if (_error != null)
              Text(_error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
            FilledButton(
              key: const ValueKey('range-drill-save-btn'),
              onPressed: _save,
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
