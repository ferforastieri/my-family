import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ThemeColorChoice { floral, rosa, azul, vermelho }

enum AppFontChoice { moderna, logo }

class ThemeController extends ChangeNotifier {
  ThemeMode mode = ThemeMode.light;
  ThemeColorChoice color = ThemeColorChoice.floral;
  AppFontChoice font = AppFontChoice.moderna;

  Future<void> bootstrap() async {
    final prefs = await SharedPreferences.getInstance();
    mode = prefs.getString('theme.mode') == 'dark'
        ? ThemeMode.dark
        : ThemeMode.light;
    final savedColor = prefs.getString('theme.color');
    color = ThemeColorChoice.values.firstWhere(
      (item) => item.name == savedColor,
      orElse: () => ThemeColorChoice.floral,
    );
    final savedFont = prefs.getString('theme.font');
    font = AppFontChoice.values.firstWhere(
      (item) => item.name == savedFont,
      orElse: () => AppFontChoice.moderna,
    );
    notifyListeners();
  }

  Future<void> setMode(ThemeMode value) async {
    mode = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'theme.mode',
      value == ThemeMode.dark ? 'dark' : 'light',
    );
  }

  Future<void> setColor(ThemeColorChoice value) async {
    color = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme.color', value.name);
  }

  Future<void> setFont(AppFontChoice value) async {
    font = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme.font', value.name);
  }
}
