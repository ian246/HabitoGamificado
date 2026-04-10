import 'package:flutter/material.dart';
import 'app_colors.dart';

/// ─────────────────────────────────────────────────────────────
/// AppTheme — ThemeData Material 3
///
/// Uso no main.dart:
///   MaterialApp(
///     theme:      AppTheme.light,
///     darkTheme:  AppTheme.dark,
///     themeMode:  ThemeMode.system, // ou salvar preferência em SharedPreferences
///   )
/// ─────────────────────────────────────────────────────────────
abstract final class AppTheme {
  // ── Light ────────────────────────────────────────────────────
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor:   AppColors.seed,
      brightness:  Brightness.light,
      surface:     AppColors.background,
      primary:     AppColors.primary,
      onPrimary:   Colors.white,
      secondary:   AppColors.blueAccent,
      onSecondary: Colors.white,
      tertiary:    AppColors.streak,
      onSurface:   AppColors.textPrimary,
    ),
    scaffoldBackgroundColor: AppColors.background,
    cardTheme: _cardTheme(AppColors.surfaceCard, AppColors.surfaceHover),
    appBarTheme: _appBarTheme(
      background: AppColors.surfaceCard,
      foreground: AppColors.textPrimary,
    ),
    navigationBarTheme: _navBarTheme(
      background: AppColors.navBackground,
      indicator:  AppColors.surfaceHover,
      icon:       AppColors.textSecondary,
      selected:   AppColors.primary,
    ),
    floatingActionButtonTheme: _fabTheme(AppColors.primary),
    inputDecorationTheme: _inputTheme(AppColors.surfaceCard, AppColors.surfaceHover),
    checkboxTheme: _checkboxTheme(AppColors.primary),
    chipTheme: _chipTheme(AppColors.surfaceCard, AppColors.primary),
    dividerTheme: const DividerThemeData(color: AppColors.surfaceHover, thickness: 0.5),
    textTheme: _textTheme(AppColors.textPrimary, AppColors.textSecondary),
    extensions: const [HabitFlowColors.light],
  );

  // ── Dark ─────────────────────────────────────────────────────
  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor:   AppColors.seed,
      brightness:  Brightness.dark,
      surface:     AppColors.darkSurface,
      primary:     AppColors.primary,
      onPrimary:   Colors.white,
      secondary:   AppColors.blueAccent,
      onSecondary: Colors.white,
      tertiary:    AppColors.streak,
      onSurface:   const Color(0xFFD8EDE5),
    ),
    scaffoldBackgroundColor: AppColors.darkSurface,
    cardTheme: _cardTheme(AppColors.darkCard, AppColors.darkBorder),
    appBarTheme: _appBarTheme(
      background: AppColors.darkCard,
      foreground: const Color(0xFFD8EDE5),
    ),
    navigationBarTheme: _navBarTheme(
      background: AppColors.darkCard,
      indicator:  AppColors.darkBorder,
      icon:       const Color(0xFF8AADA4),
      selected:   AppColors.primary,
    ),
    floatingActionButtonTheme: _fabTheme(AppColors.primary),
    inputDecorationTheme: _inputTheme(AppColors.darkCard, AppColors.darkBorder),
    checkboxTheme: _checkboxTheme(AppColors.primary),
    chipTheme: _chipTheme(AppColors.darkCard, AppColors.primary),
    dividerTheme: const DividerThemeData(color: AppColors.darkBorder, thickness: 0.5),
    textTheme: _textTheme(const Color(0xFFD8EDE5), const Color(0xFF8AADA4)),
    extensions: const [HabitFlowColors.dark],
  );

  // ── Helpers privados ─────────────────────────────────────────
  static CardThemeData _cardTheme(Color bg, Color border) => CardThemeData(
    color: bg,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(color: border, width: 0.5),
    ),
    margin: const EdgeInsets.only(bottom: 10),
  );

  static AppBarTheme _appBarTheme({
    required Color background,
    required Color foreground,
  }) => AppBarTheme(
    backgroundColor: background,
    foregroundColor: foreground,
    elevation: 0,
    scrolledUnderElevation: 0,
    centerTitle: false,
    titleTextStyle: TextStyle(
      color: foreground,
      fontSize: 18,
      fontWeight: FontWeight.w600,
    ),
  );

  static NavigationBarThemeData _navBarTheme({
    required Color background,
    required Color indicator,
    required Color icon,
    required Color selected,
  }) => NavigationBarThemeData(
    backgroundColor: background,
    elevation: 0,
    height: 60,
    indicatorColor: indicator,
    iconTheme: WidgetStateProperty.resolveWith((states) {
      final isSelected = states.contains(WidgetState.selected);
      return IconThemeData(
        color: isSelected ? selected : icon,
        size: 22,
      );
    }),
    labelTextStyle: WidgetStateProperty.resolveWith((states) {
      final isSelected = states.contains(WidgetState.selected);
      return TextStyle(
        fontSize: 10,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
        color: isSelected ? selected : icon,
      );
    }),
  );

  static FloatingActionButtonThemeData _fabTheme(Color color) =>
    FloatingActionButtonThemeData(
      backgroundColor: color,
      foregroundColor: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );

  static InputDecorationTheme _inputTheme(Color fill, Color border) =>
    InputDecorationTheme(
      filled: true,
      fillColor: fill,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: border, width: 0.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: border, width: 0.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );

  static CheckboxThemeData _checkboxTheme(Color active) => CheckboxThemeData(
    fillColor: WidgetStateProperty.resolveWith((states) =>
      states.contains(WidgetState.selected) ? active : Colors.transparent),
    checkColor: WidgetStateProperty.all(Colors.white),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
    side: BorderSide(color: active.withAlpha(153), width: 1.5),
  );

  static ChipThemeData _chipTheme(Color bg, Color selected) => ChipThemeData(
    backgroundColor: bg,
    selectedColor: selected.withAlpha(30),
    labelStyle: const TextStyle(fontSize: 12),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    side: BorderSide(color: selected.withAlpha(60), width: 0.5),
  );

  static TextTheme _textTheme(Color primary, Color secondary) => TextTheme(
    displayLarge:  TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: primary),
    displayMedium: TextStyle(fontSize: 26, fontWeight: FontWeight.w600, color: primary),
    titleLarge:    TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: primary),
    titleMedium:   TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: primary),
    titleSmall:    TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: primary),
    bodyLarge:     TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: primary),
    bodyMedium:    TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: primary),
    bodySmall:     TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: secondary),
    labelLarge:    TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: primary),
    labelMedium:   TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: secondary),
    labelSmall:    TextStyle(fontSize: 10, fontWeight: FontWeight.w400, color: secondary),
  );
}

