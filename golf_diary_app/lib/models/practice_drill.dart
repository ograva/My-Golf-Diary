import 'dart:convert';

class PracticeDrill {
  const PracticeDrill({
    required this.id,
    required this.title,
    required this.category,
    required this.shortDescription,
    required this.steps,
    this.recommendedClubs = '',
    this.isCustom = false,
    this.updatedAtMs = 0,
  });

  final String id;
  final String title;
  final String category;
  final String shortDescription;
  final List<String> steps;
  final String recommendedClubs;
  final bool isCustom;
  final int updatedAtMs;

  factory PracticeDrill.fromMap(Map<String, Object?> map) {
    final rawSteps = map['steps_json'] as String? ?? '[]';
    final decoded = jsonDecode(rawSteps);
    final steps = decoded is List
        ? [for (final step in decoded) step.toString()]
        : <String>[];
    return PracticeDrill(
      id: map['id'] as String,
      title: map['title'] as String,
      category: map['category'] as String,
      shortDescription: map['short_description'] as String? ?? '',
      steps: steps,
      recommendedClubs: map['recommended_clubs'] as String? ?? '',
      isCustom: (map['is_custom'] as int? ?? 0) == 1,
      updatedAtMs: map['updated_at_ms'] as int? ?? 0,
    );
  }
}
