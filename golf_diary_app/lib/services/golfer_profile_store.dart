import 'package:flutter/widgets.dart';

import '../models/golfer_profile.dart';
import 'local_database_service.dart';

/// In-memory profile for Bag/Range; refresh after Settings saves (MGDV-202).
class GolferProfileStore extends ChangeNotifier {
  GolferProfile profile = const GolferProfile();

  YardageUiDensity get yardageDensity => resolveYardageUiDensity(profile);

  Future<void> load() async {
    profile = await LocalDatabaseService.instance.getGolferProfile();
    notifyListeners();
  }

  Future<void> persist(GolferProfile next) async {
    await LocalDatabaseService.instance.saveGolferProfile(next);
    await load();
  }

  Future<void> refresh() => load();
}

class GolferProfileScope extends InheritedNotifier<GolferProfileStore> {
  const GolferProfileScope({
    super.key,
    required GolferProfileStore store,
    required super.child,
  }) : super(notifier: store);

  static GolferProfileStore of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<GolferProfileScope>();
    assert(scope != null, 'GolferProfileScope not found');
    return scope!.notifier!;
  }

  static GolferProfileStore? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<GolferProfileScope>()
        ?.notifier;
  }
}