import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models.dart';
import '../widgets/home_scene.dart';

enum ThemeColorChoice { floral }

enum AppFontChoice { moderna, logo }

class ThemePrimaryOption {
  const ThemePrimaryOption(this.label, this.color, this.hex);

  final String label;
  final Color color;
  final String hex;
}

const themePrimaryOptions = [
  ThemePrimaryOption('Vinho', Color(0xff9f4d4d), '#9F4D4D'),
  ThemePrimaryOption('Rosé', Color(0xffb45a6a), '#B45A6A'),
  ThemePrimaryOption('Oliva', Color(0xff6f7d5c), '#6F7D5C'),
  ThemePrimaryOption('Azul', Color(0xff4e6e81), '#4E6E81'),
  ThemePrimaryOption('Terracota', Color(0xffa86b3c), '#A86B3C'),
];

typedef PreferencesSaver = Future<void> Function({
  String? primaryColor,
  String? fontFamily,
  String? themeMode,
  String? homeScene,
});

class ThemeController extends ChangeNotifier {
  ThemeMode mode = ThemeMode.light;
  ThemeColorChoice color = ThemeColorChoice.floral;
  AppFontChoice font = AppFontChoice.moderna;
  Color primary = const Color(0xff9f4d4d);
  HomeScene scene = HomeScene.flowers;
  PreferencesSaver? savePreferences;

  Future<void> bootstrap() async {
    final prefs = await SharedPreferences.getInstance();
    mode = prefs.getString('theme.mode') == 'dark'
        ? ThemeMode.dark
        : ThemeMode.light;
    final savedFont = prefs.getString('theme.font');
    font = AppFontChoice.values.firstWhere(
      (item) => item.name == savedFont,
      orElse: () => AppFontChoice.moderna,
    );
    final savedPrimary = prefs.getString('theme.primary');
    if (savedPrimary != null && _hex.hasMatch(savedPrimary)) {
      primary = Color(int.parse('ff${savedPrimary.substring(1)}', radix: 16));
    }
    final savedScene = prefs.getString('theme.scene');
    scene = HomeScene.values.firstWhere(
      (item) => item.name == savedScene,
      orElse: () => HomeScene.flowers,
    );
    notifyListeners();
  }

  void applyPreferences(UserPreferences preferences) {
    mode = preferences.isDark ? ThemeMode.dark : ThemeMode.light;
    font = preferences.usesClassicFont
        ? AppFontChoice.logo
        : AppFontChoice.moderna;
    final saved = preferences.primaryColor;
    primary = saved != null && _hex.hasMatch(saved)
        ? Color(int.parse('ff${saved.substring(1)}', radix: 16))
        : const Color(0xff9f4d4d);
    scene = HomeScene.values.firstWhere(
      (item) => item.name == preferences.homeScene,
      orElse: () => HomeScene.flowers,
    );
    color = ThemeColorChoice.floral;
    notifyListeners();
  }

  void reset() {
    mode = ThemeMode.light;
    font = AppFontChoice.moderna;
    primary = const Color(0xff9f4d4d);
    scene = HomeScene.flowers;
    color = ThemeColorChoice.floral;
    notifyListeners();
  }

  Future<void> setMode(ThemeMode value) async {
    mode = value;
    notifyListeners();
    await _persist(themeMode: value == ThemeMode.dark ? 'dark' : 'light');
  }

  Future<void> setPrimary(Color value) async {
    primary = value;
    notifyListeners();
    await _persist(primaryColor: _hexFromColor(value));
  }

  Future<void> setFont(AppFontChoice value) async {
    font = value;
    notifyListeners();
    await _persist(
      fontFamily: value == AppFontChoice.logo
          ? 'cormorantGaramond'
          : 'nunitoSans',
    );
  }

  Future<void> setScene(HomeScene value) async {
    scene = value;
    notifyListeners();
    await _persist(homeScene: value.name);
  }

  Future<void> _persist({
    String? primaryColor,
    String? fontFamily,
    String? themeMode,
    String? homeScene,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (themeMode != null) await prefs.setString('theme.mode', themeMode);
    if (primaryColor != null) await prefs.setString('theme.primary', primaryColor);
    if (fontFamily != null) await prefs.setString('theme.font', fontFamily);
    if (homeScene != null) await prefs.setString('theme.scene', homeScene);
    try {
      await savePreferences?.call(
        primaryColor: primaryColor,
        fontFamily: fontFamily,
        themeMode: themeMode,
        homeScene: homeScene,
      );
    } catch (_) {
      // A preferência local permanece válida mesmo se a sincronização falhar.
    }
  }
}

final _hex = RegExp(r'^#[0-9a-fA-F]{6}$');

String _hexFromColor(Color color) {
  final value = color.toARGB32() & 0xffffff;
  return '#${value.toRadixString(16).padLeft(6, '0').toUpperCase()}';
}
