import 'package:flutter/material.dart';

/// ════════════════════════════════════════════════════════════════════════
///  TDLF-Educ · "Aurora Glass" design system
///  Indigo → Violet brand · frosted glass surfaces · soft aurora glows
/// ════════════════════════════════════════════════════════════════════════

/// Raw brand hues used across gradients and accents.
class AppPalette {
  AppPalette._();

  static const indigo = Color(0xFF6366F1);
  static const indigoDeep = Color(0xFF4F46E5);
  static const violet = Color(0xFF8B5CF6);
  static const violetDeep = Color(0xFF7C3AED);
  static const purple = Color(0xFFA855F7);
  static const magenta = Color(0xFFD946EF);
  static const cyan = Color(0xFF22D3EE);
  static const pink = Color(0xFFEC4899);
}

/// Theme-aware decoration tokens (glass fills, gradients, aurora glow colors).
/// Pulled from any `BuildContext` via `AppDecoration.of(context)`.
@immutable
class AppDecoration extends ThemeExtension<AppDecoration> {
  final Color glassFill;
  final Color glassFillStrong;
  final Color glassBorder;
  final Color glassHighlight;
  final List<Color> brandGradient;
  final List<Color> heroGradient;
  final List<Color> auroraColors;
  final Color cardShadow;
  final Color glowShadow;

  const AppDecoration({
    required this.glassFill,
    required this.glassFillStrong,
    required this.glassBorder,
    required this.glassHighlight,
    required this.brandGradient,
    required this.heroGradient,
    required this.auroraColors,
    required this.cardShadow,
    required this.glowShadow,
  });

  static AppDecoration of(BuildContext context) =>
      Theme.of(context).extension<AppDecoration>()!;

