library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

export 'src/family_button.dart';
export 'src/family_buttons.dart';
export 'src/family_fields.dart';
export 'src/family_icons.dart';
export 'src/family_skeleton.dart';
export 'src/family_surfaces.dart';

const defaultPrimary = Color(0xff9f4d4d);
const paper = Color(0xfffefbf3);
const paperDeep = Color(0xfffbebdc);
const ink = Color(0xff542a30);

enum FamilyFont { nunitoSans, cormorantGaramond }

FamilyFont familyFontFromApi(String? value) => switch (value) {
  'cormorantGaramond' => FamilyFont.cormorantGaramond,
  _ => FamilyFont.nunitoSans,
};

ThemeData familyTheme({
  Color primary = defaultPrimary,
  FamilyFont font = FamilyFont.nunitoSans,
  Brightness brightness = Brightness.light,
}) {
  final dark = brightness == Brightness.dark;
  final base = ThemeData(brightness: brightness, useMaterial3: true);
  final textTheme = font == FamilyFont.cormorantGaramond
      ? GoogleFonts.cormorantGaramondTextTheme(base.textTheme)
      : GoogleFonts.nunitoSansTextTheme(base.textTheme);
  final surface = dark ? const Color(0xff321c1f) : paper;
  final foreground = dark ? paper : ink;
  return base.copyWith(
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      surface: surface,
      brightness: brightness,
    ),
    scaffoldBackgroundColor: surface,
    textTheme: textTheme.apply(bodyColor: foreground, displayColor: foreground),
    cardTheme: CardThemeData(
      color: dark ? const Color(0xff3a2023) : const Color(0xfffffdf8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: primary.withValues(alpha: .22)),
        borderRadius: BorderRadius.circular(18),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primary,
        side: BorderSide(color: primary.withValues(alpha: .55)),
        minimumSize: const Size(0, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    dropdownMenuTheme: DropdownMenuThemeData(
      menuStyle: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(surface),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    ),
    datePickerTheme: DatePickerThemeData(
      backgroundColor: surface,
      headerBackgroundColor: primary,
      headerForegroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: surface,
      selectedColor: primary.withValues(alpha: .14),
      side: BorderSide(color: primary.withValues(alpha: .22)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
    ),
  );
}

Color? parseFamilyColor(String? value) {
  if (value == null || !RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(value)) {
    return null;
  }
  return Color(int.parse('ff${value.substring(1)}', radix: 16));
}
