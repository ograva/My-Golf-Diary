/// A swing-diary model call. Tests pass a fake. The app uses Vertex.
abstract class DiaryModel {
  bool get available;

  Future<String> generate(String prompt);
}
