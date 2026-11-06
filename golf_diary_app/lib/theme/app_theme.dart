import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'font_loading.dart';

// ─── Golf Diary Design System v1.0 ─────────────────────────────────────────
// Moodboard : docs/context/UI_UX_Design_Guide.md
// Source    : docs/context/designs/DesignSystem.md
//
// Rule: Never add ad-hoc Color literals to screen widgets.
// Use GolfPalette tokens or Theme.of(context).colorScheme roles.

// ─── Palette tokens ──────────────────────────────────────────────────────────

class GolfPalette {
  GolfPalette._();

  // Brand greens
  static const Color fairwayGreen   = Color(0xFF1A5E3A); // primary brand, CTA
  static const Color fairwayDark    = Color(0xFF0F4228); // deep surface, pressed
  static const Color fairwayLight   = Color(0xFF6DBF8C); // primary on dark bg

  // Accent
  static const Color birdieGold     = Color(0xFFC8A84B); // secondary (light)
  static const Color birdieGoldDark = Color(0xFFD4B85A); // secondary (dark)

  // Light mode surfaces
  static const Color cream          = Color(0xFFFAF7F0); // base background
  static const Color creamElevated  = Color(0xFFF0EDE5); // cards
  static const Color creamSunken    = Color(0xFFE8E5DC); // inputs, steppers
  static const Color hairline       = Color(0xFFD8D2C4); // 0.5 dp dividers

  // Dark mode surfaces
  static const Color deepForest     = Color(0xFF0E1611); // OLED base
  static const Color forestElevated = Color(0xFF162019); // dark cards
  static const Color forestSunken   = Color(0xFF1E2D22); // dark inputs
  static const Color forestHairline = Color(0xFF2A3A2E); // dark dividers

  // Ink
  static const Color inkPrimary     = Color(0xFF1C1C1E); // body text, digits (light)
  static const Color inkSecondary   = Color(0xFF5C5C5C); // labels, captions (light)
  static const Color inkTertiary    = Color(0xFF8A8A8A); // hints (light)
  static const Color inkOnDark      = Color(0xFFF0EDE5); // body text (dark)
  static const Color inkOnDarkSub   = Color(0xFFA0A8A2); // sub-labels (dark)

  // Semantic
  static const Color positive       = Color(0xFF1A5E3A); // birdie / under par
  static const Color negative       = Color(0xFF8B2E2E); // bogey / over par / error
  static const Color negativeLight  = Color(0xFFCF8484); // error text on dark bg
  static const Color warning        = Color(0xFFA67B2E); // penalty / caution
}

/// Backward-compatible aliases — migrate screens to colorScheme roles over time.
class AppColors {
  AppColors._();
  static const Color green = GolfPalette.fairwayGreen;
  static const Color amber = GolfPalette.birdieGold;
}

TextStyle _playfair({
  required double fontSize,
  FontWeight fontWeight = FontWeight.w400,
  Color? color,
  double? letterSpacing,
  double? height,
}) {
  if (!useGoogleFonts) {
    return TextStyle(
      fontFamily: 'serif',
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );
  }
  return GoogleFonts.playfairDisplay(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    letterSpacing: letterSpacing,
    height: height,
  );
}

TextStyle _inter({
  required double fontSize,
  FontWeight fontWeight = FontWeight.w400,
  Color? color,
  double? letterSpacing,
  double? height,
}) {
  if (!useGoogleFonts) {
    return TextStyle(
      fontFamily: 'sans-serif',
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );
  }
  return GoogleFonts.inter(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    letterSpacing: letterSpacing,
    height: height,
  );
}

