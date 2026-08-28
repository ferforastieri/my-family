import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ThemeColorChoice { floral }

enum AppFontChoice { moderna, logo }

class ThemeController extends ChangeNotifier {
  ThemeMode mode = ThemeMode.light;
  ThemeColorChoice color = ThemeColorChoice.floral;
  AppFontChoice font = AppFontChoice.moderna;
  Color primary = const Color(0xff9f4d4d);

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
    final tenantKey = kIsWeb &&
            Uri.base.pathSegments.length >= 2 &&
            Uri.base.pathSegments.first == 'f'
        ? Uri.base.pathSegments[1]
        : null;
    if (tenantKey != null) {
      final tenantPrimary = prefs.getString('tenant.$tenantKey.primary');
      if (tenantPrimary != null &&
          RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(tenantPrimary)) {
        primary =
            Color(int.parse('ff${tenantPrimary.substring(1)}', radix: 16));
      }
      final tenantFont = prefs.getString('tenant.$tenantKey.font');
      font = tenantFont == 'cormorantGaramond'
          ? AppFontChoice.logo
          : AppFontChoice.moderna;
    }
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

  Future<void> applyTenantTheme(
      {String? primaryColor, String? fontFamily, String? tenantKey}) async {
    if (primaryColor != null &&
        RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(primaryColor)) {
      primary = Color(int.parse('ff${primaryColor.substring(1)}', radix: 16));
    } else {
      primary = const Color(0xff9f4d4d);
    }
    font = fontFamily == 'cormorantGaramond'
        ? AppFontChoice.logo
        : AppFontChoice.moderna;
    notifyListeners();
    if (tenantKey != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          'tenant.$tenantKey.primary', primaryColor ?? '#9F4D4D');
      await prefs.setString(
          'tenant.$tenantKey.font', fontFamily ?? 'nunitoSans');
    }
  }
}
