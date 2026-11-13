/// A swing-diary model call. Tests pass a fake. The app uses Vertex.
abstract class DiaryModel {
  bool get available;

  /// Model id sent to Vertex. Shown in the temporary debug line.
  String get modelName;

  /// Vertex location. Shown in the temporary debug line.
  String get location;

  /// Yields each text chunk as it arrives. A cancel ends the stream with
  /// [DiaryCancelled] and must not be treated as a finished reply.
  Stream<String> generate(
    String prompt, {
    String? systemInstruction,
    DiaryCancel? cancel,
  });
}

/// Stops an in-flight [DiaryModel.generate] call.
class DiaryCancel {
  bool _cancelled = false;
  void Function()? _abort;

  bool get isCancelled => _cancelled;

  /// Runs [abort] immediately when this call is already cancelled.
  void bindAbort(void Function() abort) {
    _abort = abort;
    if (_cancelled) abort();
  }

  void cancel() {
    if (_cancelled) return;
    _cancelled = true;
    _abort?.call();
  }
}

/// The golfer cancelled the evaluation. Nothing should be saved.
class DiaryCancelled implements Exception {
  const DiaryCancelled();

  @override
  String toString() => 'DiaryCancelled';
}
