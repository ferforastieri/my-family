import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ThemeColorChoice { rosa, azul, vermelho }

class ThemeController extends ChangeNotifier {
  ThemeMode mode = ThemeMode.light;
  ThemeColorChoice color = ThemeColorChoice.rosa;

  Future<void> bootstrap() async {
    final prefs = await SharedPreferences.getInstance();
    mode = prefs.getString('theme.mode') == 'dark'
        ? ThemeMode.dark
        : ThemeMode.light;
    color = ThemeColorChoice.values.firstWhere(
      (item) => item.name == prefs.getString('theme.color'),
      orElse: () => ThemeColorChoice.rosa,
    );
    notifyListeners();
  }

  Future<void> setMode(ThemeMode value) async {
    mode = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'theme.mode', value == ThemeMode.dark ? 'dark' : 'light');
  }

  Future<void> setColor(ThemeColorChoice value) async {
    color = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme.color', value.name);
  }
}
