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
  static const String modelId = 'gemini-2.5-flash';
  static const String defaultLocation = 'global';

  @override
  bool get available => Firebase.apps.isNotEmpty;

  @override
  String get modelName => modelId;

  @override
  String get location => defaultLocation;

  @override
  Stream<String> generate(String prompt, {DiaryCancel? cancel}) async* {
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
      final model =
          FirebaseAI.agentPlatform(location: location).generativeModel(
        model: modelName,
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
}
