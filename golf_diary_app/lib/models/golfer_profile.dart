import 'dart:convert';

import 'golf_models.dart';

/// Stored in [GolferProfile.skillTier]; drives copy density (MGDV-203).
abstract final class GolferSkillTier {
  static const beginner = 'beginner';
  static const amateur = 'amateur';
  static const seasonedPro = 'seasoned_pro';

  static const List<String> values = [beginner, amateur, seasonedPro];

  static String label(String tier) => switch (tier) {
        beginner => 'Beginner',
        amateur => 'Amateur',
        seasonedPro => 'Seasoned pro',
        _ => tier,
      };

  static String blurb(String tier) => switch (tier) {
        beginner =>
          'New to golf or still building a repeatable swing and bag feel.',
        amateur =>
          'Comfortable on the course; you log practice and want sharper feedback.',
        seasonedPro =>
          'Experienced player; you want concise, numbers-forward coaching.',
        _ => '',
      };
}

/// Gender buckets for AI personalization only — never for UI string swaps.
abstract final class GolferGender {
  static const female = 'female';
  static const male = 'male';
  static const nonBinary = 'non_binary';
  static const preferNotToSay = 'prefer_not_to_say';

  static const List<String> values = [female, male, nonBinary, preferNotToSay];

  static String label(String value) => switch (value) {
        female => 'Female',
        male => 'Male',
        nonBinary => 'Non-binary',
        preferNotToSay => 'Prefer not to say',
        _ => value,
      };
}

/// Durable coaching baseline for one local golfer. A single SQLite row.
class GolferProfile {
  const GolferProfile({
    this.equipmentNotes = '',
    this.swingAnchors = '',
    this.physicalConstraints = '',
    this.trainingEnvironment = '',
    this.dismissedPrompts = const [],
    this.distilledThroughMs = 0,
    this.age,
    this.yearsPlaying,
    this.gender = '',
    this.skillTier = '',
    this.onboardingCompleted = 0,
    this.bagNickname = '',
    this.isSynced = 0,
    this.updatedAtMs = 0,
  });

  static const String rowId = 'primary';

  final String equipmentNotes;
  final String swingAnchors;
  final String physicalConstraints;
  final String trainingEnvironment;
  final List<String> dismissedPrompts;
  final int distilledThroughMs;
  final int? age;
  final int? yearsPlaying;
  final String gender;
  final String skillTier;
  final int onboardingCompleted;
  final String bagNickname;
  final int isSynced;
  final int updatedAtMs;

  bool get hasCompletedOnboarding => onboardingCompleted == 1;

  int get filledCount => [
        equipmentNotes,
        swingAnchors,
        physicalConstraints,
        trainingEnvironment,
      ].where((value) => value.trim().isNotEmpty).length;

  String get baselineLabel =>
      filledCount == 4 ? 'Baseline' : 'Baseline ($filledCount/4)';

  GolferProfile copyWith({
    String? equipmentNotes,
    String? swingAnchors,
    String? physicalConstraints,
    String? trainingEnvironment,
    List<String>? dismissedPrompts,
    int? distilledThroughMs,
    int? age,
    bool clearAge = false,
    int? yearsPlaying,
    bool clearYearsPlaying = false,
    String? gender,
    String? skillTier,
    int? onboardingCompleted,
    String? bagNickname,
    int? isSynced,
    int? updatedAtMs,
  }) {
    return GolferProfile(
      equipmentNotes: equipmentNotes ?? this.equipmentNotes,
      swingAnchors: swingAnchors ?? this.swingAnchors,
      physicalConstraints: physicalConstraints ?? this.physicalConstraints,
      trainingEnvironment: trainingEnvironment ?? this.trainingEnvironment,
      dismissedPrompts: dismissedPrompts ?? this.dismissedPrompts,
      distilledThroughMs: distilledThroughMs ?? this.distilledThroughMs,
      age: clearAge ? null : (age ?? this.age),
      yearsPlaying:
          clearYearsPlaying ? null : (yearsPlaying ?? this.yearsPlaying),
      gender: gender ?? this.gender,
      skillTier: skillTier ?? this.skillTier,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      bagNickname: bagNickname ?? this.bagNickname,
      isSynced: isSynced ?? this.isSynced,
      updatedAtMs: updatedAtMs ?? this.updatedAtMs,
    );
  }

