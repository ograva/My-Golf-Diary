import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/golfer_profile.dart';
import '../services/diary_model.dart';
import '../services/golfer_profile_store.dart';
import '../services/local_database_service.dart';
import '../services/vertex_diary_model.dart';
import '../widgets/golfer_baseline_sheet.dart';

/// Settings surface for demographics, skill tier, yardage mode, and baseline.
class GolferProfileSettingsScreen extends StatefulWidget {
  const GolferProfileSettingsScreen({
    super.key,
    this.diary,
    this.initialProfile,
  });

  final DiaryModel? diary;
  final GolferProfile? initialProfile;

  @override
  State<GolferProfileSettingsScreen> createState() =>
      _GolferProfileSettingsScreenState();
}

class _GolferProfileSettingsScreenState
    extends State<GolferProfileSettingsScreen> {
  late final TextEditingController _ageController;
  late final TextEditingController _yearsController;
  late final DiaryModel _diary;

  GolferProfile _base = const GolferProfile();
  String _gender = '';
  String _skillTier = '';
  String _yardageMode = YardageDisplayMode.defaultMode;
  String? _ageError;
  String? _yearsError;
  bool _busy = false;
  String? _status;

  @override
  void initState() {
    super.initState();
    _diary = widget.diary ?? VertexDiaryModel();
    _ageController = TextEditingController();
    _yearsController = TextEditingController();
    final profile = widget.initialProfile;
    if (profile != null) {
      _hydrateFrom(profile);
    } else {
      _loadFromDb();
    }
  }

  void _hydrateFrom(GolferProfile profile) {
    _base = profile;
    _ageController.text = profile.age?.toString() ?? '';
    _yearsController.text = profile.yearsPlaying?.toString() ?? '';
    _gender = profile.gender;
    _skillTier = profile.skillTier;
    _yardageMode = profile.yardageDisplayMode.trim().isEmpty
        ? YardageDisplayMode.defaultMode
        : profile.yardageDisplayMode;
  }

  Future<void> _loadFromDb() async {
    final profile = await LocalDatabaseService.instance.getGolferProfile();
    if (!mounted) return;
    setState(() => _hydrateFrom(profile));
  }

  @override
  void dispose() {
    _ageController.dispose();
    _yearsController.dispose();
    super.dispose();
  }

  GolferProfile _draft() {
    return _base.copyWith(
      age: parseOnboardingAge(_ageController.text),
      clearAge: parseOnboardingAge(_ageController.text) == null &&
          _ageController.text.trim().isEmpty,
      yearsPlaying: parseOnboardingYears(_yearsController.text),
      clearYearsPlaying: parseOnboardingYears(_yearsController.text) == null &&
          _yearsController.text.trim().isEmpty,
      gender: _gender,
      skillTier: _skillTier,
      yardageDisplayMode: _yardageMode,
    );
  }

  bool _validateDemographics() {
    _ageError = validateOnboardingAge(_ageController.text);
    _yearsError = validateOnboardingYears(_yearsController.text);
    setState(() {});
    return _ageError == null && _yearsError == null;
  }

  Future<void> _save() async {
    if (!_validateDemographics()) return;
    if (_skillTier.isEmpty) {
      setState(() => _status = 'Pick a skill tier');
      return;
    }
    setState(() {
      _busy = true;
      _status = null;
    });
    try {
      final next = _draft();
      await LocalDatabaseService.instance.saveGolferProfile(next);
      if (!mounted) return;
      GolferProfileScope.maybeOf(context)?.refresh();
      setState(() {
        _base = next;
        _status = 'Profile saved';
      });
      Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openBaseline() async {
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => GolferBaselineSheet(
        profile: _draft(),
        diary: _diary,
      ),
    );
    final fresh = await LocalDatabaseService.instance.getGolferProfile();
    if (!mounted) return;
    setState(() {
      _base = _base.copyWith(
        equipmentNotes: fresh.equipmentNotes,
        swingAnchors: fresh.swingAnchors,
        physicalConstraints: fresh.physicalConstraints,
        trainingEnvironment: fresh.trainingEnvironment,
        dismissedPrompts: fresh.dismissedPrompts,
        distilledThroughMs: fresh.distilledThroughMs,
      );
    });
    GolferProfileScope.maybeOf(context)?.refresh();
  }

  Future<void> _resetOnboarding() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset onboarding?'),
        content: const Text(
          'The setup wizard will run again the next time you open the app. '
          'Your saved data stays on this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    try {
      final next = _draft().copyWith(onboardingCompleted: 0);
      await LocalDatabaseService.instance.saveGolferProfile(next);
      if (!mounted) return;
      GolferProfileScope.maybeOf(context)?.refresh();
      setState(() => _status = 'Onboarding will restart on next launch');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Golfer profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('About you', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Used to tailor AI coaching — not to change neutral app labels.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _ageController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: 'Age',
              errorText: _ageError,
            ),
            onChanged: (_) => setState(() => _ageError = null),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _yearsController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: 'Years playing',
              errorText: _yearsError,
            ),
            onChanged: (_) => setState(() => _yearsError = null),
          ),
          const SizedBox(height: 16),
          Text('Gender', style: theme.textTheme.titleSmall),
          ...GolferGender.values.map(
            (value) => RadioListTile<String>(
              value: value,
              groupValue: _gender.isEmpty ? null : _gender,
              onChanged: (next) {
                if (next != null) setState(() => _gender = next);
              },
              title: Text(GolferGender.label(value)),
            ),
          ),
          const Divider(height: 32),
          Text('Skill tier', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          ...GolferSkillTier.values.map(
            (tier) => RadioListTile<String>(
              key: ValueKey('profile-skill-tier-$tier'),
              value: tier,
              groupValue: _skillTier.isEmpty ? null : _skillTier,
              onChanged: (next) {
                if (next != null) setState(() => _skillTier = next);
              },
              title: Text(GolferSkillTier.label(tier)),
              subtitle: Text(GolferSkillTier.blurb(tier)),
            ),
          ),
          const Divider(height: 32),
          Text('Yardage display', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Controls how many numbers you see on My Bag and Range.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          ...YardageDisplayMode.values.map(
            (mode) => RadioListTile<String>(
              key: ValueKey('profile-yardage-display-$mode'),
              value: mode,
              groupValue: _yardageMode,
              onChanged: (next) {
                if (next != null) setState(() => _yardageMode = next);
              },
              title: Text(YardageDisplayMode.label(mode)),
              subtitle: Text(YardageDisplayMode.blurb(mode)),
            ),
          ),
          const Divider(height: 32),
          Text('Coaching baseline', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Equipment, swing, body, and training notes for the swing diary.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: _busy ? null : _openBaseline,
            child: Text(_base.baselineLabel),
          ),
          const Divider(height: 32),
          OutlinedButton(
            key: const ValueKey('profile-reset-onboarding-btn'),
            onPressed: _busy ? null : _resetOnboarding,
            child: const Text('Reset onboarding wizard'),
          ),
          if (_status != null) ...[
            const SizedBox(height: 12),
            Text(_status!, style: theme.textTheme.bodySmall),
          ],
          const SizedBox(height: 24),
          FilledButton(
            key: const ValueKey('profile-save-btn'),
            onPressed: _busy ? null : _save,
            child: _busy
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save profile'),
          ),
        ],
      ),
    );
  }
}