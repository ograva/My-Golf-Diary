import 'account_link_conflict.dart';
import 'account_session.dart';

/// Holds the account session across Firebase auth events.
///
/// Email sign-in can emit a null user while [current] is about to become the
/// signed-in account, or while it is already that account. A null event must
/// not clear a session that just succeeded.
class AuthSessionBinder {
  AuthSessionBinder({this.settleDelay = const Duration(milliseconds: 400)});

  final Duration settleDelay;
  AccountSession session = const AccountSession.signedOut();
  int _epoch = 0;

  void adopt(AuthUserSnapshot? user) {
    _epoch++;
    session = sessionFromAuthSnapshot(user);
  }

  /// Applies one auth event. Returns the session to show now.
  ///
  /// When both [event] and [current] are null, the previous session stays
  /// until [settle] runs for the returned epoch.
  AccountSession apply({
    required AuthUserSnapshot? event,
    required AuthUserSnapshot? current,
    void Function(int epoch)? whenSettled,
  }) {
    final epoch = ++_epoch;
    final immediate = event ?? current;
    if (immediate != null) {
      session = sessionFromAuthSnapshot(immediate);
      return session;
    }
    whenSettled?.call(epoch);
    return session;
  }

  /// Confirms or clears a held session. Returns false when a newer event won.
  bool settle(int epoch, AuthUserSnapshot? current) {
    if (epoch != _epoch) return false;
    session = sessionFromAuthSnapshot(current);
    return true;
  }
}
