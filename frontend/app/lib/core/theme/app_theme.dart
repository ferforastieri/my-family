import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart' as brand;
import 'theme_controller.dart';

ThemeData buildAppTheme({
  ThemeColorChoice color = ThemeColorChoice.floral,
  ThemeMode mode = ThemeMode.light,
  AppFontChoice font = AppFontChoice.moderna,
  Color primary = brand.primary,
}) {
  final palette = AppPalette.from(primary, mode);
  final usesLogoFont = font == AppFontChoice.logo;
  final baseTextTheme = ThemeData.light().textTheme;
  final textTheme = usesLogoFont
      ? GoogleFonts.cormorantGaramondTextTheme(baseTextTheme)
      : GoogleFonts.nunitoSansTextTheme(baseTextTheme);
  final textStyle =
      usesLogoFont ? GoogleFonts.cormorantGaramond() : GoogleFonts.nunitoSans();
  return ThemeData(
    brightness: mode == ThemeMode.dark ? Brightness.dark : Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: palette.primary,
      primary: palette.primary,
      surface: palette.card,
      brightness: mode == ThemeMode.dark ? Brightness.dark : Brightness.light,
    ),
    scaffoldBackgroundColor: palette.bgStart,
    useMaterial3: true,
    textTheme: textTheme.apply(
      bodyColor: palette.foreground,
      displayColor: palette.foreground,
    ),
    appBarTheme: AppBarTheme(
      centerTitle: false,
      elevation: 0,
      backgroundColor: palette.card,
      foregroundColor: palette.foreground,
      surfaceTintColor: Colors.transparent,
    ),
    extensions: <ThemeExtension<dynamic>>[
      AppTextThemes(
        display: textStyle.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -.3,
        ),
        body: textStyle,
      ),
      palette,
    ],
    cardTheme: CardThemeData(
      color: palette.card.withValues(alpha: .90),
      elevation: 3,
      shadowColor: palette.copper.withValues(alpha: .14),
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: palette.border),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: palette.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(foregroundColor: palette.foreground),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: palette.primary),
    ),
    inputDecorationTheme: InputDecorationTheme(
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      filled: true,
      fillColor: palette.card.withValues(alpha: .78),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: palette.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: palette.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: palette.primary, width: 1.4),
      ),
      labelStyle: TextStyle(color: palette.muted),
      hintStyle: TextStyle(color: palette.muted),
    ),
    dividerTheme: DividerThemeData(color: palette.border),
  );
}

class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.primary,
    required this.primaryDark,
    required this.bgStart,
    required this.bgEnd,
    required this.foreground,
    required this.muted,
    required this.border,
    required this.card,
    required this.petal,
    required this.copper,
    required this.gold,
  });

  final Color primary;
  final Color primaryDark;
  final Color bgStart;
  final Color bgEnd;
  final Color foreground;
  final Color muted;
  final Color border;
  final Color card;
  final Color petal;
  final Color copper;
  final Color gold;

  factory AppPalette.from(Color primaryColor, ThemeMode mode) {
    final isDark = mode == ThemeMode.dark;
    final primaryDark = Color.lerp(primaryColor, Colors.black, .16)!;
    final soft = Color.lerp(primaryColor, brand.bgStart, .68)!;
    final medium = Color.lerp(primaryColor, brand.bgStart, .34)!;
    final light = Color.lerp(primaryColor, brand.bgStart, .52)!;
    final base = (
      primaryColor,
      primaryDark,
      brand.bgStart,
      brand.bgEnd,
      const Color(0xff2d171b),
      const Color(0xff3a2023),
      soft,
      medium,
      light,
    );
    return AppPalette(
      primary: base.$1,
      primaryDark: base.$2,
      bgStart: isDark ? base.$5 : base.$3,
      bgEnd: isDark ? base.$6 : base.$4,
      foreground: isDark ? brand.bgStart : brand.foreground,
      muted:
          isDark ? base.$7 : Color.lerp(primaryColor, brand.foreground, .48)!,
      border: isDark
          ? base.$8.withValues(alpha: .34)
          : base.$1.withValues(alpha: .22),
      card: isDark ? const Color(0xff321c1f) : const Color(0xfffffdf8),
      petal: base.$7,
      copper: base.$8,
      gold: base.$9,
    );
  }

  @override
  AppPalette copyWith({
    Color? primary,
    Color? primaryDark,
    Color? bgStart,
    Color? bgEnd,
    Color? foreground,
    Color? muted,
    Color? border,
    Color? card,
    Color? petal,
    Color? copper,
    Color? gold,
  }) {
    return AppPalette(
      primary: primary ?? this.primary,
      primaryDark: primaryDark ?? this.primaryDark,
      bgStart: bgStart ?? this.bgStart,
      bgEnd: bgEnd ?? this.bgEnd,
      foreground: foreground ?? this.foreground,
      muted: muted ?? this.muted,
      border: border ?? this.border,
      card: card ?? this.card,
      petal: petal ?? this.petal,
      copper: copper ?? this.copper,
      gold: gold ?? this.gold,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      primary: Color.lerp(primary, other.primary, t)!,
      primaryDark: Color.lerp(primaryDark, other.primaryDark, t)!,
      bgStart: Color.lerp(bgStart, other.bgStart, t)!,
      bgEnd: Color.lerp(bgEnd, other.bgEnd, t)!,
      foreground: Color.lerp(foreground, other.foreground, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      border: Color.lerp(border, other.border, t)!,
      card: Color.lerp(card, other.card, t)!,
      petal: Color.lerp(petal, other.petal, t)!,
      copper: Color.lerp(copper, other.copper, t)!,
      gold: Color.lerp(gold, other.gold, t)!,
    );
  }
}

class AppTextThemes extends ThemeExtension<AppTextThemes> {
  const AppTextThemes({required this.display, required this.body});

  final TextStyle display;
  final TextStyle body;

  @override
  AppTextThemes copyWith({TextStyle? display, TextStyle? body}) {
    return AppTextThemes(
      display: display ?? this.display,
      body: body ?? this.body,
    );
  }

  @override
  AppTextThemes lerp(ThemeExtension<AppTextThemes>? other, double t) {
    if (other is! AppTextThemes) return this;
    return AppTextThemes(
      display: TextStyle.lerp(display, other.display, t)!,
      body: TextStyle.lerp(body, other.body, t)!,
    );
  }
}
