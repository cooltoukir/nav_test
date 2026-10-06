import 'location_service.dart';

class CurrentLocationResult {
  final double? latitude;
  final double? longitude;
  final LocationErrorCode? error;

  const CurrentLocationResult.success({
    required this.latitude,
    required this.longitude,
  }) : error = null;

  const CurrentLocationResult.failure({required this.error})
    : latitude = null,
      longitude = null;
}
