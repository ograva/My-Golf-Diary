# Design System — My Golf Diary

| Field | Value |
| :--- | :--- |
| **Version** | 1.0 |
| **Date** | 2026-11-06 |
| **Author** | Eunice (UI/UX Designer cohort) |
| **Implements** | `golf_diary_app/lib/theme/app_theme.dart` |

## Version History

| Version | Date | Summary |
| :--- | :--- | :--- |
| 1.0 | 2026-11-06 | Initial design system — palette, typography, component recipes, Do/Don't |

---

## 1. pubspec.yaml change

Add `google_fonts` to `dependencies`:

```yaml
dependencies:
  google_fonts: ^6.2.1
```

This provides **Playfair Display** (display/headline), **Inter** (body/label), and **Roboto Mono** (scores/yardages). No asset font declarations needed; the package handles caching.

---

## 2. Palette — `GolfPalette` class

```dart
/// Golf Diary Design System v1.0
/// Source of truth: docs/context/designs/DesignSystem.md
class GolfPalette {
  GolfPalette._();

  // Brand greens
  static const Color fairwayGreen    = Color(0xFF1A5E3A); // primary brand, CTA
  static const Color fairwayDark     = Color(0xFF0F4228); // deep surface, pressed
  static const Color fairwayLight    = Color(0xFF6DBF8C); // primary on dark bg

  // Accent
  static const Color birdieGold      = Color(0xFFC8A84B); // secondary (light)
  static const Color birdieGoldDark  = Color(0xFFD4B85A); // secondary (dark)

  // Light surfaces
  static const Color cream           = Color(0xFFFAF7F0);
  static const Color creamElevated   = Color(0xFFF0EDE5);
  static const Color creamSunken     = Color(0xFFE8E5DC);
  static const Color hairline        = Color(0xFFD8D2C4);

  // Dark surfaces
  static const Color deepForest      = Color(0xFF0E1611);
  static const Color forestElevated  = Color(0xFF162019);
  static const Color forestSunken    = Color(0xFF1E2D22);
  static const Color forestHairline  = Color(0xFF2A3A2E);

  // Ink
  static const Color inkPrimary      = Color(0xFF1C1C1E);
  static const Color inkSecondary    = Color(0xFF5C5C5C);
  static const Color inkTertiary     = Color(0xFF8A8A8A);
  static const Color inkOnDark       = Color(0xFFF0EDE5);
  static const Color inkOnDarkSub    = Color(0xFFA0A8A2);

  // Semantic
  static const Color positive        = Color(0xFF1A5E3A); // under par / success
  static const Color negative        = Color(0xFF8B2E2E); // over par / error
  static const Color negativeLight   = Color(0xFFCF8484); // error on dark bg
  static const Color warning         = Color(0xFFA67B2E); // penalty / caution
}
```

---

## 3. `app_theme.dart` — full implementation

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Golf Diary Design System v1.0 ─────────────────────────────────────────
// Moodboard: docs/context/UI_UX_Design_Guide.md
// Source:    docs/context/designs/DesignSystem.md

class GolfPalette {
  GolfPalette._();
  static const Color fairwayGreen    = Color(0xFF1A5E3A);
  static const Color fairwayDark     = Color(0xFF0F4228);
  static const Color fairwayLight    = Color(0xFF6DBF8C);
  static const Color birdieGold      = Color(0xFFC8A84B);
  static const Color birdieGoldDark  = Color(0xFFD4B85A);
  static const Color cream           = Color(0xFFFAF7F0);
  static const Color creamElevated   = Color(0xFFF0EDE5);
  static const Color creamSunken     = Color(0xFFE8E5DC);
  static const Color hairline        = Color(0xFFD8D2C4);
  static const Color deepForest      = Color(0xFF0E1611);
  static const Color forestElevated  = Color(0xFF162019);
  static const Color forestSunken    = Color(0xFF1E2D22);
  static const Color forestHairline  = Color(0xFF2A3A2E);
  static const Color inkPrimary      = Color(0xFF1C1C1E);
  static const Color inkSecondary    = Color(0xFF5C5C5C);
  static const Color inkTertiary     = Color(0xFF8A8A8A);
  static const Color inkOnDark       = Color(0xFFF0EDE5);
  static const Color inkOnDarkSub    = Color(0xFFA0A8A2);
  static const Color positive        = Color(0xFF1A5E3A);
  static const Color negative        = Color(0xFF8B2E2E);
  static const Color negativeLight   = Color(0xFFCF8484);
  static const Color warning         = Color(0xFFA67B2E);
}