  LinearGradient get brand => LinearGradient(
        colors: brandGradient,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  LinearGradient get hero => LinearGradient(
        colors: heroGradient,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  /// Subtle frosted-card shadow.
  List<BoxShadow> get softShadow => [
        BoxShadow(
          color: cardShadow,
          blurRadius: 24,
          offset: const Offset(0, 12),
        ),
      ];

  /// Colored glow for primary CTAs / hero elements.
  List<BoxShadow> glow([double opacity = 0.45]) => [
        BoxShadow(
          color: glowShadow.withValues(alpha: opacity),
          blurRadius: 28,
          offset: const Offset(0, 14),
        ),
      ];

  @override
  AppDecoration copyWith({
    Color? glassFill,
    Color? glassFillStrong,
    Color? glassBorder,
    Color? glassHighlight,
    List<Color>? brandGradient,
    List<Color>? heroGradient,
    List<Color>? auroraColors,
    Color? cardShadow,
    Color? glowShadow,
  }) {
    return AppDecoration(
      glassFill: glassFill ?? this.glassFill,
      glassFillStrong: glassFillStrong ?? this.glassFillStrong,
      glassBorder: glassBorder ?? this.glassBorder,
      glassHighlight: glassHighlight ?? this.glassHighlight,
      brandGradient: brandGradient ?? this.brandGradient,
      heroGradient: heroGradient ?? this.heroGradient,
      auroraColors: auroraColors ?? this.auroraColors,
      cardShadow: cardShadow ?? this.cardShadow,
      glowShadow: glowShadow ?? this.glowShadow,
    );
  }

  static List<Color> _lerpColors(List<Color> a, List<Color> b, double t) {
    final n = a.length < b.length ? a.length : b.length;
    return List.generate(n, (i) => Color.lerp(a[i], b[i], t)!);
  }

  @override
  AppDecoration lerp(ThemeExtension<AppDecoration>? other, double t) {
    if (other is! AppDecoration) return this;
    return AppDecoration(
      glassFill: Color.lerp(glassFill, other.glassFill, t)!,
      glassFillStrong: Color.lerp(glassFillStrong, other.glassFillStrong, t)!,
      glassBorder: Color.lerp(glassBorder, other.glassBorder, t)!,
      glassHighlight: Color.lerp(glassHighlight, other.glassHighlight, t)!,
      brandGradient: _lerpColors(brandGradient, other.brandGradient, t),
      heroGradient: _lerpColors(heroGradient, other.heroGradient, t),
      auroraColors: _lerpColors(auroraColors, other.auroraColors, t),
      cardShadow: Color.lerp(cardShadow, other.cardShadow, t)!,
      glowShadow: Color.lerp(glowShadow, other.glowShadow, t)!,
    );
  }
}

/// Builds the light & dark [ThemeData] for the app.
class AppTheme {
  AppTheme._();

  // ── Light ────────────────────────────────────────────────────────────────
  static ThemeData get light {
    final cs = ColorScheme.fromSeed(
      seedColor: AppPalette.indigo,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppPalette.indigoDeep,
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFFE6E3FF),
      onPrimaryContainer: const Color(0xFF211C5E),
      secondary: AppPalette.violet,
      onSecondary: Colors.white,
      secondaryContainer: const Color(0xFFEFE6FF),
      onSecondaryContainer: const Color(0xFF3B1E66),
      tertiary: AppPalette.violetDeep,
      onTertiary: Colors.white,
      tertiaryContainer: const Color(0xFFDAF4FB),
      onTertiaryContainer: const Color(0xFF0C3A45),
      surface: const Color(0xFFF4F3FC),
      onSurface: const Color(0xFF1B1830),
      onSurfaceVariant: const Color(0xFF6B6786),
      surfaceContainerLowest: Colors.white,
      surfaceContainerLow: Colors.white,
      surfaceContainer: const Color(0xFFFBFAFF),
      surfaceContainerHigh: Colors.white,
      surfaceContainerHighest: Colors.white,
      outline: const Color(0xFFDAD7EC),
      outlineVariant: const Color(0xFFE9E6F5),
      error: const Color(0xFFE11D48),
      onError: Colors.white,
      errorContainer: const Color(0xFFFFE1E6),
      onErrorContainer: const Color(0xFF5C0418),
    );

    const decoration = AppDecoration(
      glassFill: Color(0x8CFFFFFF),
      glassFillStrong: Color(0xCCFFFFFF),
      glassBorder: Color(0xB3FFFFFF),
      glassHighlight: Color(0x80FFFFFF),
      brandGradient: [Color(0xFF4F46E5), Color(0xFF7C3AED), Color(0xFFA855F7)],
      heroGradient: [Color(0xFF5B4BE8), Color(0xFF8A4FE0), Color(0xFFB14DE0)],
      auroraColors: [
        AppPalette.indigo,
        AppPalette.purple,
        AppPalette.cyan,
        AppPalette.pink,
      ],
      cardShadow: Color(0x1A4F46E5),
      glowShadow: Color(0xFF6D5DFB),
    );

    return _build(cs, decoration, Brightness.light,
        inputFill: const Color(0xFFF1EFFB));
  }

  // ── Dark ─────────────────────────────────────────────────────────────────
  static ThemeData get dark {
    final cs = ColorScheme.fromSeed(
      seedColor: AppPalette.indigo,
      brightness: Brightness.dark,
    ).copyWith(
      primary: const Color(0xFF8B85FF),
      onPrimary: const Color(0xFF14112E),
      primaryContainer: const Color(0xFF2D2A66),
      onPrimaryContainer: const Color(0xFFDEDBFF),
      secondary: const Color(0xFFB39DFF),
      onSecondary: const Color(0xFF1F1147),
      secondaryContainer: const Color(0xFF362860),
      onSecondaryContainer: const Color(0xFFEADFFF),
      tertiary: const Color(0xFFC084FC),
      onTertiary: const Color(0xFF2A0E4A),
      tertiaryContainer: const Color(0xFF154A57),
      onTertiaryContainer: const Color(0xFFBFEFF9),
      surface: const Color(0xFF0D0B1C),
      onSurface: const Color(0xFFECEAFB),
      onSurfaceVariant: const Color(0xFFA7A3C6),
      surfaceContainerLowest: const Color(0xFF090814),
      surfaceContainerLow: const Color(0xFF141128),
      surfaceContainer: const Color(0xFF171433),
      surfaceContainerHigh: const Color(0xFF1D1940),
      surfaceContainerHighest: const Color(0xFF231E49),
      outline: const Color(0xFF36315E),
      outlineVariant: const Color(0xFF272249),
      error: const Color(0xFFFF6B85),
      onError: const Color(0xFF3A0512),
      errorContainer: const Color(0xFF4C1626),
      onErrorContainer: const Color(0xFFFFD9DF),
    );

    const decoration = AppDecoration(
      glassFill: Color(0x12FFFFFF),
      glassFillStrong: Color(0x1FFFFFFF),
      glassBorder: Color(0x24FFFFFF),
      glassHighlight: Color(0x14FFFFFF),
      brandGradient: [Color(0xFF6E63FF), Color(0xFF9D6BFF), Color(0xFFC15CFF)],
      heroGradient: [Color(0xFF4F46E5), Color(0xFF7C3AED), Color(0xFFB14DE0)],
      auroraColors: [
        AppPalette.indigo,
        AppPalette.purple,
        AppPalette.cyan,
        AppPalette.magenta,
      ],
      cardShadow: Color(0x66000000),
      glowShadow: Color(0xFF7C74FF),
    );

    return _build(cs, decoration, Brightness.dark,
        inputFill: const Color(0xFF1B1740));
  }

  // ── Shared builder ─────────────────────────────────────────────────────────
  static ThemeData _build(
    ColorScheme cs,
    AppDecoration decoration,
    Brightness brightness, {
    required Color inputFill,
  }) {
    final textTheme = _textTheme(cs);

    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      brightness: brightness,
      scaffoldBackgroundColor: cs.surface,
      textTheme: textTheme,
      extensions: [decoration],
      splashColor: cs.primary.withValues(alpha: 0.08),
      highlightColor: cs.primary.withValues(alpha: 0.04),
      appBarTheme: AppBarTheme(
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
        foregroundColor: cs.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 21,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
          color: cs.onSurface,
        ),
        iconTheme: IconThemeData(color: cs.onSurface),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: cs.surfaceContainerHighest,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: cs.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: cs.error, width: 1.4),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: cs.error, width: 1.6),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
        prefixIconColor: cs.onSurfaceVariant,
        labelStyle: TextStyle(color: cs.onSurfaceVariant, fontSize: 14),
        floatingLabelStyle: TextStyle(color: cs.primary, fontSize: 14),
        hintStyle: TextStyle(
          color: cs.onSurfaceVariant.withValues(alpha: 0.6),
          fontSize: 14,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
          disabledBackgroundColor: cs.primary.withValues(alpha: 0.4),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
          minimumSize: const Size(0, 52),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle:
              const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: cs.primary,
          side: BorderSide(color: cs.outline),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          minimumSize: const Size(0, 52),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: cs.primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        elevation: 0,
        highlightElevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        height: 70,
        backgroundColor: Colors.transparent,
        indicatorColor: cs.primary.withValues(alpha: 0.16),
        surfaceTintColor: Colors.transparent,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          return IconThemeData(
            color: states.contains(WidgetState.selected)
                ? cs.primary
                : cs.onSurfaceVariant,
            size: 24,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          return TextStyle(
            fontSize: 11,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? cs.primary
                : cs.onSurfaceVariant,
          );
        }),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide(color: cs.outline.withValues(alpha: 0.4)),
      ),
      tabBarTheme: TabBarThemeData(
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: Colors.transparent,
        labelColor: cs.primary,
        unselectedLabelColor: cs.onSurfaceVariant,
        labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        unselectedLabelStyle:
            const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color: cs.primary, width: 3),
          insets: const EdgeInsets.symmetric(horizontal: 16),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? Colors.white : null),
        trackColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? cs.primary : null),
        trackOutlineColor:
            WidgetStateProperty.all(Colors.transparent),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          backgroundColor: WidgetStateProperty.resolveWith((states) =>
              states.contains(WidgetState.selected)
                  ? cs.primary
                  : Colors.transparent),
          foregroundColor: WidgetStateProperty.resolveWith((states) =>
              states.contains(WidgetState.selected)
                  ? cs.onPrimary
                  : cs.onSurfaceVariant),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: cs.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        titleTextStyle: TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.w700,
          color: cs.onSurface,
        ),
        contentTextStyle: TextStyle(
          fontSize: 14,
          height: 1.5,
          color: cs.onSurfaceVariant,
        ),
      ),
      dividerTheme: DividerThemeData(
        space: 1,
        thickness: 1,
        color: cs.outlineVariant,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: cs.primary,
        linearTrackColor: cs.surfaceContainerHighest,
        circularTrackColor: cs.surfaceContainerHighest,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: cs.inverseSurface,
        contentTextStyle: TextStyle(color: cs.onInverseSurface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: cs.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
    );
  }

  static TextTheme _textTheme(ColorScheme cs) {
    final base = ThemeData(brightness: cs.brightness).textTheme;
    return base
        .copyWith(
          displaySmall: const TextStyle(
              fontSize: 34, fontWeight: FontWeight.w800, letterSpacing: -0.8),
          headlineMedium: const TextStyle(
              fontSize: 27, fontWeight: FontWeight.w800, letterSpacing: -0.6),
          headlineSmall: const TextStyle(
              fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.4),
          titleLarge: const TextStyle(
              fontSize: 19, fontWeight: FontWeight.w700, letterSpacing: -0.3),
          titleMedium: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: -0.1),
          titleSmall:
              const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          bodyLarge: const TextStyle(fontSize: 15, height: 1.45),
          bodyMedium: const TextStyle(fontSize: 14, height: 1.45),
          labelLarge:
              const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        )
        .apply(
          bodyColor: cs.onSurface,
          displayColor: cs.onSurface,
        );
  }
}
