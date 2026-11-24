import 'package:flutter/material.dart';

import '../models/diary_context_note.dart';
import '../models/golfer_profile.dart';
import '../services/account_auth_controller.dart';
import '../services/diary_model.dart';
import '../services/golfer_profile_service.dart';
import '../services/local_database_service.dart';
import '../services/swing_diary_service.dart';
import 'diary_markdown_body.dart';
import 'golf_ball_loader.dart';
import 'golfer_avatar_circle.dart';
import 'golfer_baseline_sheet.dart';

/// Opt-in swing diary. The model is only called after Continue, and only
/// when [diary] reports that Vertex is available.
class SwingDiarySheet extends StatefulWidget {
  const SwingDiarySheet({
    super.key,
    required this.diary,
    required this.store,
    this.entrySource,
  });

  final DiaryModel diary;
  final SwingDiaryService store;

  /// Tab that opened the diary. The thread is shared; callers still name the source.
  final DiaryContextSource? entrySource;

  @override
  State<SwingDiarySheet> createState() => _SwingDiarySheetState();
}

class _SwingDiarySheetState extends State<SwingDiarySheet> {
  final _composer = TextEditingController();
  var _loading = true;
  var _optedIn = false;
  var _showLog = false;
  var _busy = false;
  String? _errorMessage;
  String _draft = '';
  String? _pendingQuestion;
  DiaryCancel? _cancel;
  List<DiaryMessage> _messages = const [];
  List<RangeEvaluation> _evaluations = const [];
  GolferProfile _profile = const GolferProfile();
  var _clubsMissingSpecs = false;
  var _baselineUpdated = false;
  String? _baselineSummary;

  @override
  void initState() {
    super.initState();
    _composer.addListener(() {
      if (mounted) setState(() {});
    });
    _load();
  }

  @override
  void dispose() {
    _cancel?.cancel();
    _composer.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final optedIn = await widget.store.isOptedIn();
    final profile = await LocalDatabaseService.instance.getGolferProfile();
    final clubs = await LocalDatabaseService.instance.getAllClubs();
    final messages = await widget.store.listMessages();
    final evaluations = await widget.store.listEvaluations();
    if (!mounted) return;
    setState(() {
      _optedIn = optedIn;
      _messages = messages;
      _evaluations = evaluations;
      _profile = profile;
      _clubsMissingSpecs = clubsMissingEquipmentSpecs(clubs);
      _loading = false;
    });
  }

  Future<void> _continue() async {
    await widget.store.setOptedIn(true);
    if (!mounted) return;
    setState(() => _optedIn = true);
  }

