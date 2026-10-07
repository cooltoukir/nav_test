import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:nav_test/features/search/models/place_model.dart';

import '../../../core/utils/app_constants.dart';

final dioProvider = Provider<Dio>((ref) {
  return Dio(
    BaseOptions(
      baseUrl: AppConstants.nominatimBaseUrl,
      headers: {'User-Agent': 'NavTest/1.0'},
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );
});

class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void update(String query) => state = query;

  void clear() => state = '';
}

final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(
  SearchQueryNotifier.new,
);

final searchSuggestionsProvider = FutureProvider.autoDispose<List<PlaceModel>>((
  ref,
) async {
  final query = ref.watch(searchQueryProvider);
  if (query.trim().length < 3) return [];

  final dio = ref.watch(dioProvider);

  try {
    final response = await dio.get(
      '/search',
      queryParameters: {
        'q': query,
        'format': 'json',
        'limit': 5,
        'addressdetails': 1,
      },
    );

    final List data = response.data as List;
    return data
        .map((e) => PlaceModel.fromJson(e as Map<String, dynamic>))
        .toList();
  } on DioException {
    return [];
  }
});

class SelectedPlaceNotifier extends Notifier<PlaceModel?> {
  @override
  PlaceModel? build() => null;

  void select(PlaceModel? place) => state = place;

  void clear() => state = null;
}

final selectedPlaceProvider =
    NotifierProvider<SelectedPlaceNotifier, PlaceModel?>(
      SelectedPlaceNotifier.new,
    );

Future<PlaceModel?> reverseGeocode(WidgetRef ref, LatLng point) async {
  final dio = ref.read(dioProvider);

  try {
    final response = await dio.get(
      '/reverse',
      queryParameters: {
        'lat': point.latitude,
        'lon': point.longitude,
        'format': 'json',
        'addressdetails': 1,
      },
    );

    final data = response.data as Map<String, dynamic>;

    final displayName = data['display_name'] as String? ?? 'Selected location';

    return PlaceModel(
      displayName: displayName,
      shortName: _extractShortName(displayName),
      latLng: point,
      type: data['type'] as String?,
      icon: data['icon'] as String?,
    );
  } on DioException {
    return null;
  }
}

String _extractShortName(String displayName) {
  final parts = displayName.split(',');

  return parts.length >= 2
      ? '${parts[0].trim()}, ${parts[1].trim()}'
      : parts[0].trim();
}
