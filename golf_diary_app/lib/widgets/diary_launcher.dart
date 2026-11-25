import 'package:flutter/material.dart';

import '../models/diary_context_note.dart';
import '../services/diary_model.dart';
import '../services/swing_diary_service.dart';
import '../services/vertex_diary_model.dart';
import 'swing_diary_sheet.dart';

/// Opens the shared swing diary sheet above [HomeShell] (modal, not a nav tab).
Future<void> showSwingDiarySheet(
  BuildContext context, {
  DiaryModel? diary,
  SwingDiaryService? store,
  DiaryContextSource? entrySource,
  String? reviewSessionId,
  bool autoAskReview = false,
}) async {
  final model = diary ?? VertexDiaryModel();
  final diaryStore = store ?? SwingDiaryService();
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => SwingDiarySheet(
      diary: model,
      store: diaryStore,
      entrySource: entrySource,
      reviewSessionId: reviewSessionId,
      autoAskReview: autoAskReview,
    ),
  );
}

/// The one diary write control: a 48dp book icon in the AppBar.
class DiaryEntryButton extends StatelessWidget {
  const DiaryEntryButton({
    super.key,
    required this.entryKey,
    this.diary,
    this.store,
    this.entrySource,
  });

  final String entryKey;
  final DiaryModel? diary;
  final SwingDiaryService? store;
  final DiaryContextSource? entrySource;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      key: ValueKey(entryKey),
      tooltip: 'Swing diary',
      onPressed: () => showSwingDiarySheet(
        context,
        diary: diary,
        store: store,
        entrySource: entrySource,
      ),
      icon: const Icon(Icons.auto_stories_outlined),
      style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
    );
  }
}