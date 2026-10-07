import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
