import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'dart:io' show Platform;

class LocationService {
  static const double NEARBY_RADIUS_METERS = 50.0;
  static const int UPDATE_INTERVAL_SECONDS = 60;
  
  StreamSubscription<Position>? _positionStreamSubscription;
  Timer? _simulatorTimer;
  bool _isTracking = false;
  Position? _lastPosition;
  
  // Minimum mesafe (metre cinsinden) - bu mesafeden daha yakın konumlar için bildirim gönderilmeyecek
  static const int MIN_DISTANCE_THRESHOLD = 10;  // metre
  
  Future<bool> handlePermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    try {
      // Check if location services are enabled
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('Location services are disabled');
        // Open location settings
        await Geolocator.openLocationSettings();
        return false;
      }

      // Check if we have permission
      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        // Request permission
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('Location permissions are denied');
          return false;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        print('Location permissions are permanently denied');
        // Open app settings
        await Geolocator.openAppSettings();
        return false;
      }

      print('Location permissions granted');
      return true;
    } catch (e) {
      print('Error handling location permission: $e');
      return false;
    }
  }

  Future<Position?> getCurrentLocation() async {
    try {
      final hasPermission = await handlePermission();
      if (!hasPermission) {
        print('No location permission');
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      print('Got current location: ${position.latitude}, ${position.longitude}');
      return position;
    } on PlatformException catch (e) {
      print('Platform error getting location: $e');
      return null;
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
  }

  bool _shouldUpdateLocation(Position newPosition) {
    if (kDebugMode) return true;  // Always allow updates in debug mode
    
    if (_lastPosition == null) return true;
    
    final distance = Geolocator.distanceBetween(
      _lastPosition!.latitude,
      _lastPosition!.longitude,
      newPosition.latitude,
      newPosition.longitude,
    );
    
    return distance >= MIN_DISTANCE_THRESHOLD.toDouble();
  }

  void startLocationTracking(Function(Position) onLocationUpdate) async {
    if (_isTracking) {
      print('Location tracking is already active');
      return;
    }

    try {
      final hasPermission = await handlePermission();
      if (!hasPermission) {
        print('No location permission for tracking');
        return;
      }

      // Cancel any existing subscriptions and timers
      await stopLocationTracking();
      
      print('Starting location tracking with ${UPDATE_INTERVAL_SECONDS}s interval...');
      _isTracking = true;

      // Get initial location
      final initialLocation = await getCurrentLocation();
      if (initialLocation != null) {
        print('Initial location: ${initialLocation.latitude}, ${initialLocation.longitude}');
        _lastPosition = initialLocation;
        onLocationUpdate(initialLocation);
      }

      // iOS simulator'da timer, gerçek cihazlarda stream kullan
      if (Platform.isIOS && kDebugMode) {
        print('Using timer for iOS simulator');
        _startTimerBasedTracking(onLocationUpdate);
      } else {
        print('Using location stream for real device');
        _startStreamBasedTracking(onLocationUpdate);
      }
    } catch (e) {
      print('Error starting location tracking: $e');
      _isTracking = false;
    }
  }

  void _startTimerBasedTracking(Function(Position) onLocationUpdate) {
    _simulatorTimer = Timer.periodic(Duration(seconds: UPDATE_INTERVAL_SECONDS), (timer) async {
      if (!_isTracking) {
        timer.cancel();
        return;
      }

      try {
        final position = await getCurrentLocation();
        if (position != null && _shouldUpdateLocation(position)) {
          print('Timer location update: ${position.latitude}, ${position.longitude}');
          _lastPosition = position;
          onLocationUpdate(position);
        }
      } catch (e) {
        print('Error in timer location update: $e');
      }
    });
  }

  void _startStreamBasedTracking(Function(Position) onLocationUpdate) {
    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: MIN_DISTANCE_THRESHOLD,
        timeLimit: Duration(seconds: UPDATE_INTERVAL_SECONDS),
      ),
    ).listen(
      (Position position) {
        if (!_isTracking) return;
        if (_shouldUpdateLocation(position)) {
          print('Stream location update: ${position.latitude}, ${position.longitude}');
          _lastPosition = position;
          onLocationUpdate(position);
        }
      },
      onError: (error) {
        print('Error in location stream: $error');
        if (error is LocationServiceDisabledException) {
          print('Location services are disabled, attempting to enable...');
          handlePermission();
        }
      },
      onDone: () {
        print('Location stream completed');
      },
      cancelOnError: false,
    );
  }

  Future<void> stopLocationTracking() async {
    _isTracking = false;
    _lastPosition = null;
    _simulatorTimer?.cancel();
    _simulatorTimer = null;
    if (_positionStreamSubscription != null) {
      print('Stopping location tracking...');
      await _positionStreamSubscription?.cancel();
      _positionStreamSubscription = null;
    }
  }

  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }
} 