/// Backward-compatible aliases — migrate screens to colorScheme roles.
class AppColors {
  AppColors._();
  static const Color green = GolfPalette.fairwayGreen;
  static const Color amber = GolfPalette.birdieGold;
}

// ─── Color schemes ──────────────────────────────────────────────────────────

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

// ─── Typography ─────────────────────────────────────────────────────────────

TextTheme _buildTextTheme({required bool isDark}) {
  final ink    = isDark ? GolfPalette.inkOnDark    : GolfPalette.inkPrimary;
  final inkSub = isDark ? GolfPalette.inkOnDarkSub : GolfPalette.inkSecondary;

  return TextTheme(
    // Playfair Display — display, headline
    displayLarge:  GoogleFonts.playfairDisplay(fontSize: 57, fontWeight: FontWeight.w400, color: ink, letterSpacing: -0.25, height: 1.12),
    displayMedium: GoogleFonts.playfairDisplay(fontSize: 45, fontWeight: FontWeight.w400, color: ink, height: 1.16),
    displaySmall:  GoogleFonts.playfairDisplay(fontSize: 36, fontWeight: FontWeight.w400, color: ink, height: 1.22),
    headlineLarge: GoogleFonts.playfairDisplay(fontSize: 32, fontWeight: FontWeight.w700, color: ink, height: 1.25),
    headlineMedium:GoogleFonts.playfairDisplay(fontSize: 28, fontWeight: FontWeight.w600, color: ink, height: 1.29),
    headlineSmall: GoogleFonts.playfairDisplay(fontSize: 24, fontWeight: FontWeight.w600, color: ink, height: 1.33),

    // Inter — title, body, label
    titleLarge:   GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w600, color: ink,    letterSpacing: 0,    height: 1.27),
    titleMedium:  GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: ink,    letterSpacing: 0.15, height: 1.5),
    titleSmall:   GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: ink,    letterSpacing: 0.1,  height: 1.43),
    bodyLarge:    GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w400, color: ink,    letterSpacing: 0.5,  height: 1.5),
    bodyMedium:   GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400, color: ink,    letterSpacing: 0.25, height: 1.43),
    bodySmall:    GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400, color: inkSub, letterSpacing: 0.4,  height: 1.33),
    labelLarge:   GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: ink,    letterSpacing: 1.5,  height: 1.43),
    labelMedium:  GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: inkSub, letterSpacing: 1.25, height: 1.33),
    labelSmall:   GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: inkSub, letterSpacing: 1.5,  height: 1.45),
  );
}

// ─── Monospaced number helpers ───────────────────────────────────────────────

/// Use for ALL yardages, scores, stroke counts, distances.
/// Tabular digits align vertically across rows.
class GolfTextStyles {
  GolfTextStyles._();

  static TextStyle tabularNum(
    BuildContext context, {
    double fontSize = 24,
    FontWeight fontWeight = FontWeight.w700,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GoogleFonts.robotoMono(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: isDark ? GolfPalette.inkOnDark : GolfPalette.inkPrimary,
    );
  }

  static TextStyle scorePositive(BuildContext context, {double fontSize = 20}) =>
      tabularNum(context, fontSize: fontSize)
          .copyWith(color: GolfPalette.positive);

  static TextStyle scoreNegative(BuildContext context, {double fontSize = 20}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return tabularNum(context, fontSize: fontSize)
        .copyWith(color: isDark ? GolfPalette.negativeLight : GolfPalette.negative);
  }

  static TextStyle yardage(BuildContext context, {double fontSize = 18}) =>
      tabularNum(context, fontSize: fontSize, fontWeight: FontWeight.w600);
}

// ─── ThemeData ───────────────────────────────────────────────────────────────

ThemeData buildGolfTheme({Brightness brightness = Brightness.light}) {
  final isDark = brightness == Brightness.dark;
  final cs = isDark ? _darkScheme() : _lightScheme();
  final tt = _buildTextTheme(isDark: isDark);

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: cs,
    textTheme: tt,
    scaffoldBackgroundColor: isDark ? GolfPalette.deepForest : GolfPalette.cream,

    // ── AppBar ─────────────────────────────────────────────────
    appBarTheme: AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0.5,
      backgroundColor: isDark ? GolfPalette.fairwayDark : GolfPalette.fairwayGreen,
      foregroundColor: Colors.white,
      centerTitle: true,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      titleTextStyle: GoogleFonts.playfairDisplay(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: Colors.white,
        letterSpacing: 0.15,
      ),
    ),

