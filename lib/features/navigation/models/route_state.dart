import 'package:latlong2/latlong.dart';
import 'package:nav_test/core/utils/app_constants.dart';

enum NavigationStatus { idle, loading, ready, navigating, arrived }

class RouteState {
  final List<LatLng> routePoints;
  final LatLng? animatedMarkerPos;
  final double? animatedMarkerBearing;
  final NavigationStatus status;
  final double? distanceMeters;
  final double? durationSeconds;
  final int currentSegmentIndex;
  final String? error;

  const RouteState({
    this.routePoints = const [],
    this.animatedMarkerPos,
    this.animatedMarkerBearing,
    this.status = NavigationStatus.idle,
    this.distanceMeters,
    this.durationSeconds,
    this.currentSegmentIndex = 0,
    this.error,
  });

  RouteState copyWith({
    List<LatLng>? routePoints,
    LatLng? animatedMarkerPos,
    double? animatedMarkerBearing,
    NavigationStatus? status,
    double? distanceMeters,
    double? durationSeconds,
    int? currentSegmentIndex,
    String? error,
  }) => RouteState(
    routePoints: routePoints ?? this.routePoints,
    animatedMarkerPos: animatedMarkerPos ?? this.animatedMarkerPos,
    animatedMarkerBearing: animatedMarkerBearing ?? this.animatedMarkerBearing,
    status: status ?? this.status,
    distanceMeters: distanceMeters ?? this.distanceMeters,
    durationSeconds: durationSeconds ?? this.durationSeconds,
    currentSegmentIndex: currentSegmentIndex ?? this.currentSegmentIndex,
    error: error,
  );

  String get distanceText {
    if (distanceMeters == null) return '';
    if (distanceMeters! >= 1000) {
      return '${(distanceMeters! / 1000).toStringAsFixed(1)} km';
    }
    return '${distanceMeters!.toStringAsFixed(0)} m';
  }

  String get durationText {
    if (durationSeconds == null) return '';
    final mins = (durationSeconds! / 60).round();
    if (mins >= 60) {
      final h = mins ~/ 60;
      final m = mins % 60;
      return '${h}h ${m}m';
    }
    return '$mins min';
  }

  String get remainingDistanceText {
    if (distanceMeters == null || routePoints.isEmpty) return '';
    final progress = currentSegmentIndex / AppConstants.markerAnimSteps;
    final remaining = distanceMeters! * (1 - progress);
    if (remaining >= 1000) {
      return '${(remaining / 1000).toStringAsFixed(1)} km';
    }
    return '${remaining.toStringAsFixed(0)} m';
  }

  String get remainingDurationText {
    if (durationSeconds == null || routePoints.isEmpty) return '';
    final progress = currentSegmentIndex / AppConstants.markerAnimSteps;
    final remaining = durationSeconds! * (1 - progress);
    final mins = (remaining / 60).round();
    if (mins >= 60) {
      final h = mins ~/ 60;
      final m = mins % 60;
      return '${h}h ${m}m';
    }
    return '$mins min';
  }
}
