import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/image_repository.dart';
import 'image_result.dart';

class ImageSearchState {
  final List<ImageResult> images;
  final bool isLoading;
  final bool isLoadingMore;
  final String query;
  final int page;
  final bool hasMore;
  final String? error;

  const ImageSearchState({
    this.images = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.query = '',
    this.page = 1,
    this.hasMore = true,
    this.error,
  });

  ImageSearchState copyWith({
    List<ImageResult>? images,
    bool? isLoading,
    bool? isLoadingMore,
    String? query,
    int? page,
    bool? hasMore,
    String? error,
  }) {
    return ImageSearchState(
      images: images ?? this.images,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      query: query ?? this.query,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
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

    state = state.copyWith(
      isLoading: true,
      query: query,
      page: 1,
      images: [],
      hasMore: true,
      error: null,
    );

    try {
      final results = await _repository.searchImages(query, page: 1);
      debugPrint('Search results for "$query": ${results.length} images');
      state = state.copyWith(
        isLoading: false,
        images: results,
        hasMore: results.isNotEmpty,
      );
    } catch (e) {
      debugPrint('Error searching: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> retry() async {
    if (state.query.isEmpty) return;
    await search(state.query);
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore || state.query.isEmpty) return;

    state = state.copyWith(isLoadingMore: true, error: null);

    try {
      final nextPage = state.page + 1;
      final results = await _repository.searchImages(state.query, page: nextPage);
      debugPrint('Load more page $nextPage: ${results.length} images');
      state = state.copyWith(
        isLoadingMore: false,
        images: [...state.images, ...results],
        page: nextPage,
        hasMore: results.isNotEmpty,
      );
    } catch (e) {
      debugPrint('Error loading more: $e');
      state = state.copyWith(isLoadingMore: false, error: e.toString());
    }
  }
}

final imageSearchControllerProvider =
    StateNotifierProvider<ImageSearchController, ImageSearchState>((ref) {
  return ImageSearchController();
});