    // ── NavigationBar ──────────────────────────────────────────
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: isDark ? GolfPalette.forestElevated : GolfPalette.creamElevated,
      indicatorColor: cs.primaryContainer,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return IconThemeData(color: cs.onPrimaryContainer, size: 24);
        }
        return IconThemeData(color: cs.onSurfaceVariant, size: 24);
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: cs.primary, letterSpacing: 0.5);
        }
        return GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: cs.onSurfaceVariant, letterSpacing: 0.5);
      }),
    ),

    // ── Card ───────────────────────────────────────────────────
    cardTheme: CardTheme(
      color: isDark ? GolfPalette.forestElevated : GolfPalette.creamElevated,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDark ? GolfPalette.forestHairline : GolfPalette.hairline,
          width: 0.5,
        ),
      ),
    ),

    // ── Chips ──────────────────────────────────────────────────
    chipTheme: ChipThemeData(
      backgroundColor: isDark ? GolfPalette.forestSunken : GolfPalette.creamSunken,
      selectedColor: isDark ? GolfPalette.fairwayGreen : GolfPalette.fairwayGreen,
      secondarySelectedColor: cs.primaryContainer,
      checkmarkColor: GolfPalette.birdieGold,
      labelStyle: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: isDark ? GolfPalette.inkOnDark : GolfPalette.inkPrimary,
      ),
      secondaryLabelStyle: GoogleFonts.inter(
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
      showCheckmark: false,
    ),

    // ── Elevated button (primary CTA) ──────────────────────────
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size.fromHeight(56),
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        disabledBackgroundColor: cs.surfaceContainerHigh,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.5),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      ),
    ),

    // ── Outlined button (secondary) ────────────────────────────
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(56),
        foregroundColor: cs.primary,
        side: BorderSide(color: cs.primary, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.5),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      ),
    ),

    // ── Text button ────────────────────────────────────────────
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: cs.primary,
        textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 0.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        minimumSize: const Size(0, 44),
      ),
    ),

    // ── Filled button ──────────────────────────────────────────
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(56),
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.5),
      ),
    ),

    // ── Input decoration ───────────────────────────────────────
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
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
      labelStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: isDark ? GolfPalette.inkOnDarkSub : GolfPalette.inkSecondary),
      hintStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400, color: isDark ? GolfPalette.inkOnDarkSub : GolfPalette.inkTertiary),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),

    // ── Dividers ───────────────────────────────────────────────
    dividerTheme: DividerThemeData(
      color: isDark ? GolfPalette.forestHairline : GolfPalette.hairline,
      thickness: 0.5,
      space: 0,
    ),

    // ── SnackBar ───────────────────────────────────────────────
    snackBarTheme: SnackBarThemeData(
      backgroundColor: isDark ? GolfPalette.forestElevated : GolfPalette.inkPrimary,
      contentTextStyle: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: isDark ? GolfPalette.inkOnDark : GolfPalette.cream,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      behavior: SnackBarBehavior.floating,
      elevation: 4,
    ),

    // ── ListTile ───────────────────────────────────────────────
    listTileTheme: ListTileThemeData(
      tileColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      minVerticalPadding: 12,
    ),

    // ── Bottom sheet ───────────────────────────────────────────
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: isDark ? GolfPalette.forestElevated : GolfPalette.creamElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      elevation: 0,
      surfaceTintColor: Colors.transparent,
    ),

    // ── Floating Action Button ─────────────────────────────────
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: cs.primary,
      foregroundColor: cs.onPrimary,
      elevation: 2,
      shape: const CircleBorder(),
    ),
  );
}
```

---

## 4. Component recipes

### 4.1 Stat row (Min / Avg / Max)

```dart
/// Used in My Bag and future stats summaries.
Row(
  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  children: [
    _StatCol(label: 'MIN', value: '${club.minDistance.round()}'),
    _StatCol(label: 'AVG', value: '${club.avgDistance.round()}'),
    _StatCol(label: 'MAX', value: '${club.maxDistance.round()}'),
  ],
)

