import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:http/http.dart' as http;

import 'diary_model.dart';

/// Vertex entry point for the swing diary.
///
/// `firebase_ai` 5 renamed `FirebaseAI.vertexAI()` to
/// [FirebaseAI.agentPlatform]. This is that Vertex client. It is not
/// `FirebaseAI.googleAI()`, and it does not read a Gemini API key.
class VertexDiaryModel implements DiaryModel {
  static const String modelId = 'gemini-3.8-flash';
  static const String defaultLocation = 'global';

  @override
  bool get available => Firebase.apps.isNotEmpty;

  @override
  String get modelName => modelId;

  @override
  String get location => defaultLocation;

  @override
  Stream<String> generate(
    String prompt, {
    String? systemInstruction,
    DiaryCancel? cancel,
  }) async* {
    final client = http.Client();
    var closed = false;
    void abort() {
      if (closed) return;
      closed = true;
      client.close();
    }

    cancel?.bindAbort(abort);
    try {
      if (cancel?.isCancelled == true) throw const DiaryCancelled();
      final trimmedSystem = systemInstruction?.trim() ?? '';
      final model =
          FirebaseAI.agentPlatform(location: location).generativeModel(
        model: modelName,
        systemInstruction:
            trimmedSystem.isEmpty ? null : Content.system(trimmedSystem),
        httpClient: client,
      );
      await for (final response
          in model.generateContentStream([Content.text(prompt)])) {
        if (cancel?.isCancelled == true) throw const DiaryCancelled();
        final text = response.text ?? '';
        if (text.isEmpty) continue;
        yield text;
      }
      if (cancel?.isCancelled == true) throw const DiaryCancelled();
    } on DiaryCancelled {
      rethrow;
    } catch (error) {
      if (cancel?.isCancelled == true) throw const DiaryCancelled();
      rethrow;
    } finally {
      abort();
    }
  }

  @override
  Future<String?> generateJson({
    required String prompt,
    required String systemInstruction,
    Schema? responseSchema,
    DiaryCancel? cancel,
  }) async {
    final client = http.Client();
    var closed = false;
    void abort() {
      if (closed) return;
      closed = true;
      client.close();
    }

    cancel?.bindAbort(abort);
    try {
      if (cancel?.isCancelled == true) throw const DiaryCancelled();
      final trimmedSystem = systemInstruction.trim();
      final model =
          FirebaseAI.agentPlatform(location: location).generativeModel(
        model: modelName,
        systemInstruction:
            trimmedSystem.isEmpty ? null : Content.system(trimmedSystem),
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
          responseSchema: responseSchema,
        ),
        httpClient: client,
      );
      final response = await model.generateContent([Content.text(prompt)]);
      if (cancel?.isCancelled == true) throw const DiaryCancelled();
      final text = response.text?.trim();
      if (text == null || text.isEmpty) return null;
      return text;
    } on DiaryCancelled {
      rethrow;
    } catch (error) {
      if (cancel?.isCancelled == true) throw const DiaryCancelled();
      rethrow;
    } finally {
      abort();
    }
  }
}
