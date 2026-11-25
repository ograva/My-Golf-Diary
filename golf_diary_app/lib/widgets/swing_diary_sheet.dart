import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../models/diary_context_note.dart';
import '../models/golfer_profile.dart';
import '../services/account_auth_controller.dart';
import '../services/coach_persona_store.dart';
import '../services/diary_model.dart';
import '../services/golfer_profile_service.dart';
import '../services/local_database_service.dart';
import '../services/swing_diary_service.dart';
import 'diary_markdown_body.dart';
import 'golf_putt_loader.dart';
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
    this.personaStore = const CoachPersonaStore(),
    this.reviewSessionId,
    this.autoAskReview = false,
  });

  final DiaryModel diary;
  final SwingDiaryService store;
  final CoachPersonaStore personaStore;

  /// Tab that opened the diary. The thread is shared; callers still name the source.
  final DiaryContextSource? entrySource;

  /// Saved range session to review. Set when save-and-evaluate opens the sheet.
  final String? reviewSessionId;

  /// Ask the coach about [reviewSessionId] once, after the user post is stored.
  final bool autoAskReview;

  @override
  State<SwingDiarySheet> createState() => _SwingDiarySheetState();
}

class _SwingDiarySheetState extends State<SwingDiarySheet> {
  final _composer = TextEditingController();
  final _threadScroll = ScrollController();
  var _loading = true;
  var _optedIn = false;
  var _showLog = false;
  var _busy = false;
  var _loadingOlder = false;
  var _hasOlder = false;

