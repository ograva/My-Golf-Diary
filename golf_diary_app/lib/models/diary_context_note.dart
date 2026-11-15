/// Local diary notes from Range, On Course, or Scorecard (not synced).
enum DiaryContextSource {
  range,
  onCourse,
  scorecard,
  diary,
}

extension DiaryContextSourceLabels on DiaryContextSource {
  String get storageValue => switch (this) {
        DiaryContextSource.range => 'range',
        DiaryContextSource.onCourse => 'on_course',
        DiaryContextSource.scorecard => 'scorecard',
        DiaryContextSource.diary => 'diary',
      };

  String get promptLabel => switch (this) {
        DiaryContextSource.range => 'Range',
        DiaryContextSource.onCourse => 'On course',
        DiaryContextSource.scorecard => 'Scorecard',
        DiaryContextSource.diary => 'Diary',
      };

  static DiaryContextSource fromStorage(String value) => switch (value) {
        'range' => DiaryContextSource.range,
        'on_course' => DiaryContextSource.onCourse,
        'scorecard' => DiaryContextSource.scorecard,
        'diary' => DiaryContextSource.diary,
        _ => DiaryContextSource.diary,
      };
}

class DiaryContextNote {
  const DiaryContextNote({
    required this.id,
    required this.source,
    required this.content,
    required this.contextDate,
    required this.timestamp,
    this.roundId,
  });

  final String id;
  final DiaryContextSource source;
  final String content;
  final String contextDate;
  final int timestamp;
  final String? roundId;
}