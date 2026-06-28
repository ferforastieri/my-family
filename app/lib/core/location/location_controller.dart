import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:geolocator/geolocator.dart';

import '../auth/auth_controller.dart';
import '../api/http_api_client.dart';
import '../config/app_config.dart';
import '../socket/socket_client.dart';

class LocationController with WidgetsBindingObserver {
  LocationController(this.socket, this.auth);

  final SocketClient socket;
  final AuthController auth;
  late final HttpApiClient api = HttpApiClient(socket);
  final Battery _battery = Battery();
  static const MethodChannel _backgroundChannel = MethodChannel(
    'com.viciofer.my_family/background_location',
  );
  StreamSubscription<Position>? _positionSubscription;
  Timer? _timer;
  bool _started = false;
  bool _starting = false;
  bool _authListenerBound = false;
  bool _lifecycleListenerBound = false;
  bool _openedBackgroundSettings = false;
  bool _openedLocationSettings = false;
  String? _activeAndroidToken;

  Future<void> requestStartupPermissions() async {
    _bindLifecycleListener();
    if (kIsWeb) return;
    try {
      await _ensurePermission(request: true);
    } catch (_) {
      //
    }
  }

  Future<void> bootstrap() async {
    _bindAuthListener();
    _bindLifecycleListener();
    if (kIsWeb) {
      stop();
      return;
    }
    final currentToken = socket.token;
    if (!_hasTenantSession || currentToken == null) return;
    if (_started) {
      if (defaultTargetPlatform == TargetPlatform.android &&
          _activeAndroidToken != currentToken) {
        await _startAndroidBackgroundService();
      }
      return;
    }
    if (_starting) return;
    _starting = true;
    try {
      final permission = await _ensurePermission(request: false);
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        if (permission != LocationPermission.always) return;
        final started = await _startAndroidBackgroundService();
        _started = started;
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
    } catch (_) {
      //
    } finally {
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
        _hasTenantSession &&
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
    if (_hasTenantSession && socket.token != null) {
      unawaited(bootstrap());
    } else {
      stop();
    }
  }

  Future<LocationPermission> _ensurePermission({required bool request}) async {
    if (kIsWeb) return LocationPermission.denied;
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (request && !_openedLocationSettings) {
        _openedLocationSettings = true;
        await Geolocator.openLocationSettings();
      }
      return LocationPermission.denied;
    }
    var permission = await Geolocator.checkPermission();
    if (request && permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (!kIsWeb &&
        defaultTargetPlatform == TargetPlatform.android &&
        permission == LocationPermission.whileInUse) {
      if (request) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.whileInUse &&
          request &&
          !_openedBackgroundSettings) {
        _openedBackgroundSettings = true;
        await Geolocator.openAppSettings();
      }
      if (permission != LocationPermission.always) {
        return LocationPermission.denied;
      }
    }
    return permission;
  }

  Future<bool> _startAndroidBackgroundService() async {
    final token = socket.token;
    if (token == null) return false;
    try {
      await _backgroundChannel.invokeMethod<bool>('start', {
        'token': token,
        'apiBaseUrl': AppConfig.apiBaseUrl,
      });
      _activeAndroidToken = token;
      return true;
    } catch (_) {
      unawaited(_sendCurrentPosition());
      return false;
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
    if (!_hasTenantSession || socket.token == null) return;
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
    if (!_hasTenantSession || socket.token == null) return;
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
          'isCharging':
              batteryState == BatteryState.charging ||
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

  bool get _hasTenantSession =>
      auth.user != null &&
      auth.tenant != null &&
      auth.user?.isPlatformSession != true;

  void stop() {
    _timer?.cancel();
    _timer = null;
    _positionSubscription?.cancel();
    _positionSubscription = null;
    unawaited(_stopAndroidBackgroundService());
    _started = false;
    _starting = false;
    _activeAndroidToken = null;
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
