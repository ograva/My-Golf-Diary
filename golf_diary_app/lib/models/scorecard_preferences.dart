/// Scorecard tab layout (MGDV-401).
abstract final class ScorecardViewMode {
  static const classic = 'classic';
  static const cart = 'cart';

  static const List<String> values = [classic, cart];

  static const String defaultMode = classic;

  static String label(String mode) => switch (mode) {
        classic => 'Classic',
        cart => 'Cart scoring',
        _ => mode,
      };
}