class _StatCol extends StatelessWidget {
  const _StatCol({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(letterSpacing: 1.5)),
        const SizedBox(height: 2),
        Text('$value yds', style: GolfTextStyles.yardage(context, fontSize: 20)),
      ],
    );
  }
}
```

### 4.2 Hole HUD banner

```dart
/// Big hole number + score inline, used in On Course header.
Container(
  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  decoration: BoxDecoration(
    color: Theme.of(context).colorScheme.surfaceContainer,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: Theme.of(context).colorScheme.outline, width: 0.5),
  ),
  child: Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text('Hole $_holeNumber', style: Theme.of(context).textTheme.headlineSmall),
      Text('Par $_par', style: Theme.of(context).textTheme.titleMedium),
      Text('Total: $_roundTotal', style: GolfTextStyles.tabularNum(context, fontSize: 18)),
    ],
  ),
)
```

### 4.3 Section header (uppercase, tracked)

```dart
Padding(
  padding: const EdgeInsets.only(top: 16, bottom: 8),
  child: Text(
    'CLUB',
    style: Theme.of(context).textTheme.labelLarge,
  ),
)
```

### 4.4 Score status chip (scorecard)

```dart
/// Shows vs-par result — green for under, red for over.
Container(
  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  decoration: BoxDecoration(
    color: vsParScore < 0
      ? GolfPalette.positive.withOpacity(0.12)
      : GolfPalette.negative.withOpacity(0.12),
    borderRadius: BorderRadius.circular(100),
  ),
  child: Text(
    vsParScore < 0 ? '$vsParScore' : '+$vsParScore',
    style: vsParScore < 0
      ? GolfTextStyles.scorePositive(context, fontSize: 14)
      : GolfTextStyles.scoreNegative(context, fontSize: 14),
  ),
)
```

---

## 5. Do / Don't

| ✅ Do | ❌ Don't |
| :--- | :--- |
| Use `colorScheme.primary`, `colorScheme.surface`, `colorScheme.onSurfaceVariant` for colors | Hardcode `AppColors.green` or `Color(0xFF...)` in screen widgets |
| Use `GolfTextStyles.tabularNum(context)` for yardages and scores | Use `TextStyle(fontWeight: FontWeight.bold)` for numbers — use Roboto Mono |
| Use `GolfPalette.negative` (burgundy) for errors | Use `Colors.red` for errors |
| `FilledButton` / `ElevatedButton` for the **one** primary CTA per screen | Stack two `ElevatedButton`s — one primary CTA max |
| `showCheckmark: false` on `ChoiceChip` — selection shown by background color | Let the default checkmark appear alongside the selection color |
| Prefer `surfaceContainer` card bg | Use `Card` default elevation that creates a shadow blob |
| `minVerticalPadding: 12` on `ListTile` for touch target | Bare `Text` rows without tap area |
| Playfair Display for screen title or section header | Playfair Display inside a `TextField`, chip, or button label |
| `behavior: SnackBarBehavior.floating` with rounded corners | Full-width snackbar snapped to bottom edge |

---

## 6. Flutter `Key` naming convention

Pattern: **`[screen]-[element]-[purpose]`** in kebab-case.

| Screen | Example key string | Widget |
| :--- | :--- | :--- |
| My Bag | `bag-category-chip-wood` | `ChoiceChip` |
| My Bag | `bag-club-card-driver` | `Card` |
| My Bag | `bag-notes-field-driver` | `TextField` |
| My Bag | `bag-save-notes-btn-driver` | `TextButton` |
| On Course | `oncourse-course-name-field` | `TextField` |
| On Course | `oncourse-par-chip-4` | `ChoiceChip` |
| On Course | `oncourse-lie-chip-fairway` | `ChoiceChip` |
| On Course | `oncourse-record-shot-btn` | `ElevatedButton` |
| On Course | `oncourse-penalty-1-btn` | `OutlinedButton` |
| On Course | `oncourse-mulligan-btn` | `OutlinedButton` |
| On Course | `oncourse-concede-btn` | `OutlinedButton` |
| On Course | `oncourse-finish-hole-btn` | `ElevatedButton` |
| Scorecard | `scorecard-hole-tile-{n}` | table row / `InkWell` |
| Scorecard | `scorecard-new-round-btn` | `OutlinedButton` |
| Range | `range-club-chip-{clubId}` | `ChoiceChip` |
| Range | `range-shot-counter-increment` | `IconButton` |
| Range | `range-min-field` | `TextField` |
| Range | `range-avg-field` | `TextField` |
| Range | `range-max-field` | `TextField` |
| Range | `range-save-drill-btn` | `ElevatedButton` |
