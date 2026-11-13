import 'dart:convert';

import 'golf_models.dart';

/// Durable coaching baseline for one local golfer. A single SQLite row.
class GolferProfile {
  const GolferProfile({
    this.equipmentNotes = '',
    this.swingAnchors = '',
    this.physicalConstraints = '',
    this.trainingEnvironment = '',
    this.dismissedPrompts = const [],
    this.distilledThroughMs = 0,
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
  final int isSynced;
  final int updatedAtMs;

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
      isSynced: map['is_synced'] as int? ?? 0,
      updatedAtMs: map['updated_at_ms'] as int? ?? 0,
    );
  }
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
