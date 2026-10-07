import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:nav_test/core/utils/app_constants.dart';
import 'package:nav_test/features/navigation/models/route_state.dart';

import '../../../config/flavor_config.dart';
import '../../map/providers/location_provider.dart';
import '../../search/providers/search_provider.dart';

class RouteNotifier extends Notifier<RouteState> {
  Timer? _animTimer;

  @override
  RouteState build() {
    ref.onDispose(() {
      _animTimer?.cancel();
    });

    return const RouteState();
  }

  Future<void> fetchRoute() async {
    final location = ref.read(locationProvider).position;
    final destination = ref.read(selectedPlaceProvider);
    final config = ref.watch(flavorConfigProvider);

    if (location == null || destination == null) return;

    state = state.copyWith(status: NavigationStatus.loading, error: null);

    try {
      final url =
          '${config.osrmBaseUrl}/${location.longitude},${location.latitude};'
          '${destination.latLng.longitude},${destination.latLng.latitude}'
          '?overview=full&geometries=geojson&steps=true';

      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) throw Exception('OSRM error');

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final route = (json['routes'] as List).first as Map<String, dynamic>;
      final coords = (route['geometry']['coordinates'] as List)
          .map(
            (c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()),
          )
          .toList();

      state = state.copyWith(
        routePoints: coords,
        animatedMarkerPos: coords.first,
        status: NavigationStatus.ready,
        distanceMeters: (route['distance'] as num).toDouble(),
        durationSeconds: (route['duration'] as num).toDouble(),
        currentSegmentIndex: 0,
      );
    } catch (e) {
      state = state.copyWith(
        status: NavigationStatus.idle,
        error: 'Could not load route. Check connection',
      );
    }
  }

  void startNavigation() {
    if (state.routePoints.isEmpty) return;
    _animTimer?.cancel();

    final points = state.routePoints;
    final totalSteps = AppConstants.markerAnimSteps;

    final interpolated = _interpolatePath(points, totalSteps);
    int step = 0;

    state = state.copyWith(status: NavigationStatus.navigating);

    _animTimer = Timer.periodic(AppConstants.markerAnimDuration, (timer) {
      if (step >= interpolated.length - 1) {
        timer.cancel();
        state = state.copyWith(
          animatedMarkerPos: interpolated.last,
          status: NavigationStatus.arrived,
        );
        return;
      }

      final current = interpolated[step];
      final next = interpolated[step + 1];
      final bearing = _bearing(current, next);

      state = state.copyWith(
        animatedMarkerPos: current,
        animatedMarkerBearing: bearing,
        currentSegmentIndex: step,
      );
      step++;
    });
  }

  void stopNavigation() {
    _animTimer?.cancel();
    state = const RouteState();
  }

  void clearRoute() {
    _animTimer?.cancel();
    state = const RouteState();
  }

  List<LatLng> _interpolatePath(List<LatLng> points, int steps) {
    final result = <LatLng>[];
    if (points.isEmpty) return result;

    double totalDist = 0;
    final dists = <double>[];
    for (int i = 0; i < points.length - 1; i++) {
      final d = _haversine(points[i], points[i + 1]);
      dists.add(d);
      totalDist += d;
    }

    final stepDist = totalDist / steps;
    double accumulated = 0;
    int seg = 0;
    double segProgress = 0;

    result.add(points[0]);
    for (int s = 1; s < steps; s++) {
      final target = s * stepDist;
      while (seg < dists.length - 1 && accumulated + dists[seg] < target) {
        accumulated += dists[seg];
        seg++;
      }
      segProgress =
          (target - accumulated) / dists[seg].clamp(0.0001, double.infinity);
      final lat =
          points[seg].latitude +
          (points[seg + 1].latitude - points[seg].latitude) * segProgress;
      final lng =
          points[seg].longitude +
          (points[seg + 1].longitude - points[seg].longitude) * segProgress;
      result.add(LatLng(lat, lng));
    }
    result.add(points.last);
    return result;
  }

  double _haversine(LatLng a, LatLng b) {
    const R = 6371000.0;
    final lat1 = a.latitude * pi / 180;
    final lat2 = b.latitude * pi / 180;
    final dlat = (b.latitude - a.latitude) * pi / 180;
    final dlng = (b.longitude - a.longitude) * pi / 180;
    final s =
        sin(dlat / 2) * sin(dlat / 2) +
        cos(lat1) * cos(lat2) * sin(dlng / 2) * sin(dlng / 2);
    return R * 2 * atan2(sqrt(s), sqrt(1 - s));
  }

  double _bearing(LatLng from, LatLng to) {
    final lat1 = from.latitude * pi / 180;
    final lat2 = to.latitude * pi / 180;
    final dlng = (to.longitude - from.longitude) * pi / 180;
    final y = sin(dlng) * cos(lat2);
    final x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dlng);
    return (atan2(y, x) * 180 / pi + 360) % 360;
  }
}

final routeProvider = NotifierProvider<RouteNotifier, RouteState>(
  RouteNotifier.new,
);
