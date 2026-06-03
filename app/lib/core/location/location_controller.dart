import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:geolocator/geolocator.dart';

import '../auth/auth_controller.dart';
import '../api/socket_api_client.dart';
import '../socket/socket_client.dart';

class LocationController {
  LocationController(this.socket, this.auth);

  final SocketClient socket;
  final AuthController auth;
  late final SocketApiClient api = SocketApiClient(socket);
  final Battery _battery = Battery();
  StreamSubscription<Position>? _positionSubscription;
  Timer? _timer;
  bool _started = false;
  bool _authListenerBound = false;

  Future<void> bootstrap() async {
    _bindAuthListener();
    if (auth.user == null || socket.token == null) return;
    if (_started) return;
    _started = true;
    final permission = await _ensurePermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return;
    }

    unawaited(_sendCurrentPosition());
    _timer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => unawaited(_sendCurrentPosition()),
    );
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 20,
      ),
    ).listen((position) => unawaited(_sendPosition(position)));
  }

  void _bindAuthListener() {
    if (_authListenerBound) return;
    auth.addListener(_handleAuthChanged);
    _authListenerBound = true;
  }

  void _handleAuthChanged() {
    if (auth.user != null && socket.token != null) {
      unawaited(bootstrap());
    } else {
      stop();
    }
  }

  Future<LocationPermission> _ensurePermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return LocationPermission.denied;
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission;
  }

  Future<void> _sendCurrentPosition() async {
    if (auth.user == null || socket.token == null) return;
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      await _sendPosition(position);
    } catch (_) {
      //
    }
  }

  Future<void> _sendPosition(Position position) async {
    if (auth.user == null || socket.token == null) return;
    try {
      final batteryLevel = await _safeBatteryLevel();
      final batteryState = await _safeBatteryState();
      await api.mutate<Map<String, dynamic>>('location.update', {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy,
        'altitude': position.altitude,
        'speed': position.speed,
        'heading': position.heading,
        if (batteryLevel != null) 'batteryLevel': batteryLevel,
        if (batteryState != null)
          'isCharging': batteryState == BatteryState.charging ||
              batteryState == BatteryState.full,
        'platform': _platform,
      });
    } catch (_) {
      //
    }
  }

  Future<int?> _safeBatteryLevel() async {
    try {
      return await _battery.batteryLevel;
    } catch (_) {
      return null;
    }
  }

  Future<BatteryState?> _safeBatteryState() async {
    try {
      return await _battery.batteryState;
    } catch (_) {
      return null;
    }
  }

  String get _platform {
    if (kIsWeb) return 'web';
    if (defaultTargetPlatform == TargetPlatform.android) return 'android';
    if (defaultTargetPlatform == TargetPlatform.iOS) return 'ios';
    return 'unknown';
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _positionSubscription?.cancel();
    _positionSubscription = null;
    _started = false;
  }

  void dispose() {
    stop();
    if (_authListenerBound) {
      auth.removeListener(_handleAuthChanged);
      _authListenerBound = false;
    }
  }
}