// ─────────────────────────────────────────────────────────────
// ThemeExtension — cores customizadas acessíveis via context
//
// Uso: Theme.of(context).extension<HabitFlowColors>()!.streak
// ─────────────────────────────────────────────────────────────
class HabitFlowColors extends ThemeExtension<HabitFlowColors> {
  final Color streak;
  final Color streakText;
  final Color cardBorder;
  final Color progressTrack;

  const HabitFlowColors({
    required this.streak,
    required this.streakText,
    required this.cardBorder,
    required this.progressTrack,
  });

  static const light = HabitFlowColors(
    streak:        AppColors.streak,
    streakText:    AppColors.streakDark,
    cardBorder:    AppColors.surfaceHover,
    progressTrack: AppColors.surfaceCard,
  );

  static const dark = HabitFlowColors(
    streak:        AppColors.streak,
    streakText:    Color(0xFFFFF3E0),
    cardBorder:    AppColors.darkBorder,
    progressTrack: AppColors.darkCard,
  );

  @override
  HabitFlowColors copyWith({
    Color? streak,
    Color? streakText,
    Color? cardBorder,
    Color? progressTrack,
  }) => HabitFlowColors(
    streak:        streak        ?? this.streak,
    streakText:    streakText    ?? this.streakText,
    cardBorder:    cardBorder    ?? this.cardBorder,
    progressTrack: progressTrack ?? this.progressTrack,
  );

  @override
  HabitFlowColors lerp(HabitFlowColors? other, double t) {
    if (other == null) return this;
    return HabitFlowColors(
      streak:        Color.lerp(streak,        other.streak,        t)!,
      streakText:    Color.lerp(streakText,    other.streakText,    t)!,
      cardBorder:    Color.lerp(cardBorder,    other.cardBorder,    t)!,
      progressTrack: Color.lerp(progressTrack, other.progressTrack, t)!,
    );
  }
}
