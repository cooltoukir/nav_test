import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:nav_test/core/utils/app_constants.dart';
import 'package:nav_test/features/map/providers/location_provider.dart';
import 'package:nav_test/features/map/providers/map_controller_provider.dart';

import '../../../config/flavor_config.dart';
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

  @override
  Widget build(BuildContext context) {
    final location = ref.watch(locationProvider);
    final mapController = ref.watch(mapControllerProvider);
    final config = ref.watch(flavorConfigProvider);

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

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              initialCenter: _defaultCenter,
              initialZoom: AppConstants.defaultZoom,
              onMapReady: _onMapReady,
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
              MarkerLayer(
                markers: [
                  if (location.position != null)
                    Marker(
                      point: location.position!,
                      width: 60,
                      height: 60,
                      child: const AnimatedLocationMarker(),
                    ),
                ],
              ),
            ],
          ),
          Positioned(right: 16, bottom: 200, child: CurrentLocationButton()),
        ],
      ),
    );
  }
}