TextStyle _mono({
  required double fontSize,
  FontWeight fontWeight = FontWeight.w400,
  Color? color,
}) {
  if (!useGoogleFonts) {
    return TextStyle(
      fontFamily: 'monospace',
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
  }
  return GoogleFonts.robotoMono(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
  );
}

// ─── Color schemes ───────────────────────────────────────────────────────────

ColorScheme _lightScheme() => ColorScheme.fromSeed(
      seedColor: GolfPalette.fairwayGreen,
      brightness: Brightness.light,
    ).copyWith(
      primary:                GolfPalette.fairwayGreen,
      onPrimary:              Colors.white,
      primaryContainer:       const Color(0xFFB8E8C8),
      onPrimaryContainer:     const Color(0xFF002112),
      secondary:              GolfPalette.birdieGold,
      onSecondary:            const Color(0xFF2A1E00),
      secondaryContainer:     const Color(0xFFF5E8C4),
      onSecondaryContainer:   const Color(0xFF2A1E00),
      error:                  GolfPalette.negative,
      onError:                Colors.white,
      errorContainer:         const Color(0xFFFFDAD6),
      onErrorContainer:       const Color(0xFF520000),
      surface:                GolfPalette.cream,
      onSurface:              GolfPalette.inkPrimary,
      surfaceContainerLowest: const Color(0xFFFFFDF8),
      surfaceContainerLow:    const Color(0xFFF5F2EA),
      surfaceContainer:       GolfPalette.creamElevated,
      surfaceContainerHigh:   GolfPalette.creamSunken,
      surfaceContainerHighest:const Color(0xFFE0DDD5),
      onSurfaceVariant:       GolfPalette.inkSecondary,
      outline:                GolfPalette.hairline,
      outlineVariant:         const Color(0xFFE8E5DC),
    );

ColorScheme _darkScheme() => ColorScheme.fromSeed(
      seedColor: GolfPalette.fairwayGreen,
      brightness: Brightness.dark,
    ).copyWith(
      primary:                GolfPalette.fairwayLight,
      onPrimary:              const Color(0xFF002112),
      primaryContainer:       GolfPalette.fairwayGreen,
      onPrimaryContainer:     const Color(0xFFB8E8C8),
      secondary:              GolfPalette.birdieGoldDark,
      onSecondary:            const Color(0xFF2A1E00),
      secondaryContainer:     const Color(0xFF4A3800),
      onSecondaryContainer:   const Color(0xFFF5E8C4),
      error:                  GolfPalette.negativeLight,
      onError:                const Color(0xFF520000),
      errorContainer:         GolfPalette.negative,
      onErrorContainer:       const Color(0xFFFFDAD6),
      surface:                GolfPalette.deepForest,
      onSurface:              GolfPalette.inkOnDark,
      surfaceContainerLowest: const Color(0xFF0A1209),
      surfaceContainerLow:    const Color(0xFF121912),
      surfaceContainer:       GolfPalette.forestElevated,
      surfaceContainerHigh:   GolfPalette.forestSunken,
      surfaceContainerHighest:const Color(0xFF263829),
      onSurfaceVariant:       GolfPalette.inkOnDarkSub,
      outline:                GolfPalette.forestHairline,
      outlineVariant:         const Color(0xFF2A3A2E),
    );

// ─── Typography ──────────────────────────────────────────────────────────────

TextTheme _buildTextTheme({required bool isDark}) {
  final ink    = isDark ? GolfPalette.inkOnDark    : GolfPalette.inkPrimary;
  final inkSub = isDark ? GolfPalette.inkOnDarkSub : GolfPalette.inkSecondary;

  return TextTheme(
    // Playfair Display — display, headline (serif, premium)
    displayLarge:  _playfair(fontSize: 57, fontWeight: FontWeight.w400, color: ink, letterSpacing: -0.25, height: 1.12),
    displayMedium: _playfair(fontSize: 45, fontWeight: FontWeight.w400, color: ink, height: 1.16),
    displaySmall:  _playfair(fontSize: 36, fontWeight: FontWeight.w400, color: ink, height: 1.22),
    headlineLarge: _playfair(fontSize: 32, fontWeight: FontWeight.w700, color: ink, height: 1.25),
    headlineMedium:_playfair(fontSize: 28, fontWeight: FontWeight.w600, color: ink, height: 1.29),
    headlineSmall: _playfair(fontSize: 24, fontWeight: FontWeight.w600, color: ink, height: 1.33),

    // Inter — title, body, label (clean sans-serif)
    titleLarge:  _inter(fontSize: 22, fontWeight: FontWeight.w600, color: ink,    letterSpacing: 0,    height: 1.27),
    titleMedium: _inter(fontSize: 16, fontWeight: FontWeight.w600, color: ink,    letterSpacing: 0.15, height: 1.5),
    titleSmall:  _inter(fontSize: 14, fontWeight: FontWeight.w600, color: ink,    letterSpacing: 0.1,  height: 1.43),
    bodyLarge:   _inter(fontSize: 16, fontWeight: FontWeight.w400, color: ink,    letterSpacing: 0.5,  height: 1.5),
    bodyMedium:  _inter(fontSize: 14, fontWeight: FontWeight.w400, color: ink,    letterSpacing: 0.25, height: 1.43),
    bodySmall:   _inter(fontSize: 12, fontWeight: FontWeight.w400, color: inkSub, letterSpacing: 0.4,  height: 1.33),
    labelLarge:  _inter(fontSize: 14, fontWeight: FontWeight.w700, color: ink,    letterSpacing: 1.5,  height: 1.43),
    labelMedium: _inter(fontSize: 12, fontWeight: FontWeight.w600, color: inkSub, letterSpacing: 1.25, height: 1.33),
    labelSmall:  _inter(fontSize: 11, fontWeight: FontWeight.w600, color: inkSub, letterSpacing: 1.5,  height: 1.45),
  );
}

// ─── Monospaced number helpers ────────────────────────────────────────────────
//
// Use GolfTextStyles for every yardage, stroke count, score, and distance.
// Roboto Mono + tabular figures make digits stack cleanly across stat rows.

class GolfTextStyles {
  GolfTextStyles._();

  /// Base monospaced style — scores, counters, raw numbers.
  static TextStyle tabularNum(
    BuildContext context, {
    double fontSize = 24,
    FontWeight fontWeight = FontWeight.w700,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _mono(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: isDark ? GolfPalette.inkOnDark : GolfPalette.inkPrimary,
    );
  }

  /// Birdie / Eagle / under-par score — fairway green.
  static TextStyle scorePositive(BuildContext context, {double fontSize = 20}) =>
      tabularNum(context, fontSize: fontSize)
          .copyWith(color: GolfPalette.positive);

  /// Bogey / over-par score — burgundy.
  static TextStyle scoreNegative(BuildContext context, {double fontSize = 20}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return tabularNum(context, fontSize: fontSize).copyWith(
      color: isDark ? GolfPalette.negativeLight : GolfPalette.negative,
    );
  }

  /// Yardage display — slightly smaller, medium weight.
  static TextStyle yardage(BuildContext context, {double fontSize = 18}) =>
      tabularNum(context, fontSize: fontSize, fontWeight: FontWeight.w600);
}

// ─── ThemeData ────────────────────────────────────────────────────────────────

ThemeData buildGolfTheme({Brightness brightness = Brightness.light}) {
  final isDark = brightness == Brightness.dark;
  final cs     = isDark ? _darkScheme() : _lightScheme();
  final tt     = _buildTextTheme(isDark: isDark);

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: cs,
    textTheme: tt,
    scaffoldBackgroundColor: isDark ? GolfPalette.deepForest : GolfPalette.cream,

    // ── AppBar ───────────────────────────────────────────────────
    appBarTheme: AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0.5,
      backgroundColor:    isDark ? GolfPalette.fairwayDark : GolfPalette.fairwayGreen,
      foregroundColor:    Colors.white,
      centerTitle:        true,
      surfaceTintColor:   Colors.transparent,
      shadowColor:        Colors.transparent,
      titleTextStyle: _playfair(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: Colors.white,
        letterSpacing: 0.15,
      ),
    ),

    // ── Bottom NavigationBar ──────────────────────────────────────
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor:  isDark ? GolfPalette.forestElevated : GolfPalette.creamElevated,
      indicatorColor:   cs.primaryContainer,
      elevation:        0,
      surfaceTintColor: Colors.transparent,
      shadowColor:      Colors.transparent,
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return IconThemeData(color: cs.onPrimaryContainer, size: 24);
        }
        return IconThemeData(color: cs.onSurfaceVariant, size: 24);
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return _inter(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: cs.primary,
            letterSpacing: 0.5,
          );
        }
        return _inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: cs.onSurfaceVariant,
          letterSpacing: 0.5,
        );
      }),
    ),

    // ── Card ──────────────────────────────────────────────────────
    cardTheme: CardThemeData(
      color:             isDark ? GolfPalette.forestElevated : GolfPalette.creamElevated,
      elevation:         0,
      shadowColor:       Colors.transparent,
      surfaceTintColor:  Colors.transparent,
      margin:            EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDark ? GolfPalette.forestHairline : GolfPalette.hairline,
          width: 0.5,
        ),
      ),
    ),

    // ── Chips ─────────────────────────────────────────────────────
    chipTheme: ChipThemeData(
      backgroundColor:       isDark ? GolfPalette.forestSunken   : GolfPalette.creamSunken,
      selectedColor:         GolfPalette.fairwayGreen,
      secondarySelectedColor:cs.primaryContainer,
      checkmarkColor:        GolfPalette.birdieGold,
      showCheckmark:         false,
      labelStyle: _inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: isDark ? GolfPalette.inkOnDark : GolfPalette.inkPrimary,
      ),
      secondaryLabelStyle: _inter(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(100),
        side: BorderSide(
          color: isDark ? GolfPalette.forestHairline : GolfPalette.hairline,
          width: 0.5,
        ),
      ),
      elevation: 0,
    ),

    // ── Elevated button — primary CTA ─────────────────────────────
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize:            const Size.fromHeight(56),
        backgroundColor:        cs.primary,
        foregroundColor:        cs.onPrimary,
        disabledBackgroundColor:cs.surfaceContainerHigh,
        elevation:              0,
        shadowColor:            Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: _inter(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.5),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      ),
    ),

    // ── Outlined button — secondary ───────────────────────────────
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize:   const Size.fromHeight(56),
        foregroundColor: cs.primary,
        side:          BorderSide(color: cs.primary, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: _inter(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.5),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      ),
    ),

    // ── Text button — tertiary / link ─────────────────────────────
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: cs.primary,
        minimumSize: const Size(0, 44),
        textStyle: _inter(fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 0.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),

    // ── Filled button ─────────────────────────────────────────────
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize:    const Size.fromHeight(56),
        backgroundColor:cs.primary,
        foregroundColor:cs.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: _inter(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.5),
      ),
    ),

    // ── Input decoration ──────────────────────────────────────────
    inputDecorationTheme: InputDecorationTheme(
      filled:    true,
      fillColor: isDark ? GolfPalette.forestSunken : GolfPalette.creamSunken,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: isDark ? GolfPalette.forestHairline : GolfPalette.hairline, width: 0.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: isDark ? GolfPalette.forestHairline : GolfPalette.hairline, width: 0.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: GolfPalette.fairwayGreen, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: GolfPalette.negative, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: GolfPalette.negative, width: 2),
      ),
      labelStyle: _inter(fontSize: 14, fontWeight: FontWeight.w500, color: isDark ? GolfPalette.inkOnDarkSub : GolfPalette.inkSecondary),
      hintStyle:  _inter(fontSize: 14, fontWeight: FontWeight.w400, color: isDark ? GolfPalette.inkOnDarkSub : GolfPalette.inkTertiary),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),

    // ── Dividers ──────────────────────────────────────────────────
    dividerTheme: DividerThemeData(
      color:     isDark ? GolfPalette.forestHairline : GolfPalette.hairline,
      thickness: 0.5,
      space:     0,
    ),

    // ── SnackBar ──────────────────────────────────────────────────
    snackBarTheme: SnackBarThemeData(
      backgroundColor: isDark ? GolfPalette.forestElevated : GolfPalette.inkPrimary,
      contentTextStyle: _inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: isDark ? GolfPalette.inkOnDark : GolfPalette.cream,
      ),
      shape:     RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      behavior:  SnackBarBehavior.floating,
      elevation: 4,
    ),

    // ── ListTile ──────────────────────────────────────────────────
    listTileTheme: const ListTileThemeData(
      tileColor:          Colors.transparent,
      contentPadding:     EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      minVerticalPadding: 12,
    ),

    // ── Bottom sheet ──────────────────────────────────────────────
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor:  isDark ? GolfPalette.forestElevated : GolfPalette.creamElevated,
      surfaceTintColor: Colors.transparent,
      elevation:        0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    ),

    // ── FAB ───────────────────────────────────────────────────────
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: cs.primary,
      foregroundColor: cs.onPrimary,
      elevation:       2,
      shape:           const CircleBorder(),
    ),
  );
}
