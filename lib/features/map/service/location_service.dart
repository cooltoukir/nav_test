import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';

import 'current_location_result.dart';

class LocationService {
  static const MethodChannel _channel = MethodChannel(
    'com.toukirahmed.nav_test/location',
  );

  static const EventChannel _locationStreamChannel = EventChannel(
    'com.toukirahmed.nav_test/location_stream',
  );

  static Future<CurrentLocationResult> getCurrentLocation() async {
    try {
      final permissionStatus = await checkPermission();

      switch (permissionStatus) {
        case LocationPermissionStatus.notRequested:
          return _requestPermissionAndGetLocation();

        case LocationPermissionStatus.granted:
          return _getLocation();

        case LocationPermissionStatus.denied:
          return _requestPermissionAndGetLocation();

        case LocationPermissionStatus.permanentlyDenied:
          await openAppSettings();

          return const CurrentLocationResult.failure(
            error: LocationErrorCode.permissionPermanentlyDenied,
          );
      }
    } on PlatformException {
      return const CurrentLocationResult.failure(
        error: LocationErrorCode.notSupported,
      );
    } catch (_) {
      return const CurrentLocationResult.failure(
        error: LocationErrorCode.unknownError,
      );
    }
  }

  static Future<LocationPermissionStatus> checkPermission() async {
    try {
      final String status =
          await _channel.invokeMethod<String>('checkPermission') ?? 'denied';

      switch (status) {
        case 'notRequested':
          return LocationPermissionStatus.notRequested;

        case 'granted':
          return LocationPermissionStatus.granted;

        case 'permanentlyDenied':
          return LocationPermissionStatus.permanentlyDenied;

        case 'denied':
        default:
          return LocationPermissionStatus.denied;
      }
    } on PlatformException {
      return LocationPermissionStatus.denied;
    } catch (_) {
      return LocationPermissionStatus.denied;
    }
  }

  static Future<LocationPermissionStatus> requestPermission() async {
    try {
      final String status =
          await _channel.invokeMethod<String>('requestPermission') ?? 'denied';

      switch (status) {
        case 'granted':
          return LocationPermissionStatus.granted;

        case 'permanentlyDenied':
          return LocationPermissionStatus.permanentlyDenied;

        case 'notRequested':
          return LocationPermissionStatus.notRequested;

        case 'denied':
        default:
          return LocationPermissionStatus.denied;
      }
    } on PlatformException {
      return LocationPermissionStatus.denied;
    } catch (_) {
      return LocationPermissionStatus.denied;
    }
  }

  static Future<bool> isLocationEnabled() async {
    try {
      return await _channel.invokeMethod<bool>('isLocationEnabled') ?? false;
    } on PlatformException {
      return false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> openLocationSettings() async {
    await _channel.invokeMethod<bool>('openLocationSettings');
  }

  static Future<void> openAppSettings() async {
    await _channel.invokeMethod<bool>('openAppSettings');
  }

  static Future<CurrentLocationResult>
  _requestPermissionAndGetLocation() async {
    final permissionStatus = await requestPermission();

    switch (permissionStatus) {
      case LocationPermissionStatus.granted:
        return _getLocation();

      case LocationPermissionStatus.permanentlyDenied:
        return const CurrentLocationResult.failure(
          error: LocationErrorCode.permissionPermanentlyDenied,
        );

      case LocationPermissionStatus.notRequested:
      case LocationPermissionStatus.denied:
        return const CurrentLocationResult.failure(
          error: LocationErrorCode.permissionDenied,
        );
    }
  }

  static Future<CurrentLocationResult> _getLocation() async {
    final bool locationEnabled = await isLocationEnabled();

    if (!locationEnabled) {
      return const CurrentLocationResult.failure(
        error: LocationErrorCode.servicesDisabled,
      );
    }

    return _fetchCurrentLocation();
  }

  static Future<CurrentLocationResult> _fetchCurrentLocation() async {
    try {
      final Map<dynamic, dynamic>? response = await _channel
          .invokeMethod<Map<dynamic, dynamic>>('getCurrentLocation');

      if (response == null) {
        return const CurrentLocationResult.failure(
          error: LocationErrorCode.unknownError,
        );
      }

      final latitude = response['latitude'];
      final longitude = response['longitude'];

      if (latitude is num && longitude is num) {
        return CurrentLocationResult.success(
          latitude: latitude.toDouble(),
          longitude: longitude.toDouble(),
        );
      }

      return _mapNativeError(response['error'] as String?);
    } on PlatformException {
      return const CurrentLocationResult.failure(
        error: LocationErrorCode.notSupported,
      );
    } catch (_) {
      return const CurrentLocationResult.failure(
        error: LocationErrorCode.unknownError,
      );
    }
  }

  static CurrentLocationResult _mapNativeError(String? error) {
    switch (error) {
      case 'PERMISSION_DENIED':
        return const CurrentLocationResult.failure(
          error: LocationErrorCode.permissionDenied,
        );

      case 'PERMISSION_PERMANENTLY_DENIED':
        return const CurrentLocationResult.failure(
          error: LocationErrorCode.permissionPermanentlyDenied,
        );

      case 'SERVICES_DISABLED':
        return const CurrentLocationResult.failure(
          error: LocationErrorCode.servicesDisabled,
        );

      case 'TIMEOUT':
        return const CurrentLocationResult.failure(
          error: LocationErrorCode.timeout,
        );

      case 'UNKNOWN_ERROR':
      default:
        return const CurrentLocationResult.failure(
          error: LocationErrorCode.unknownError,
        );
    }
  }

  static Stream<LatLng> getLocationStream() {
    return _locationStreamChannel.receiveBroadcastStream().map((event) {
      final data = Map<dynamic, dynamic>.from(event);

      return LatLng(
        (data['latitude'] as num).toDouble(),
        (data['longitude'] as num).toDouble(),
      );
    });
  }
}

enum LocationPermissionStatus {
  notRequested,
  granted,
  denied,
  permanentlyDenied,
}

enum LocationErrorCode {
  permissionDenied,
  permissionPermanentlyDenied,
  servicesDisabled,
  timeout,
  unknownError,
  notSupported,
}
