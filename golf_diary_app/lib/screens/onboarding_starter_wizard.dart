import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/golfer_profile.dart';
import '../services/local_database_service.dart';

class OnboardingStarterWizard extends StatefulWidget {
  const OnboardingStarterWizard({
    super.key,
    required this.initialProfile,
    required this.onFinished,
  });

  final GolferProfile initialProfile;
  final VoidCallback onFinished;

  @override
  State<OnboardingStarterWizard> createState() =>
      _OnboardingStarterWizardState();
}

class _OnboardingStarterWizardState extends State<OnboardingStarterWizard> {
  static const _pageCount = 4;

  late final PageController _pageController;
  late final TextEditingController _ageController;
  late final TextEditingController _yearsController;

  int _page = 0;
  String? _ageError;
  String? _yearsError;
  String _gender = '';
  String _skillTier = '';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    final profile = widget.initialProfile;
    _ageController = TextEditingController(
      text: profile.age?.toString() ?? '',
    );
    _yearsController = TextEditingController(
      text: profile.yearsPlaying?.toString() ?? '',
    );
    _gender = profile.gender;
    _skillTier = profile.skillTier;
  }

  @override
  void dispose() {
    _pageController.dispose();
    _ageController.dispose();
    _yearsController.dispose();
    super.dispose();
  }

  GolferProfile _draftProfile({required int onboardingCompleted}) {
    final base = widget.initialProfile;
    return base.copyWith(
      age: parseOnboardingAge(_ageController.text),
      clearAge: parseOnboardingAge(_ageController.text) == null &&
          _ageController.text.trim().isEmpty,
      yearsPlaying: parseOnboardingYears(_yearsController.text),
      clearYearsPlaying: parseOnboardingYears(_yearsController.text) == null &&
          _yearsController.text.trim().isEmpty,
      gender: _gender,
      skillTier: _skillTier,
      onboardingCompleted: onboardingCompleted,
    );
  }

  Future<void> _persist(int onboardingCompleted) async {
    setState(() => _saving = true);
    try {
      await LocalDatabaseService.instance
          .saveGolferProfile(_draftProfile(onboardingCompleted: onboardingCompleted));
      widget.onFinished();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _nextFromDemographics() {
    setState(() {
      if (_page == 0) {
        _ageError = validateOnboardingAge(_ageController.text);
        if (_ageError != null) return;
      }
      if (_page == 1) {
        _yearsError = validateOnboardingYears(_yearsController.text);
        if (_yearsError != null) return;
      }
    });
    if ((_page == 0 && _ageError != null) ||
        (_page == 1 && _yearsError != null)) {
      return;
    }
    _goToPage(_page + 1);
  }

  void _goToPage(int index) {
    if (index < 0 || index >= _pageCount) return;
    setState(() => _page = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  void _onComplete() {
    final ageError = validateOnboardingAge(_ageController.text);
    final yearsError = validateOnboardingYears(_yearsController.text);
    if (_skillTier.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick a skill tier to continue.')),
      );
      return;
    }
    setState(() {
      _ageError = ageError;
      _yearsError = yearsError;
    });
    if (ageError != null) {
      _goToPage(0);
      return;
    }
    if (yearsError != null) {
      _goToPage(1);
      return;
    }
    _persist(1);
  }

  Future<void> _onFinishLater() async {
    await _persist(0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome to Golf Diary'),
        actions: [
          TextButton(
            key: const ValueKey('onboarding-finish-later-btn'),
            onPressed: _saving ? null : _onFinishLater,
            child: const Text('Finish later'),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
              child: Text(
                'Step ${_page + 1} of $_pageCount',
                style: theme.textTheme.labelLarge,
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) => setState(() => _page = index),
                children: [
                  _wrapPage(
                    0,
                    _AgeStep(
                      controller: _ageController,
                      errorText: _ageError,
                      onChanged: (_) =>
                          setState(() => _ageError = null),
                    ),
                  ),
                  _wrapPage(
                    1,
                    _YearsStep(
                      controller: _yearsController,
                      errorText: _yearsError,
                      onChanged: (_) =>
                          setState(() => _yearsError = null),
                    ),
                  ),
                  _wrapPage(
                    2,
                    _GenderStep(
                      selected: _gender,
                      onSelected: (value) => setState(() => _gender = value),
                    ),
                  ),
                  _wrapPage(
                    3,
                    _SkillTierStep(
                      selected: _skillTier,
                      onSelected: (value) => setState(() => _skillTier = value),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: _page < _pageCount - 1
                  ? FilledButton(
                      onPressed: _saving ? null : _nextFromDemographics,
                      child: const Text('Continue'),
                    )
                  : FilledButton(
                      key: const ValueKey('onboarding-complete-btn'),
                      onPressed: _saving ? null : _onComplete,
                      child: _saving
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Complete'),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _wrapPage(int index, Widget child) {
    return KeyedSubtree(
      key: ValueKey('onboarding-wizard-page-$index'),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: child,
      ),
    );
  }
}

class _AgeStep extends StatelessWidget {
  const _AgeStep({
    required this.controller,
    required this.errorText,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String? errorText;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('How old are you?', style: theme.textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(
          'Used only to tailor AI coaching prompts — not to change app labels.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),
        TextField(
          key: const ValueKey('onboarding-age-field'),
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            labelText: 'Age',
            errorText: errorText,
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _YearsStep extends StatelessWidget {
  const _YearsStep({
    required this.controller,
    required this.errorText,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String? errorText;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Years playing golf', style: theme.textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(
          'Helps the swing diary gauge how much context to assume.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),
        TextField(
          key: const ValueKey('onboarding-years-field'),
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            labelText: 'Years playing',
            errorText: errorText,
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _GenderStep extends StatelessWidget {
  const _GenderStep({
    required this.selected,
    required this.onSelected,
  });

  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Gender', style: theme.textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(
          'Optional, but it improves AI baseline prompts. You can skip this step.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        ...GolferGender.values.map(
          (value) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: RadioListTile<String>(
              key: ValueKey('onboarding-gender-$value'),
              value: value,
              groupValue: selected.isEmpty ? null : selected,
              onChanged: (next) {
                if (next != null) onSelected(next);
              },
              title: Text(GolferGender.label(value)),
            ),
          ),
        ),
      ],
    );
  }
}

class _SkillTierStep extends StatelessWidget {
  const _SkillTierStep({
    required this.selected,
    required this.onSelected,
  });

  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Your skill tier', style: theme.textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(
          'Sets how much detail you see in Range and Bag. You can change this later in Settings.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        ...GolferSkillTier.values.map(
          (tier) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: RadioListTile<String>(
              key: ValueKey('onboarding-skill-tier-$tier'),
              value: tier,
              groupValue: selected.isEmpty ? null : selected,
              onChanged: (next) {
                if (next != null) onSelected(next);
              },
              title: Text(GolferSkillTier.label(tier)),
              subtitle: Text(GolferSkillTier.blurb(tier)),
            ),
          ),
        ),
      ],
    );
  }
}