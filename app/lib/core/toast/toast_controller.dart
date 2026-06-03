import 'dart:async';

import 'package:flutter/foundation.dart';

enum ToastKind { success, error, info }

class AppToast {
  const AppToast({required this.message, required this.kind});

  final String message;
  final ToastKind kind;
}

class ToastController extends ChangeNotifier {
  AppToast? current;
  Timer? _timer;

  void success(String message) => show(message, ToastKind.success);
  void error(String message) => show(message, ToastKind.error);
  void info(String message) => show(message, ToastKind.info);
  void backendSuccess(String? message) {
    if (message?.trim().isNotEmpty == true) success(message!.trim());
  }

  void backendInfo(String? message) {
    if (message?.trim().isNotEmpty == true) info(message!.trim());
  }

  void show(String message, ToastKind kind) {
    _timer?.cancel();
    current = AppToast(message: message, kind: kind);
    notifyListeners();
    _timer = Timer(const Duration(seconds: 3), clear);
  }

  void clear() {
    _timer?.cancel();
    current = null;
    notifyListeners();
  }
}
