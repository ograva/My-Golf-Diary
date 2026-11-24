import 'package:shared_preferences/shared_preferences.dart';

import 'swing_diary_prompt.dart';

/// Device-only swing diary coach choice. Kept out of SQLite and sync.
class CoachPersonaStore {
  const CoachPersonaStore();

  static const _key = 'swing_diary_coach_persona';

  Future<CoachPersona> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return CoachPersona.fromId(prefs.getString(_key));
    } catch (_) {
      return CoachPersona.defaultPersona;
    }
  }

  Future<void> save(CoachPersona persona) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, persona.id);
  }
}