  Map<String, Object?> toMap() => {
        'id': rowId,
        'equipment_notes': equipmentNotes,
        'swing_anchors': swingAnchors,
        'physical_constraints': physicalConstraints,
        'training_environment': trainingEnvironment,
        'dismissed_prompts_json': jsonEncode(dismissedPrompts),
        'distilled_through_ms': distilledThroughMs,
        'age': age,
        'years_playing': yearsPlaying,
        'gender': gender,
        'skill_tier': skillTier,
        'onboarding_completed': onboardingCompleted,
        'bag_nickname': bagNickname,
        'is_synced': isSynced,
        'updated_at_ms': updatedAtMs,
        'deleted': 0,
      };

  factory GolferProfile.fromMap(Map<String, Object?> map) {
    final raw = map['dismissed_prompts_json'] as String? ?? '[]';
    final decoded = jsonDecode(raw);
    return GolferProfile(
      equipmentNotes: map['equipment_notes'] as String? ?? '',
      swingAnchors: map['swing_anchors'] as String? ?? '',
      physicalConstraints: map['physical_constraints'] as String? ?? '',
      trainingEnvironment: map['training_environment'] as String? ?? '',
      dismissedPrompts: decoded is List
          ? [for (final item in decoded) item.toString()]
          : const [],
      distilledThroughMs: map['distilled_through_ms'] as int? ?? 0,
      age: map['age'] as int?,
      yearsPlaying: map['years_playing'] as int?,
      gender: map['gender'] as String? ?? '',
      skillTier: map['skill_tier'] as String? ?? '',
      onboardingCompleted: map['onboarding_completed'] as int? ?? 0,
      bagNickname: map['bag_nickname'] as String? ?? '',
      isSynced: map['is_synced'] as int? ?? 0,
      updatedAtMs: map['updated_at_ms'] as int? ?? 0,
    );
  }
}

/// Validates onboarding age (8–99). Empty input is invalid for Complete.
String? validateOnboardingAge(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return 'Enter your age';
  final value = int.tryParse(trimmed);
  if (value == null) return 'Use a whole number';
  if (value < 8 || value > 99) return 'Use an age between 8 and 99';
  return null;
}

/// Validates years playing (0–80). Empty input is invalid for Complete.
String? validateOnboardingYears(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return 'Enter years playing';
  final value = int.tryParse(trimmed);
  if (value == null) return 'Use a whole number';
  if (value < 0 || value > 80) return 'Use a value between 0 and 80';
  return null;
}

int? parseOnboardingAge(String text) {
  return validateOnboardingAge(text) == null ? int.parse(text.trim()) : null;
}

int? parseOnboardingYears(String text) {
  return validateOnboardingYears(text) == null
      ? int.parse(text.trim())
      : null;
}

/// Optional starter the golfer can drop into a note or the diary composer.
class LeadInPrompt {
  const LeadInPrompt({
    required this.id,
    required this.label,
    required this.prefix,
  });

  final String id;
  final String label;
  final String prefix;
}

/// Up to [limit] unanswered, non-dismissed prompts. Physical safety comes first.
List<LeadInPrompt> leadInPrompts(
  GolferProfile profile, {
  required bool clubsMissingSpecs,
  int limit = 2,
}) {
  final dismissed = profile.dismissedPrompts.toSet();
  final prompts = <LeadInPrompt>[
    if (profile.physicalConstraints.trim().isEmpty)
      const LeadInPrompt(
        id: 'physical',
        label: 'Any soreness or joints to protect? (heels, back, wrists)',
        prefix: 'Body / physio watchout: ',
      ),
    if (profile.swingAnchors.trim().isEmpty)
      const LeadInPrompt(
        id: 'swing',
        label: 'What tempo or swing feel are you anchoring to?',
        prefix: 'Swing anchor: ',
      ),
    if (profile.trainingEnvironment.trim().isEmpty)
      const LeadInPrompt(
        id: 'training',
        label: 'Using any training aids or home practice setup?',
        prefix: 'Training setup: ',
      ),
    if (clubsMissingSpecs && profile.equipmentNotes.trim().isEmpty)
      const LeadInPrompt(
        id: 'equipment',
        label: 'Any shaft or club tendencies to keep in mind?',
        prefix: 'Club note: ',
      ),
  ].where((prompt) => !dismissed.contains(prompt.id));
  return prompts.take(limit).toList();
}

bool clubsMissingEquipmentSpecs(Iterable<Club> clubs) {
  final playable = clubs.where((club) => club.category != 'putter');
  if (playable.isEmpty) return false;
  return playable.any(
    (club) => club.brand.trim().isEmpty && club.model.trim().isEmpty,
  );
}