  /// Follow new rows only while the latest post is already on screen.
  var _stickToBottom = true;
  String? _errorMessage;
  String _draft = '';
  String? _pendingQuestion;
  String? _pendingFocusSessionId;
  var _pendingSkipUserMessage = false;
  var _reviewAskStarted = false;
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
    _threadScroll.dispose();
    super.dispose();
  }

  bool _nearBottom(ScrollMetrics metrics) {
    return metrics.maxScrollExtent <= 0 ||
        metrics.pixels >= metrics.maxScrollExtent - 48;
  }

  void _scheduleFollowBottom() {
    var attempts = 0;
    void tick() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_threadScroll.hasClients || !_stickToBottom) return;
        final position = _threadScroll.position;
        final max = position.maxScrollExtent;
        if ((position.pixels - max).abs() <= 1) return;
        position.jumpTo(max);
        attempts += 1;
        if (attempts < 4) tick();
      });
    }

    tick();
  }

  bool _onThreadScroll(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical) return false;
    if (notification is UserScrollNotification) {
      _stickToBottom = notification.direction == ScrollDirection.idle &&
          _nearBottom(notification.metrics);
    } else if (notification is ScrollEndNotification) {
      _stickToBottom = _nearBottom(notification.metrics);
    }
    final userMoved = notification is UserScrollNotification ||
        notification is ScrollEndNotification ||
        (notification is ScrollUpdateNotification &&
            notification.dragDetails != null);
    final nearTop = notification.metrics.pixels <= 64 &&
        notification.metrics.maxScrollExtent > 0;
    if (userMoved && nearTop && _hasOlder && !_loadingOlder) {
      _loadOlder();
    }
    return false;
  }

  Future<void> _loadOlder() async {
    if (_loadingOlder || !_hasOlder || _messages.isEmpty) return;
    _loadingOlder = true;
    setState(() {});
    final oldest = _messages.first;
    final DiaryMessagePage page;
    try {
      page = await widget.store.listMessagePage(
        beforeTimestamp: oldest.timestamp,
        beforeId: oldest.id,
      );
    } catch (_) {
      if (mounted) setState(() => _loadingOlder = false);
      return;
    }
    if (!mounted) return;
    final pixels =
        _threadScroll.hasClients ? _threadScroll.position.pixels : 0.0;
    final maxBefore =
        _threadScroll.hasClients ? _threadScroll.position.maxScrollExtent : 0.0;
    setState(() {
      _loadingOlder = false;
      _hasOlder = page.hasOlder;
      if (page.messages.isNotEmpty) {
        _messages = [...page.messages, ..._messages];
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_threadScroll.hasClients) return;
      final delta = _threadScroll.position.maxScrollExtent - maxBefore;
      final target =
          (pixels + delta).clamp(0.0, _threadScroll.position.maxScrollExtent);
      if ((target - _threadScroll.position.pixels).abs() > 0.5) {
        _threadScroll.jumpTo(target);
      }
    });
  }

  Future<void> _load() async {
    final optedIn = await widget.store.isOptedIn();
    final profile = await LocalDatabaseService.instance.getGolferProfile();
    final clubs = await LocalDatabaseService.instance.getAllClubs();
    final evaluations = await widget.store.listEvaluations();
    final DiaryMessagePage? initial;
    final List<DiaryMessage> newer;
    if (_messages.isEmpty) {
      initial = await widget.store.listMessagePage();
      newer = const [];
    } else {
      initial = null;
      final latest = _messages.last;
      newer = await widget.store.listMessagesAfter(
        timestamp: latest.timestamp,
        id: latest.id,
      );
    }
    if (!mounted) return;
    final follow = initial != null || _stickToBottom;
    setState(() {
      _optedIn = optedIn;
      _evaluations = evaluations;
      _profile = profile;
      _clubsMissingSpecs = clubsMissingEquipmentSpecs(clubs);
      _loading = false;
      if (initial != null) {
        _messages = initial.messages;
        _hasOlder = initial.hasOlder;
        _stickToBottom = true;
      } else if (newer.isNotEmpty) {
        _messages = [..._messages, ...newer];
      }
    });
    if (follow && (initial != null || newer.isNotEmpty)) {
      _scheduleFollowBottom();
    }
    await _maybeAskReview();
  }

  Future<void> _maybeAskReview() async {
    final sessionId = widget.reviewSessionId;
    if (sessionId == null || !widget.autoAskReview || _reviewAskStarted) {
      return;
    }
    if (!_optedIn || !widget.diary.available || _busy) return;
    _reviewAskStarted = true;
    await _send(
      kLastRangeSessionQuestion,
      focusSessionId: sessionId,
      skipUserMessage: true,
    );
  }

  Future<void> _continue() async {
    await widget.store.setOptedIn(true);
    if (!mounted) return;
    setState(() => _optedIn = true);
    await _maybeAskReview();
  }

  Future<void> _send(
    String text, {
    String? focusSessionId,
    bool skipUserMessage = false,
  }) async {
    final question = text.trim();
    if (!widget.diary.available || _busy || question.isEmpty) return;
    final cancel = DiaryCancel();
    _cancel = cancel;
    _pendingQuestion = question;
    _pendingFocusSessionId = focusSessionId;
    _pendingSkipUserMessage = skipUserMessage;
    setState(() {
      _busy = true;
      _draft = '';
      _errorMessage = null;
    });
    if (_stickToBottom) _scheduleFollowBottom();
    try {
      final persona = await widget.personaStore.load();
      final plan = await widget.store.preparePrompt(
        question: question,
        persona: persona,
        focusSessionId: focusSessionId,
      );
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
        if (_stickToBottom) _scheduleFollowBottom();
      }
      if (cancel.isCancelled) throw const DiaryCancelled();
      if (!mounted) return;
      final sessionId =
          focusSessionId ?? await widget.store.latestTodaySessionId();
      await widget.store.ask(
        prompt: plan.prompt,
        promptTokens: plan.tokens,
        reply: buffer.toString(),
        userText: question,
        sessionId: sessionId,
        skipUserMessage: skipUserMessage,
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
                ? const GolfPuttLoader(
                    key: ValueKey('diary-send-busy'),
                    width: 32,
                    height: 20,
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
                        : NotificationListener<ScrollNotification>(
                            onNotification: _onThreadScroll,
                            child: SingleChildScrollView(
                              controller: _threadScroll,
                              primary: false,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
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
                                          onPressed: () =>
                                              Navigator.pop(context),
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
                                  if (_hasOlder)
                                    SizedBox(
                                      key: const ValueKey(
                                          'diary-history-loader'),
                                      height: 32,
                                      child: Center(
                                        child: _loadingOlder
                                            ? const SizedBox(
                                                width: 16,
                                                height: 16,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                ),
                                              )
                                            : const SizedBox.shrink(),
                                      ),
                                    ),
                                  for (final message in _messages)
                                    ListTile(
                                      key: ValueKey(
                                          'diary-message-${message.id}'),
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
                                          ? DiaryMarkdownBody(
                                              data: message.content)
                                          : Text(message.content),
                                    ),
                                  if (_optedIn) ...[
                                    if (_busy && _draft.isEmpty)
                                      const ListTile(
                                        key: ValueKey('diary-golf-loader'),
                                        title: Text('Evaluation'),
                                        subtitle: Align(
                                          alignment: Alignment.centerLeft,
                                          child: Padding(
                                            padding: EdgeInsets.only(top: 8),
                                            child: GolfPuttLoader(
                                              width: 120,
                                              height: 32,
                                            ),
                                          ),
                                        ),
                                      ),
                                    if (_draft.isNotEmpty)
                                      ListTile(
                                        key: const ValueKey('diary-eval-draft'),
                                        title: const Text('Evaluation'),
                                        subtitle:
                                            DiaryMarkdownBody(data: _draft),
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
                                                    : () =>
                                                        _applyLeadIn(prompt),
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
                                            icon: const Icon(Icons.close,
                                                size: 18),
                                          ),
                                        ],
                                      ),
                                    Wrap(
                                      spacing: 8,
                                      children: [
                                        TextButton(
                                          key: const ValueKey(
                                              'diary-baseline-btn'),
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
                    onPressed: () => _send(
                      _pendingQuestion ?? '',
                      focusSessionId: _pendingFocusSessionId,
                      skipUserMessage: _pendingSkipUserMessage,
                    ),
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
