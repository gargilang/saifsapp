import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ── Warna dark ───────────────────────────────────────────────────────────────
const _dBg          = Color(0xFF111318); // surface (background utama)
const _dSurface     = Color(0xFF1C1F26); // surfaceContainer (kartu)
const _dSurfaceHigh = Color(0xFF252A34); // surfaceContainerHighest (input, chip)
const _gold         = Color(0xFFF5B942);
const _goldCont     = Color(0xFF7A5C1E);
const _onGold       = Color(0xFF1C1600);
const _dOnSurface   = Color(0xFFE8E8E8);
const _dOnSurfVar   = Color(0xFF8A8F9E);
const _dError       = Color(0xFFFF6B6B);
const _green        = Color(0xFF34D399);

// ── Warna light ──────────────────────────────────────────────────────────────
const _lBg          = Color(0xFFFAFAFA);
const _lSurface     = Color(0xFFFFFFFF);
const _lSurfaceHigh = Color(0xFFF0F2F5);
const _lightGold    = Color(0xFFB8860B);
const _lOnSurface   = Color(0xFF111318);
const _lOnSurfVar   = Color(0xFF5A5F6E);

ThemeData buildTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;

  final colorScheme = isDark
      ? ColorScheme.dark(
          brightness: Brightness.dark,
          surface: _dBg,
          surfaceContainer: _dSurface,
          surfaceContainerHighest: _dSurfaceHigh,
          primary: _gold,
          primaryContainer: _goldCont,
          onPrimary: _onGold,
          onSurface: _dOnSurface,
          onSurfaceVariant: _dOnSurfVar,
          error: _dError,
          onError: _onGold,
          tertiary: _green,
          onTertiary: const Color(0xFF003322),
        )
      : ColorScheme.light(
          brightness: Brightness.light,
          surface: _lBg,
          surfaceContainer: _lSurface,
          surfaceContainerHighest: _lSurfaceHigh,
          primary: _lightGold,
          primaryContainer: const Color(0xFFFFE082),
          onPrimary: const Color(0xFF1C1600),
          onSurface: _lOnSurface,
          onSurfaceVariant: _lOnSurfVar,
          error: const Color(0xFFD32F2F),
          onError: Colors.white,
          tertiary: const Color(0xFF1B7A5A),
          onTertiary: Colors.white,
        );

  final base = isDark ? ThemeData.dark() : ThemeData.light();

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    textTheme: GoogleFonts.interTextTheme(base.textTheme).copyWith(
      displayLarge: GoogleFonts.inter(
          fontSize: 40, fontWeight: FontWeight.w700, letterSpacing: -1.0,
          color: colorScheme.onSurface),
      displayMedium: GoogleFonts.inter(
          fontSize: 32, fontWeight: FontWeight.w700, letterSpacing: -0.5,
          color: colorScheme.onSurface),
      titleLarge: GoogleFonts.inter(
          fontSize: 20, fontWeight: FontWeight.w600, color: colorScheme.onSurface),
      titleMedium: GoogleFonts.inter(
          fontSize: 16, fontWeight: FontWeight.w600, color: colorScheme.onSurface),
      bodyLarge: GoogleFonts.inter(
          fontSize: 15, fontWeight: FontWeight.w400, color: colorScheme.onSurface),
      bodyMedium: GoogleFonts.inter(
          fontSize: 13, fontWeight: FontWeight.w400,
          color: colorScheme.onSurfaceVariant),
      labelLarge: GoogleFonts.inter(
          fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.3,
          color: colorScheme.onSurface),
      labelMedium: GoogleFonts.inter(
          fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.3,
          color: colorScheme.onSurfaceVariant),
      labelSmall: GoogleFonts.inter(
          fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.5,
          color: colorScheme.onSurfaceVariant),
    ),
    scaffoldBackgroundColor: colorScheme.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: colorScheme.surface,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: GoogleFonts.inter(
          fontSize: 18, fontWeight: FontWeight.w600,
          color: colorScheme.onSurface),
      iconTheme: IconThemeData(color: colorScheme.onSurface),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: colorScheme.surfaceContainer,
      indicatorColor: colorScheme.primaryContainer,
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return IconThemeData(color: colorScheme.primary);
        }
        return IconThemeData(color: colorScheme.onSurfaceVariant);
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return GoogleFonts.inter(
              fontSize: 12, fontWeight: FontWeight.w600,
              color: colorScheme.primary);
        }
        return GoogleFonts.inter(
            fontSize: 12, fontWeight: FontWeight.w400,
            color: colorScheme.onSurfaceVariant);
      }),
    ),
    cardTheme: CardThemeData(
      color: colorScheme.surfaceContainer,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.surfaceContainerHighest, width: 1),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: colorScheme.primary,
        side: BorderSide(color: colorScheme.primary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        minimumSize: const Size(0, 44),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colorScheme.surfaceContainerHighest,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.error, width: 2),
      ),
      labelStyle: GoogleFonts.inter(color: colorScheme.onSurfaceVariant),
      hintStyle: GoogleFonts.inter(color: colorScheme.onSurfaceVariant),
    ),
    chipTheme: ChipThemeData(
      shape: const StadiumBorder(),
      selectedColor: colorScheme.primaryContainer,
      labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
    ),
    listTileTheme: const ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(horizontal: 16),
    ),
    dividerTheme: DividerThemeData(
      color: colorScheme.surfaceContainerHighest,
      thickness: 1,
      space: 1,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.onPrimary,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected) ? colorScheme.primary : null),
      trackColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected)
              ? colorScheme.primaryContainer
              : null),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        selectedBackgroundColor: colorScheme.primaryContainer,
        selectedForegroundColor: colorScheme.primary,
      ),
    ),
  );
}
