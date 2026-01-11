import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/image_repository.dart';

class ImageSearchState {
  final bool isLoading;
  final String query;
  final String? error;

  const ImageSearchState({
    this.isLoading = false,
    this.query = '',
    this.error,
  });

  ImageSearchState copyWith({
    bool? isLoading,
    String? query,
    String? error,
  }) {
    return ImageSearchState(
      isLoading: isLoading ?? this.isLoading,
      query: query ?? this.query,
      error: error,
    );
  }
}

class ImageSearchController extends StateNotifier<ImageSearchState> {
  final ImageRepository _repository;

  ImageSearchController({ImageRepository? repository})
      : _repository = repository ?? ImageRepository(),
        super(const ImageSearchState());

  Future<void> search(String query) async {
    if (query.trim().isEmpty) return;

    state = state.copyWith(isLoading: true, query: query, error: null);

    try {
      final results = await _repository.searchImages(query);
      debugPrint('Search results for "$query":');
      debugPrint(results.toString());
      state = state.copyWith(isLoading: false);
    } catch (e) {
      debugPrint('Error searching: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final imageSearchControllerProvider =
    StateNotifierProvider<ImageSearchController, ImageSearchState>((ref) {
  return ImageSearchController();
});
