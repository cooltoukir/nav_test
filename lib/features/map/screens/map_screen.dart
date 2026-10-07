import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:nav_test/core/utils/app_constants.dart';
import 'package:nav_test/features/map/providers/location_provider.dart';
import 'package:nav_test/features/map/providers/map_controller_provider.dart';
import 'package:nav_test/features/search/providers/search_provider.dart';
import 'package:nav_test/features/search/widgets/search_bar_widget.dart';
import 'package:toastification/toastification.dart';

import '../../../config/flavor_config.dart';
import '../../navigation/models/route_state.dart';
import '../../navigation/providers/route_provider.dart';
import '../../navigation/widgets/route_info_panel.dart';
import '../widgets/custom_marker.dart';
import '../widgets/current_location_button.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen>
    with TickerProviderStateMixin {
  static const LatLng _defaultCenter = LatLng(23.777176, 90.399452);
  bool _mapReady = false;

  void _onMapReady() {
    setState(() => _mapReady = true);

    final pos = ref.read(locationProvider).position;
    if (pos != null) {
      ref
          .read(mapControllerProvider)
          .moveSmooth(this, target: pos, zoom: AppConstants.defaultZoom);
    }
  }

  void _handleNavigatingCamera(RouteState route) {
    if (!_mapReady) return;
    if (route.status == NavigationStatus.navigating &&
        route.animatedMarkerPos != null) {
      ref
          .read(mapControllerProvider)
          .moveSmooth2(
            route.animatedMarkerPos!,
            zoom: AppConstants.defaultZoom,
          );
    }
  }

  Future<void> _onMapLongPress(LatLng point) async {
    final place = await reverseGeocode(ref, point);

    if (!mounted) return;

    if (place == null) {
      toastification.show(
        context: context,
        title: const Text('Location not found'),
        description: const Text(
          'Could not find this location.',
        ),
        type: ToastificationType.error,
        autoCloseDuration: const Duration(seconds: 3),
      );

      return;
    }

    ref.read(selectedPlaceProvider.notifier).select(place);

    await ref.read(routeProvider.notifier).fetchRoute();
  }

  @override
  Widget build(BuildContext context) {
    final location = ref.watch(locationProvider);
    final mapController = ref.watch(mapControllerProvider);
    final config = ref.watch(flavorConfigProvider);
    final destination = ref.watch(selectedPlaceProvider);
    final route = ref.watch(routeProvider);

    ref.listen(locationProvider, (prev, next) {
      if (!_mapReady) return;
      if (prev?.position == null && next.position != null) {
        ref
            .read(mapControllerProvider)
            .moveSmooth(
              this,
              target: next.position!,
              zoom: AppConstants.defaultZoom,
            );
      }
    });

    ref.listen(routeProvider, (_, next) => _handleNavigatingCamera(next));

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              initialCenter: _defaultCenter,
              initialZoom: AppConstants.defaultZoom,
              onMapReady: _onMapReady,
              onLongPress: (tapPosition, point) {
                _onMapLongPress(point);
              },
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: AppConstants.osmTileUrl,
                maxZoom: 19,
                userAgentPackageName: config.packageName,
              ),
              RichAttributionWidget(
                attributions: [
                  TextSourceAttribution(AppConstants.openStreetMapContributors),
                ],
              ),
              if (route.routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: route.routePoints,
                      strokeWidth: 8,
                      color: Colors.black.withAlpha(20),
                    ),
                    Polyline(
                      points: route.routePoints,
                      strokeWidth: 5,
                      color: const Color(0xFF1565C0),
                      strokeCap: StrokeCap.round,
                      strokeJoin: StrokeJoin.round,
                    ),
                    if (route.status == NavigationStatus.navigating &&
                        route.currentSegmentIndex > 0)
                      Polyline(
                        points: route.routePoints
                            .take(route.currentSegmentIndex)
                            .toList(),
                        strokeWidth: 5,
                        color: Colors.green,
                        strokeCap: StrokeCap.round,
                      ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  if (location.position != null)
                    Marker(
                      point: location.position!,
                      width: 60,
                      height: 60,
                      child: const UserLocationMarker(),
                    ),
                  if (destination != null &&
                      route.status != NavigationStatus.navigating)
                    Marker(
                      point: destination.latLng,
                      width: 50,
                      height: 70,
                      child: const DestinationMarker(),
                    ),
                  if (route.animatedMarkerPos != null &&
                      route.status == NavigationStatus.navigating)
                    Marker(
                      point: route.animatedMarkerPos!,
                      width: 44,
                      height: 44,
                      child: NavigationMarker(
                        bearing: route.animatedMarkerBearing ?? 0,
                      ),
                    ),
                ],
              ),
            ],
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            right: 16,
            child: const SearchBarWidget(),
          ),
          Positioned(right: 16, bottom: 200, child: CurrentLocationButton()),
          if (route.status == NavigationStatus.loading)
            const Positioned(
              bottom: 120,
              left: 0,
              right: 0,
              child: Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 12),
                        Text('Finding best route...'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom,
            left: 16,
            right: 16,
            child: const RouteInfoPanel(),
          ),
          if (route.error != null)
            Positioned(
              bottom: 100,
              left: 16,
              right: 16,
              child: Material(
                borderRadius: BorderRadius.circular(12),
                color: Colors.red,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    route.error!,
                    style: const TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
