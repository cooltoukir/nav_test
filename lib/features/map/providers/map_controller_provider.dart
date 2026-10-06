import 'package:flutter/animation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/utils/app_constants.dart';

final mapControllerProvider = Provider<MapController>((ref) {
  final controller = MapController();
  ref.onDispose(controller.dispose);
  return controller;
});

/*extension MapControllerX on MapController {
  void moveSmooth(LatLng center, {double zoom = AppConstants.defaultZoom}) {
    move(center, zoom);
  }
}*/

extension MapControllerX on MapController {
  void moveSmooth(
    TickerProvider vsync, {
    required LatLng target,
    required double zoom,
    Duration duration = const Duration(milliseconds: 800),
  }) {
    final startLatLng = camera.center;
    final startZoom = camera.zoom;

    final animationController = AnimationController(
      vsync: vsync,
      duration: duration,
    );

    final latTween = Tween<double>(
      begin: startLatLng.latitude,
      end: target.latitude,
    );
    final lngTween = Tween<double>(
      begin: startLatLng.longitude,
      end: target.longitude,
    );
    final zoomTween = Tween<double>(begin: startZoom, end: zoom);

    final curvedAnimation = CurvedAnimation(
      parent: animationController,
      curve: Curves.fastOutSlowIn,
    );

    animationController.addListener(() {
      move(
        LatLng(
          latTween.evaluate(curvedAnimation),
          lngTween.evaluate(curvedAnimation),
        ),
        zoomTween.evaluate(curvedAnimation),
      );
    });

    animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        animationController.dispose();
      }
    });

    animationController.forward();
  }
}
