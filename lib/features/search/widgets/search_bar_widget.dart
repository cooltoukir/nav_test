import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

import '../../../core/utils/app_constants.dart';
import '../../map/providers/map_controller_provider.dart';
import '../../navigation/providers/route_provider.dart';
import '../models/place_model.dart';
import '../providers/search_provider.dart';

import 'package:flutter_animate/flutter_animate.dart';

class SearchBarWidget extends ConsumerStatefulWidget {
  const SearchBarWidget({super.key});

  @override
  ConsumerState<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends ConsumerState<SearchBarWidget>
    with TickerProviderStateMixin {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  Timer? _debounce;
  bool _showSuggestions = false;

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      ref.read(searchQueryProvider.notifier).update(value);
      setState(() => _showSuggestions = value.length >= 3);
    });
  }

  void _onSelectPlace(PlaceModel place) {
    _controller.text = place.displayName;
    _focus.unfocus();
    setState(() => _showSuggestions = false);
    ref.read(selectedPlaceProvider.notifier).select(place);
    ref.read(routeProvider.notifier).fetchRoute();
    final mapController = ref.read(mapControllerProvider);
    mapController.moveSmooth(
      this,
      target: place.latLng,
      zoom: AppConstants.defaultZoom,
    );
  }

  void _clearSearch() {
    _controller.clear();
    ref.read(searchQueryProvider.notifier).update('');
    ref.read(selectedPlaceProvider.notifier).select(null);
    ref.read(routeProvider.notifier).clearRoute();
    setState(() => _showSuggestions = false);
  }

  @override
  Widget build(BuildContext context) {
    final suggestions = ref.watch(searchSuggestionsProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(30),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextField(
            controller: _controller,
            focusNode: _focus,
            onChanged: _onChanged,
            decoration: InputDecoration(
              hintText: 'Search destination...',
              hintStyle: TextStyle(color: Colors.grey.shade400),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: Colors.blueAccent,
              ),
              suffixIcon: _controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.grey),
                      onPressed: _clearSearch,
                    )
                  : null,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ),

        if (_showSuggestions)
          Container(
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: suggestions.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
              error: (buildContext, ints) => const Padding(
                padding: EdgeInsets.all(12),
                child: Text('Search failed. Try again.'),
              ),
              data: (places) {
                if (places.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(14),
                    child: Text(
                      'No results found.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  itemCount: places.length,
                  separatorBuilder: (buildContext, ints) => Divider(
                    height: 1,
                    indent: 52,
                    color: Colors.grey.shade100,
                  ),
                  itemBuilder: (context, index) {
                    final place = places[index];
                    return _SuggestionTile(
                          place: place,
                          onTap: () => _onSelectPlace(place),
                        )
                        .animate()
                        .fadeIn(duration: 200.ms, delay: (index * 40).ms)
                        .slideY(begin: 0.1, end: 0);
                  },
                );
              },
            ),
          ),
      ],
    );
  }
}

class _SuggestionTile extends StatelessWidget {
  final PlaceModel place;
  final VoidCallback onTap;

  const _SuggestionTile({required this.place, required this.onTap});

  IconData _iconForType(String? type) {
    switch (type) {
      case 'restaurant':
      case 'cafe':
        return Icons.restaurant_rounded;
      case 'hotel':
        return Icons.hotel_rounded;
      case 'hospital':
        return Icons.local_hospital_rounded;
      case 'school':
      case 'university':
        return Icons.school_rounded;
      case 'airport':
        return Icons.flight_rounded;
      default:
        return Icons.location_on_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.blueAccent.withAlpha(25),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          _iconForType(place.type),
          size: 18,
          color: Colors.blueAccent,
        ),
      ),
      title: Text(
        place.shortName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        place.displayName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
      ),
    );
  }
}
