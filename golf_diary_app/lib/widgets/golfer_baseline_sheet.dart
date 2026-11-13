import 'package:flutter/material.dart';

import '../models/golfer_profile.dart';
import '../services/diary_model.dart';
import '../services/golfer_profile_service.dart';
import '../services/local_database_service.dart';

/// Offline editor for the four baseline pillars, plus an on-demand distill.
class GolferBaselineSheet extends StatefulWidget {
  const GolferBaselineSheet({
    super.key,
    required this.profile,
    required this.diary,
  });

  final GolferProfile profile;
  final DiaryModel diary;

  @override
  State<GolferBaselineSheet> createState() => _GolferBaselineSheetState();
}

class _GolferBaselineSheetState extends State<GolferBaselineSheet> {
  late final TextEditingController _equipment;
  late final TextEditingController _swing;
  late final TextEditingController _physical;
  late final TextEditingController _training;
  var _busy = false;
  String? _status;

  @override
  void initState() {
    super.initState();
    _equipment = TextEditingController(text: widget.profile.equipmentNotes);
    _swing = TextEditingController(text: widget.profile.swingAnchors);
    _physical = TextEditingController(text: widget.profile.physicalConstraints);
    _training = TextEditingController(text: widget.profile.trainingEnvironment);
  }

  @override
  void dispose() {
    _equipment.dispose();
    _swing.dispose();
    _physical.dispose();
    _training.dispose();
    super.dispose();
  }

  GolferProfile _edited() {
    return widget.profile.copyWith(
      equipmentNotes: _equipment.text.trim(),
      swingAnchors: _swing.text.trim(),
      physicalConstraints: _physical.text.trim(),
      trainingEnvironment: _training.text.trim(),
    );
  }

  Future<void> _save() async {
    await LocalDatabaseService.instance.saveGolferProfile(_edited());
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  Future<void> _restorePrompts() async {
    await LocalDatabaseService.instance.saveGolferProfile(
      _edited().copyWith(dismissedPrompts: const []),
    );
    if (!mounted) return;
    setState(() => _status = 'Lead-in questions restored');
  }

  Future<void> _distill() async {
    setState(() {
      _busy = true;
      _status = 'Reading your notes';
    });
    try {
      await LocalDatabaseService.instance.saveGolferProfile(_edited());
      final result = await GolferProfileService(model: widget.diary).distillIfNeeded();
      if (!mounted) return;
      if (result == null) {
        setState(() => _status = 'No new notes to distill');
        return;
      }
      _equipment.text = result.profile.equipmentNotes;
      _swing.text = result.profile.swingAnchors;
      _physical.text = result.profile.physicalConstraints;
      _training.text = result.profile.trainingEnvironment;
      setState(() {
        _status = result.changed
            ? (result.summary.isEmpty ? 'Baseline updated' : result.summary)
            : 'Baseline already matched your notes';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _status = '$error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height * 0.85;
    return SafeArea(
      child: SizedBox(
        height: height,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: ListView(
            children: [
              Text('Baseline', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              const Text(
                'These notes stay on this device and shape the coach. Edit them any time.',
              ),
              const SizedBox(height: 12),
              TextField(
                key: const ValueKey('baseline-equipment-field'),
                controller: _equipment,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Equipment',
                  hintText: 'Shaft, head, or attack tendencies',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                key: const ValueKey('baseline-swing-field'),
                controller: _swing,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Swing anchors',
                  hintText: 'Tempo, setup, or a feel to keep',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                key: const ValueKey('baseline-physical-field'),
                controller: _physical,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Physical constraints',
                  hintText: 'Joints or fatigue to protect',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                key: const ValueKey('baseline-training-field'),
                controller: _training,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Training environment',
                  hintText: 'Aids, indoor space, mats or turf',
                ),
              ),
              if (_status != null) ...[
                const SizedBox(height: 8),
                Text(_status!, key: const ValueKey('baseline-status')),
              ],
              const SizedBox(height: 12),
              ElevatedButton(
                key: const ValueKey('baseline-save-btn'),
                onPressed: _busy ? null : _save,
                child: const Text('Save baseline'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                key: const ValueKey('baseline-distill-btn'),
                onPressed: widget.diary.available && !_busy ? _distill : null,
                child: const Text('Distill from my notes'),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  key: const ValueKey('baseline-restore-prompts-btn'),
                  onPressed: _busy ? null : _restorePrompts,
                  child: const Text('Show lead-in questions again'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
