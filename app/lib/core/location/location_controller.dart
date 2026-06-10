import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:geolocator/geolocator.dart';

import '../auth/auth_controller.dart';
import '../api/socket_api_client.dart';
import '../config/app_config.dart';
import '../socket/socket_client.dart';

class LocationController with WidgetsBindingObserver {
  LocationController(this.socket, this.auth);

  final SocketClient socket;
  final AuthController auth;
  late final SocketApiClient api = SocketApiClient(socket);
  final Battery _battery = Battery();
  static const MethodChannel _backgroundChannel =
      MethodChannel('com.viciofer.my_family/background_location');
  StreamSubscription<Position>? _positionSubscription;
  Timer? _timer;
  bool _started = false;
  bool _starting = false;
  bool _authListenerBound = false;
  bool _lifecycleListenerBound = false;
  bool _openedBackgroundSettings = false;

  Future<void> bootstrap() async {
    _bindAuthListener();
    _bindLifecycleListener();
    if (kIsWeb) {
      stop();
      return;
    }
    if (auth.user == null || socket.token == null) return;
    if (_started || _starting) return;
    _starting = true;
    try {
      final permission = await _ensurePermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _starting = false;
        return;
      }

      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        await _startAndroidBackgroundService();
        _started = true;
        _starting = false;
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
      _started = true;
      _starting = false;
    } catch (_) {
      _starting = false;
    }
  }

  void _bindAuthListener() {
    if (_authListenerBound) return;
    auth.addListener(_handleAuthChanged);
    _authListenerBound = true;
  }

  void _bindLifecycleListener() {
    if (_lifecycleListenerBound) return;
    WidgetsBinding.instance.addObserver(this);
    _lifecycleListenerBound = true;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        auth.user != null &&
        socket.token != null &&
        !_started) {
      unawaited(bootstrap());
    }
  }

  void _handleAuthChanged() {
    if (kIsWeb) {
      stop();
      return;
    }
    if (auth.user != null && socket.token != null) {
      unawaited(bootstrap());
    } else {
      stop();
    }
  }

  Future<LocationPermission> _ensurePermission() async {
    if (kIsWeb) return LocationPermission.denied;
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return LocationPermission.denied;
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (!kIsWeb &&
        defaultTargetPlatform == TargetPlatform.android &&
        permission == LocationPermission.whileInUse) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.whileInUse &&
          !_openedBackgroundSettings) {
        _openedBackgroundSettings = true;
        await Geolocator.openAppSettings();
        return LocationPermission.denied;
      }
    }
    return permission;
  }

  Future<void> _startAndroidBackgroundService() async {
    final token = socket.token;
    if (token == null) return;
    try {
      await _backgroundChannel.invokeMethod<bool>('start', {
        'token': token,
        'apiBaseUrl': AppConfig.apiBaseUrl,
      });
    } catch (_) {
      unawaited(_sendCurrentPosition());
    }
  }

  Future<void> _stopAndroidBackgroundService() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await _backgroundChannel.invokeMethod<bool>('stop');
    } catch (_) {
      //
    }
  }

  Future<void> _sendCurrentPosition() async {
    if (kIsWeb) return;
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
    if (kIsWeb) return;
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
    unawaited(_stopAndroidBackgroundService());
    _started = false;
    _starting = false;
  }

  void dispose() {
    stop();
    if (_authListenerBound) {
      auth.removeListener(_handleAuthChanged);
      _authListenerBound = false;
    }
    if (_lifecycleListenerBound) {
      WidgetsBinding.instance.removeObserver(this);
      _lifecycleListenerBound = false;
    }
  }
}
