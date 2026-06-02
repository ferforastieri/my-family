import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

ThemeData buildAppTheme() {
  return ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      surface: Colors.white,
    ),
    scaffoldBackgroundColor: bgStart,
    useMaterial3: true,
    textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme).apply(
      bodyColor: foreground,
      displayColor: foreground,
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: false,
      elevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: foreground,
      surfaceTintColor: Colors.transparent,
    ),
    extensions: <ThemeExtension<dynamic>>[
      AppTextThemes(
        display: GoogleFonts.playfairDisplay(),
        body: GoogleFonts.inter(),
      ),
    ],
    cardTheme: CardThemeData(
      color: Colors.white.withValues(alpha: .90),
      elevation: 3,
      shadowColor: const Color(0x1aff69b4),
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: border),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
  );
}

class AppTextThemes extends ThemeExtension<AppTextThemes> {
  const AppTextThemes({required this.display, required this.body});

  final TextStyle display;
  final TextStyle body;

  @override
  AppTextThemes copyWith({TextStyle? display, TextStyle? body}) {
    return AppTextThemes(display: display ?? this.display, body: body ?? this.body);
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

