import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'app_build_id.dart';
import 'pwa_update_client.dart';
import 'pwa_update_policy.dart';

/// Listens for a published web build and asks before the PWA reloads onto it.
class PwaUpdateHost extends StatefulWidget {
  const PwaUpdateHost({
    super.key,
    required this.child,
    this.client = const PlatformPwaUpdateClient(),
    this.runningBuildId = appBuildId,
    this.enabled,
    this.recheckInterval = const Duration(minutes: 15),
  });

  final Widget child;
  final PwaUpdateClient client;
  final String runningBuildId;

  /// Release web builds check for a published update. Set this in tests.
  final bool? enabled;

  /// How often to look again while the app stays open. Null checks on launch
  /// and when the app resumes.
  final Duration? recheckInterval;

  @override
  State<PwaUpdateHost> createState() => _PwaUpdateHostState();
}

class _PwaUpdateHostState extends State<PwaUpdateHost>
    with WidgetsBindingObserver {
  Timer? _timer;
  String? _dismissedBuildId;
  bool _checking = false;
  bool _dialogOpen = false;
  bool _applying = false;

  bool get _enabled => widget.enabled ?? !kDebugMode;

  @override
  void initState() {
    super.initState();
    if (!_enabled) return;
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
    final interval = widget.recheckInterval;
    if (interval != null) {
      _timer = Timer.periodic(interval, (_) => _check());
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    if (_enabled) WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _check();
  }

  Future<void> _check() async {
    if (!_enabled || _checking || _dialogOpen || _applying || !mounted) return;
    _checking = true;
    try {
      final published = await widget.client.fetchPublishedBuild();
      if (!mounted || published == null) return;
      final offer = shouldOfferPwaUpdate(
        runningBuildId: widget.runningBuildId,
        publishedBuildId: published.buildId,
        dismissedBuildId: _dismissedBuildId,
      );
      if (!offer) return;
      _dialogOpen = true;
      final accepted = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => const PwaUpdateDialog(),
      );
      _dialogOpen = false;
      if (!mounted) return;
      if (accepted == true) {
        _applying = true;
        await widget.client.applyUpdate();
      } else {
        _dismissedBuildId = published.buildId;
      }
    } finally {
      _checking = false;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class PwaUpdateDialog extends StatelessWidget {
  const PwaUpdateDialog({super.key});

  static const dialogKey = Key('pwa-update-dialog');
  static const updateKey = Key('pwa-update-confirm');
  static const laterKey = Key('pwa-update-later');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      key: dialogKey,
      icon: Icon(Icons.system_update_alt, color: theme.colorScheme.primary),
      title: Text('New version published', style: theme.textTheme.titleLarge),
      content: const Text(
        'A new version of Golf Diary is ready. Saved rounds, clubs, and notes stay on this device. The update starts when you choose Update.',
      ),
      actions: [
        TextButton(
          key: laterKey,
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Later'),
        ),
        FilledButton(
          key: updateKey,
          style: FilledButton.styleFrom(
            backgroundColor: GolfPalette.fairwayGreen,
            foregroundColor: GolfPalette.cream,
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Update'),
        ),
      ],
    );
  }
}
