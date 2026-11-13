import 'dart:async';

import 'package:flutter/material.dart';

import '../app_check_config.dart';
import '../models/golfer_profile.dart';
import '../services/diary_model.dart';
import '../services/golfer_profile_service.dart';
import '../services/local_database_service.dart';
import '../services/swing_diary_service.dart';
import 'diary_markdown_body.dart';
import 'golfer_baseline_sheet.dart';

/// Opt-in swing diary. The model is only called after Continue, and only
/// when [diary] reports that Vertex is available.
class SwingDiarySheet extends StatefulWidget {
  const SwingDiarySheet({super.key, required this.diary, required this.store});

  final DiaryModel diary;
  final SwingDiaryService store;

  @override
  State<SwingDiarySheet> createState() => _SwingDiarySheetState();
}

class _SwingDiarySheetState extends State<SwingDiarySheet> {
  final _composer = TextEditingController();
  var _loading = true;
  var _optedIn = false;
  var _hasToday = false;
  var _showLog = false;
  var _busy = false;
  var _promptChars = 0;
  var _promptTokens = 0;
  var _chunks = 0;
  String? _phase;
  String? _status;
  String? _errorType;
  String? _errorMessage;
  String? _evaluationId;
  String _draft = '';
  String _appCheck = 'missing';
  String? _pendingQuestion;
  DateTime? _startedAt;
  Timer? _ticker;
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
    _load();
  }

  @override
  void dispose() {
    _cancel?.cancel();
    _ticker?.cancel();
    _composer.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final optedIn = await widget.store.isOptedIn();
    final profile = await LocalDatabaseService.instance.getGolferProfile();
    final clubs = await LocalDatabaseService.instance.getAllClubs();
    final hasToday = await widget.store.hasDrillToday();
    final messages = await widget.store.listMessages();
    final evaluations = await widget.store.listEvaluations();
    if (!mounted) return;
    setState(() {
      _optedIn = optedIn;
      _hasToday = hasToday;
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

  void _startClock() {
    _ticker?.cancel();
    _startedAt = DateTime.now();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _busy) setState(() {});
    });
  }

  void _stopClock() {
    _ticker?.cancel();
    _ticker = null;
  }

  Future<void> _send(String text) async {
    final question = text.trim();
    if (!widget.diary.available || _busy || question.isEmpty) return;
    final cancel = DiaryCancel();
    _cancel = cancel;
    _pendingQuestion = question;
    _startClock();
    setState(() {
      _busy = true;
      _phase = 'prepare';
      _status = 'Preparing your session';
      _draft = '';
      _chunks = 0;
      _promptChars = 0;
      _promptTokens = 0;
      _errorType = null;
      _errorMessage = null;
      _evaluationId = null;
    });
    try {
      final plan = await widget.store.preparePrompt(question: question);
      final appCheck = await appCheckDebugState();
      if (cancel.isCancelled) throw const DiaryCancelled();
      if (!mounted) return;
      setState(() {
        _phase = 'request';
        _status = 'Waiting for Vertex';
        _promptChars = plan.systemInstruction.length + plan.prompt.length;
        _promptTokens = plan.tokens;
        _appCheck = appCheck;
      });
      final buffer = StringBuffer();
      await for (final chunk in widget.diary.generate(
        plan.prompt,
        systemInstruction: plan.systemInstruction,
        cancel: cancel,
      )) {
        if (cancel.isCancelled) throw const DiaryCancelled();
        buffer.write(chunk);
        if (!mounted) return;
        setState(() {
          _phase = 'stream';
          _status = 'Waiting for Vertex';
          _chunks += 1;
          _draft = buffer.toString();
        });
      }
      if (cancel.isCancelled) throw const DiaryCancelled();
      if (!mounted) return;
      setState(() => _phase = 'save');
      final sessionId = await widget.store.latestTodaySessionId();
      final saved = await widget.store.ask(
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
        _phase = 'done';
        _status = null;
        _draft = '';
        _evaluationId = saved.evaluationId;
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
      setState(() {
        _phase = 'cancelled';
        _status = 'Evaluation cancelled';
        _draft = '';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _phase = 'failed';
        _status = '$error';
        _errorType = error.runtimeType.toString();
        _errorMessage = '$error';
        _draft = '';
      });
    } finally {
      _cancel = null;
      _stopClock();
      if (mounted) setState(() => _busy = false);
    }
  }

  void _applyLeadIn(LeadInPrompt prompt) {
    final current = _composer.text.trim();
    if (!current.contains(prompt.prefix)) {
      _composer.text = current.isEmpty ? prompt.prefix : '$current\n${prompt.prefix}';
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

  String _debugLine() {
    final elapsed = _startedAt == null
        ? 0
        : DateTime.now().difference(_startedAt!).inSeconds;
    final firebase = widget.diary.available ? 'yes' : 'no';
    final base =
        'phase=$_phase model=${widget.diary.modelName} location=${widget.diary.location} '
        'firebase=$firebase appCheck=$_appCheck chars=$_promptChars tokens=$_promptTokens elapsed=${elapsed}s chunks=$_chunks';
    if (_phase == 'cancelled') return '$base cancelled by user';
    if (_phase == 'failed') return '$base error=$_errorType: $_errorMessage';
    if (_phase == 'done') return '$base saved $_evaluationId';
    return base;
  }

  @override
  Widget build(BuildContext context) {
    final available = widget.diary.available;
    final height = MediaQuery.sizeOf(context).height * 0.85;
    final failed = _phase == 'failed' && !_busy;
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
                                  'Range notes are sent to produce an evaluation of this session. No API key is stored on this phone.',
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
                                    'Your range log is still on this phone.',
                                    key: ValueKey('diary-offline-copy'),
                                  ),
                                ),
                              if (_optedIn) ...[
                                const SizedBox(height: 12),
                                for (final message in _messages)
                                  ListTile(
                                    key:
                                        ValueKey('diary-message-${message.id}'),
                                    title: Text(message.role == 'model'
                                        ? 'Evaluation'
                                        : 'You'),
                                    subtitle: message.role == 'model'
                                        ? DiaryMarkdownBody(
                                            data: message.content)
                                        : Text(message.content),
                                  ),
                                if (_draft.isNotEmpty)
                                  ListTile(
                                    key: const ValueKey('diary-eval-draft'),
                                    title: const Text('Evaluation'),
                                    subtitle: DiaryMarkdownBody(data: _draft),
                                  ),
                                if (_status != null) ...[
                                  const SizedBox(height: 8),
                                  Text(_status!,
                                      key: const ValueKey('diary-eval-status')),
                                ],
                                if (_phase != null)
                                  Text(
                                    _debugLine(),
                                    key: const ValueKey('diary-eval-debug'),
                                  ),
                                const SizedBox(height: 8),
                                if (_baselineUpdated) ...[
                                  Text(
                                    _baselineSummary ?? 'Baseline updated',
                                    key: const ValueKey('diary-baseline-updated'),
                                  ),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: TextButton(
                                      key: const ValueKey('diary-baseline-review'),
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
                                const SizedBox(height: 8),
                                TextField(
                                  key: const ValueKey('diary-composer-field'),
                                  controller: _composer,
                                  enabled: available && !_busy,
                                  decoration: const InputDecoration(
                                    hintText: 'Ask about a session',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                OutlinedButton(
                                  key: const ValueKey(
                                      'diary-summarize-today-btn'),
                                  onPressed: available && _hasToday && !_busy
                                      ? () => _send('Summarize today')
                                      : null,
                                  child: const Text('Summarize today'),
                                ),
                                const SizedBox(height: 8),
                                ElevatedButton(
                                  key: const ValueKey('diary-send-btn'),
                                  onPressed: available && !_busy
                                      ? () => _send(_composer.text)
                                      : null,
                                  child: const Text('Send'),
                                ),
                                if (_busy)
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: TextButton(
                                      key: const ValueKey('diary-eval-cancel'),
                                      onPressed: () => _cancel?.cancel(),
                                      child: const Text('Cancel'),
                                    ),
                                  ),
                                if (failed)
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: TextButton(
                                      key: const ValueKey('diary-eval-retry'),
                                      onPressed: () =>
                                          _send(_pendingQuestion ?? ''),
                                      child: const Text('Try again'),
                                    ),
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
