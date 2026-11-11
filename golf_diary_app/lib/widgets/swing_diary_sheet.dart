import 'package:flutter/material.dart';

import '../services/diary_model.dart';
import '../services/swing_diary_service.dart';

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
  List<DiaryMessage> _messages = const [];
  List<RangeEvaluation> _evaluations = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _composer.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final optedIn = await widget.store.isOptedIn();
    final hasToday = await widget.store.hasDrillToday();
    final messages = await widget.store.listMessages();
    final evaluations = await widget.store.listEvaluations();
    if (!mounted) return;
    setState(() {
      _optedIn = optedIn;
      _hasToday = hasToday;
      _messages = messages;
      _evaluations = evaluations;
      _loading = false;
    });
  }

  Future<void> _continue() async {
    await widget.store.setOptedIn(true);
    if (!mounted) return;
    setState(() => _optedIn = true);
  }

  Future<void> _send(String text) async {
    if (!widget.diary.available || _busy || text.trim().isEmpty) return;
    setState(() => _busy = true);
    final plan = await widget.store.preparePrompt(question: text);
    final reply = await widget.diary.generate(plan.prompt);
    final sessionId = await widget.store.latestTodaySessionId();
    await widget.store.ask(
      prompt: plan.prompt,
      reply: reply,
      userText: text,
      sessionId: sessionId,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    _composer.clear();
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final available = widget.diary.available;
    final height = MediaQuery.sizeOf(context).height * 0.85;
    return SafeArea(
      child: SizedBox(
        height: height,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Swing diary', style: Theme.of(context).textTheme.titleLarge),
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
                                      key: const ValueKey('diary-opt-in-dismiss'),
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Not now'),
                                    ),
                                    ElevatedButton(
                                      key: const ValueKey('diary-opt-in-continue'),
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
                                    key: ValueKey('diary-message-${message.id}'),
                                    title: Text(message.role == 'model' ? 'Evaluation' : 'You'),
                                    subtitle: Text(message.content),
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
                                  key: const ValueKey('diary-summarize-today-btn'),
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
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: TextButton(
                                    key: const ValueKey('diary-evaluation-log-btn'),
                                    onPressed: () => setState(() => _showLog = true),
                                    child: const Text('Evaluation log'),
                                  ),
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
              subtitle: Text(row.content),
            ),
      ],
    );
  }
}
