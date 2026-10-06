import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../models/location_state.dart';
import '../service/location_service.dart';

import 'package:toastification/toastification.dart';

class LocationNotifier extends Notifier<LocationState> {
  StreamSubscription<LatLng>? _locationSubscription;

  @override
  LocationState build() {
    ref.onDispose(() {
      _locationSubscription?.cancel();
    });

    return const LocationState(isLoading: false);
  }

  Future<void> getCurrentLocation() async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await LocationService.getCurrentLocation();

    if (result.error == null) {
      final lat = result.latitude;
      final lng = result.longitude;
      if (lat != null && lng != null) {
        state = state.copyWith(
          position: LatLng(lat, lng),
          isLoading: false,
          error: null,
        );
        _startLocationStream();
      } else {
        state = state.copyWith(isLoading: false, error: 'Location not found.');
      }
    } else {
      switch (result.error) {
        case LocationErrorCode.permissionPermanentlyDenied:
          toastification.show(
            title: const Text(
              'Location permission is required. Please enable it from Settings.',
            ),
          );
          await LocationService.openAppSettings();
          break;

        case LocationErrorCode.servicesDisabled:
          toastification.show(
            title: const Text('Please turn on Location Services to continue.'),
          );
          await LocationService.openLocationSettings();
          break;

        case LocationErrorCode.permissionDenied:
          toastification.show(
            title: const Text('Location permission is required.'),
          );
          break;

        case LocationErrorCode.timeout:
          toastification.show(
            title: const Text('Unable to get your location. Please try again.'),
          );
          break;

        case LocationErrorCode.notSupported:
          toastification.show(
            title: const Text('Location is not supported on this platform.'),
          );
          break;

        default:
          toastification.show(
            title: const Text('Unable to get your current location.'),
          );
      }
      state = state.copyWith(isLoading: false, error: 'Location not found.');
    }
  }

  void _startLocationStream() {
    _locationSubscription?.cancel();

    _locationSubscription = LocationService.getLocationStream().listen(
      (position) {
        state = state.copyWith(position: position);
      },
      onError: (error) {
        state = state.copyWith(error: error.toString());
      },
    );
  }
}

final locationProvider = NotifierProvider<LocationNotifier, LocationState>(
  LocationNotifier.new,
);
