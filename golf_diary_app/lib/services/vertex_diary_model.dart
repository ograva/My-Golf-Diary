import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_core/firebase_core.dart';

import 'diary_model.dart';

/// Vertex entry point for the swing diary.
///
/// `firebase_ai` 5 renamed `FirebaseAI.vertexAI()` to
/// [FirebaseAI.agentPlatform]. This is that Vertex client. It is not
/// `FirebaseAI.googleAI()`, and it does not read a Gemini API key.
class VertexDiaryModel implements DiaryModel {
  @override
  bool get available => Firebase.apps.isNotEmpty;

  @override
  Future<String> generate(String prompt) async {
    final model = FirebaseAI.agentPlatform().generativeModel(
      model: 'gemini-2.5-flash',
    );
    final response = await model.generateContent([Content.text(prompt)]);
    return response.text ?? '';
  }
}
