import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// MateEazy brand palette (shared with the mobile app): coral action colour,
/// deep plum ink, warm cream canvas.
abstract final class BrandColors {
  static const coral = Color(0xFFFF6B5B);
  static const coralPressed = Color(0xFFE85A4B);
  static const gold = Color(0xFFF4B740);
  static const success = Color(0xFF2E9E6B);

  static const plum = Color(0xFF2B1B3D);
  static const plumSoft = Color(0xFF3A294C);
  static const plumRaised = Color(0xFF473457);

  static const cream = Color(0xFFFBF6F1);
  static const creamDeep = Color(0xFFF3EAE0);
  static const line = Color(0xFFE9DED3);
  static const muted = Color(0xFF7D7088);
  static const mutedDark = Color(0xFFC1B0CC);
  static const creamText = Color(0xFFFFF8F0);
}

abstract final class AppTheme {
  static final light = _build(Brightness.light);
  static final dark = _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final background = isDark ? BrandColors.plum : BrandColors.cream;
    final surface = isDark ? BrandColors.plumSoft : Colors.white;
    final ink = isDark ? BrandColors.creamText : BrandColors.plum;
    final muted = isDark ? BrandColors.mutedDark : BrandColors.muted;
    final line = isDark ? BrandColors.plumRaised : BrandColors.line;
    final fill = isDark ? BrandColors.plumRaised : BrandColors.creamDeep;

    final scheme = ColorScheme.fromSeed(
      seedColor: BrandColors.coral,
      brightness: brightness,
    ).copyWith(
      primary: isDark ? BrandColors.coral : BrandColors.coralPressed,
      onPrimary: Colors.white,
      primaryContainer: isDark
          ? const Color(0xFF533443)
          : const Color(0xFFFFE8DE),
      onPrimaryContainer: isDark ? BrandColors.creamText : BrandColors.plum,
      secondary: BrandColors.gold,
      surface: surface,
      onSurface: ink,
      onSurfaceVariant: muted,
      surfaceContainerLowest: surface,
      surfaceContainerLow: surface,
      surfaceContainer: fill,
      surfaceContainerHigh: fill,
      surfaceContainerHighest: fill,
      outline: line,
      outlineVariant: line,
      error: const Color(0xFFD9432F),
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
    );

    final text = GoogleFonts.poppinsTextTheme(base.textTheme).apply(
      bodyColor: ink,
      displayColor: ink,
    );
    final textTheme = text.copyWith(
      headlineLarge: text.headlineLarge?.copyWith(fontWeight: FontWeight.w700),
      headlineMedium: text.headlineMedium?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
      ),
      headlineSmall: text.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
      titleLarge: text.titleLarge?.copyWith(fontWeight: FontWeight.w600),
      titleMedium: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      titleSmall: text.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      bodySmall: text.bodySmall?.copyWith(color: muted),
      labelLarge: text.labelLarge?.copyWith(fontWeight: FontWeight.w600),
    );

    final radius = BorderRadius.circular(12);
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: color, width: width),
        );

    return base.copyWith(
      scaffoldBackgroundColor: background,
      canvasColor: background,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      dividerTheme: DividerThemeData(color: line, thickness: 1, space: 1),
      iconTheme: IconThemeData(color: ink),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: ink,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: line),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: muted,
        shape: RoundedRectangleBorder(borderRadius: radius),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? BrandColors.plumRaised : Colors.white,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        labelStyle: TextStyle(color: muted),
        hintStyle: TextStyle(color: muted),
        border: border(line),
        enabledBorder: border(line),
        focusedBorder: border(scheme.primary, 1.6),
        errorBorder: border(scheme.error),
        focusedErrorBorder: border(scheme.error, 1.6),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 46),
          padding: const EdgeInsets.symmetric(horizontal: 22),
          shape: RoundedRectangleBorder(borderRadius: radius),
          textStyle: textTheme.labelLarge,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(0, 46),
          shape: RoundedRectangleBorder(borderRadius: radius),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ink,
          minimumSize: const Size(0, 46),
          side: BorderSide(color: line),
          shape: RoundedRectangleBorder(borderRadius: radius),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          shape: RoundedRectangleBorder(borderRadius: radius),
          textStyle: textTheme.labelLarge,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: muted),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: fill,
        side: BorderSide.none,
        labelStyle: textTheme.labelMedium?.copyWith(color: ink),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shadowColor: BrandColors.plum.withValues(alpha: 0.25),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: textTheme.titleLarge,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: line),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: BrandColors.plum,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: BrandColors.creamText,
        ),
        shape: RoundedRectangleBorder(borderRadius: radius),
      ),
      dataTableTheme: DataTableThemeData(
        headingRowColor: WidgetStatePropertyAll(fill),
        headingTextStyle: textTheme.labelLarge?.copyWith(color: muted),
        dividerThickness: 1,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: scheme.primary,
        unselectedLabelColor: muted,
        indicatorColor: scheme.primary,
        dividerColor: line,
        labelStyle: textTheme.labelLarge,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? Colors.white : muted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? scheme.primary : fill,
        ),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: scheme.primary),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStatePropertyAll(muted.withValues(alpha: 0.4)),
        radius: const Radius.circular(8),
      ),
    );
  }
}
