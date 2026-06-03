import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../socket/socket_client.dart';

class LocationController {
  LocationController(this.socket);

  final SocketClient socket;
  StreamSubscription<Position>? _positionSubscription;
  Timer? _timer;
  bool _started = false;

  Future<void> bootstrap() async {
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
    try {
      await socket.emitAck<Map<String, dynamic>>('location.update', {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy,
        'altitude': position.altitude,
        'speed': position.speed,
        'heading': position.heading,
        'platform': _platform,
      });
    } catch (_) {
      //
    }
  }

  String get _platform {
    if (kIsWeb) return 'web';
    if (defaultTargetPlatform == TargetPlatform.android) return 'android';
    if (defaultTargetPlatform == TargetPlatform.iOS) return 'ios';
    return 'unknown';
  }

  void dispose() {
    _timer?.cancel();
    _positionSubscription?.cancel();
  }
}

