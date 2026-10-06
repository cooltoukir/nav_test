import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nav_test/features/map/providers/map_controller_provider.dart';

import '../../../core/utils/app_constants.dart';
import '../providers/location_provider.dart';

class CurrentLocationButton extends ConsumerStatefulWidget {
  const CurrentLocationButton({super.key});

  @override
  ConsumerState<CurrentLocationButton> createState() =>
      _CurrentLocationButtonState();
}

class _CurrentLocationButtonState extends ConsumerState<CurrentLocationButton>
    with TickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    final locationState = ref.watch(locationProvider);

    return FloatingActionButton(
      backgroundColor: Colors.white,
      foregroundColor: Colors.blue,
      onPressed: locationState.isLoading
          ? null
          : () async {
              await ref.read(locationProvider.notifier).getCurrentLocation();
              if (!context.mounted) return;
              final newPosition = ref.read(locationProvider).position;
              if (newPosition != null) {
                ref
                    .read(mapControllerProvider)
                    .moveSmooth(
                      this,
                      target: newPosition,
                      zoom: AppConstants.defaultZoom,
                    );
              }
            },
      child: locationState.isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            )
          : const Icon(Icons.my_location),
    );
  }
}