  Future<void> _send(String text) async {
    final question = text.trim();
    if (!widget.diary.available || _busy || question.isEmpty) return;
    final cancel = DiaryCancel();
    _cancel = cancel;
    _pendingQuestion = question;
    setState(() {
      _busy = true;
      _draft = '';
      _errorMessage = null;
    });
    try {
      final plan = await widget.store.preparePrompt(question: question);
      if (cancel.isCancelled) throw const DiaryCancelled();
      if (!mounted) return;
      final buffer = StringBuffer();
      await for (final chunk in widget.diary.generate(
        plan.prompt,
        systemInstruction: plan.systemInstruction,
        cancel: cancel,
      )) {
        if (cancel.isCancelled) throw const DiaryCancelled();
        buffer.write(chunk);
        if (!mounted) return;
        setState(() => _draft = buffer.toString());
      }
      if (cancel.isCancelled) throw const DiaryCancelled();
      if (!mounted) return;
      final sessionId = await widget.store.latestTodaySessionId();
      await widget.store.ask(
        prompt: plan.prompt,
        promptTokens: plan.tokens,
        reply: buffer.toString(),
        userText: question,
        sessionId: sessionId,
      );
      DistillResult? distilled;
      try {
        distilled =
            await GolferProfileService(model: widget.diary).distillIfNeeded();
      } catch (_) {
        distilled = null;
      }
      if (!mounted) return;
      setState(() {
        _draft = '';
        _errorMessage = null;
        _baselineUpdated = distilled?.changed == true;
        _baselineSummary = distilled?.changed == true
            ? (distilled!.summary.isEmpty
                ? 'Baseline updated'
                : distilled.summary)
            : null;
      });
      _composer.clear();
      await _load();
    } on DiaryCancelled {
      if (!mounted) return;
      setState(() => _draft = '');
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = "Couldn't get a reply.";
        _draft = '';
      });
    } finally {
      _cancel = null;
      if (mounted) setState(() => _busy = false);
    }
  }

  void _applyLeadIn(LeadInPrompt prompt) {
    final current = _composer.text.trim();
    if (!current.contains(prompt.prefix)) {
      _composer.text =
          current.isEmpty ? prompt.prefix : '$current\n${prompt.prefix}';
    }
  }

  Future<void> _dismissLeadIn(LeadInPrompt prompt) async {
    await LocalDatabaseService.instance.saveGolferProfile(
      _profile.copyWith(
        dismissedPrompts: {..._profile.dismissedPrompts, prompt.id}.toList(),
      ),
    );
    await _load();
  }

  Future<void> _openBaseline() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => GolferBaselineSheet(
        profile: _profile,
        diary: widget.diary,
      ),
    );
    if (!mounted) return;
    await _load();
  }

  Widget _chatBox(bool available) {
    final canSend =
        _optedIn && available && !_busy && _composer.text.trim().isNotEmpty;
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              key: const ValueKey('diary-composer-field'),
              restorationId: widget.entrySource?.storageValue,
              controller: _composer,
              enabled: !_busy,
              minLines: 1,
              maxLines: 6,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              decoration: const InputDecoration(
                hintText: 'How did your body feel?',
                border: InputBorder.none,
                isCollapsed: true,
                contentPadding: EdgeInsets.fromLTRB(16, 14, 8, 14),
              ),
            ),
          ),
          IconButton(
            key: const ValueKey('diary-send-btn'),
            tooltip: _busy ? 'Waiting for a reply' : 'Send',
            style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
            onPressed: canSend ? () => _send(_composer.text) : null,
            icon: _busy
                ? const GolfBallLoader(
                    key: ValueKey('diary-send-busy'),
                    size: 28,
                  )
                : const Icon(Icons.arrow_upward),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final available = widget.diary.available;
    final height = MediaQuery.sizeOf(context).height * 0.85;
    final failed = _errorMessage != null && !_busy;
    final leadIns = leadInPrompts(
      _profile,
      clubsMissingSpecs: _clubsMissingSpecs,
    );
    return SafeArea(
      child: SizedBox(
        height: height,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Swing diary',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Expanded(
                child: _loading
                    ? const Text('Loading diary')
                    : _showLog
                        ? _EvaluationLog(
                            evaluations: _evaluations,
                            onClose: () => setState(() => _showLog = false),
                          )
                        : ListView(
                            children: [
                              if (!_optedIn) ...[
                                const Text(
                                  'When you evaluate or ask a question, Golf Diary may send your '
                                  'range logs, on-course notes, scorecard reflections, club yardages, '
                                  'and swing notes to Google Vertex AI. No API key is stored on this phone.',
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 8,
                                  children: [
                                    OutlinedButton(
                                      key: const ValueKey(
                                          'diary-opt-in-dismiss'),
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Not now'),
                                    ),
                                    ElevatedButton(
                                      key: const ValueKey(
                                          'diary-opt-in-continue'),
                                      onPressed: _continue,
                                      child: const Text('Continue'),
                                    ),
                                  ],
                                ),
                              ],
                              if (!available)
                                const Padding(
                                  padding: EdgeInsets.only(top: 12),
                                  child: Text(
                                    'Your practice and round logs stay on this phone. '
                                    'Connect to the internet to run Vertex AI evaluation.',
                                    key: ValueKey('diary-offline-copy'),
                                  ),
                                ),
                              const SizedBox(height: 12),
                              for (final message in _messages)
                                ListTile(
                                  key: ValueKey('diary-message-${message.id}'),
                                  leading: message.role == 'model'
                                      ? null
                                      : GolferAvatarCircle(
                                          session: AccountAuthController
                                              .instance.session,
                                          profile: _profile,
                                          radius: 16,
                                        ),
                                  title: Text(message.role == 'model'
                                      ? 'Evaluation'
                                      : 'You'),
                                  subtitle: message.role == 'model'
                                      ? DiaryMarkdownBody(data: message.content)
                                      : Text(message.content),
                                ),
                              if (_optedIn) ...[
                                if (_draft.isNotEmpty)
                                  ListTile(
                                    key: const ValueKey('diary-eval-draft'),
                                    title: const Text('Evaluation'),
                                    subtitle: DiaryMarkdownBody(data: _draft),
                                  ),
                                if (_baselineUpdated) ...[
                                  Text(
                                    _baselineSummary ?? 'Baseline updated',
                                    key: const ValueKey(
                                        'diary-baseline-updated'),
                                  ),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: TextButton(
                                      key: const ValueKey(
                                          'diary-baseline-review'),
                                      onPressed: _openBaseline,
                                      child: const Text('Review'),
                                    ),
                                  ),
                                ],
                                for (final prompt in leadIns)
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Align(
                                          alignment: Alignment.centerLeft,
                                          child: ActionChip(
                                            key: ValueKey(
                                                'diary-lead-in-chip-${prompt.id}'),
                                            label: Text(prompt.label),
                                            onPressed: _busy
                                                ? null
                                                : () => _applyLeadIn(prompt),
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        key: ValueKey(
                                            'diary-lead-in-dismiss-${prompt.id}'),
                                        tooltip: 'Dismiss',
                                        onPressed: _busy
                                            ? null
                                            : () => _dismissLeadIn(prompt),
                                        icon: const Icon(Icons.close, size: 18),
                                      ),
                                    ],
                                  ),
                                Wrap(
                                  spacing: 8,
                                  children: [
                                    TextButton(
                                      key: const ValueKey('diary-baseline-btn'),
                                      onPressed: _openBaseline,
                                      child: Text(_profile.baselineLabel),
                                    ),
                                    TextButton(
                                      key: const ValueKey(
                                          'diary-evaluation-log-btn'),
                                      onPressed: () =>
                                          setState(() => _showLog = true),
                                      child: const Text('Evaluation log'),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
              ),
              if (failed) ...[
                const SizedBox(height: 8),
                const Text(
                  "Couldn't get a reply.",
                  key: ValueKey('diary-eval-status'),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    key: const ValueKey('diary-eval-retry'),
                    onPressed: () => _send(_pendingQuestion ?? ''),
                    child: const Text('Try again'),
                  ),
                ),
              ],
              if (_busy)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    key: const ValueKey('diary-eval-cancel'),
                    onPressed: () => _cancel?.cancel(),
                    child: const Text('Cancel'),
                  ),
                ),
              const SizedBox(height: 8),
              _chatBox(available),
            ],
          ),
        ),
      ),
    );
  }
}

class _EvaluationLog extends StatelessWidget {
  const _EvaluationLog({required this.evaluations, required this.onClose});

  final List<RangeEvaluation> evaluations;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const ValueKey('diary-evaluation-log'),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(onPressed: onClose, child: const Text('Back')),
        ),
        if (evaluations.isEmpty)
          const Text('No evaluations yet.')
        else
          for (final row in evaluations)
            ListTile(
              key: ValueKey('diary-evaluation-row-${row.id}'),
              title: Text(row.kind == 'periodic_summary'
                  ? 'Progress brief'
                  : 'Evaluation ${row.sessionDate ?? ''}'),
              subtitle: DiaryMarkdownBody(data: row.content),
            ),
      ],
    );
  }
}
