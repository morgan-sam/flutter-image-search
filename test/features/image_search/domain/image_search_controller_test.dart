import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_image_search/features/image_search/domain/image_search_controller.dart';
import 'package:flutter_image_search/features/image_search/domain/image_result.dart';
import 'package:flutter_image_search/features/image_search/data/image_repository.dart';

/// Fake repository for testing controller logic in isolation.
/// Demonstrates clean architecture: controller depends on repository abstraction.
class FakeImageRepository implements ImageRepository {
  List<ImageResult> Function(String query, int page, int perPage)? onSearchImages;
  Exception? throwException;
  Duration? delay;
  final List<({String query, int page, int perPage})> searchCalls = [];

  @override
  Future<List<ImageResult>> searchImages(String query, {int page = 1, int perPage = 20}) async {
    searchCalls.add((query: query, page: page, perPage: perPage));
    if (delay != null) {
      await Future.delayed(delay!);
    }
    if (throwException != null) {
      throw throwException!;
    }
    return onSearchImages?.call(query, page, perPage) ?? [];
  }

  void reset() {
    searchCalls.clear();
    throwException = null;
    delay = null;
  }
}

void main() {
  late FakeImageRepository fakeRepository;
  late ImageSearchController controller;

  setUp(() {
    fakeRepository = FakeImageRepository();
    controller = ImageSearchController(repository: fakeRepository);
  });

  ImageResult createTestImage(String id) {
    return ImageResult(
      id: id,
      title: 'Test Image $id',
      thumbnailUrl: 'https://example.com/thumb/$id.jpg',
      fullUrl: 'https://example.com/full/$id.jpg',
    );
  }

  List<ImageResult> createTestImages(int count, {int startId = 1}) {
    return List.generate(count, (i) => createTestImage('${startId + i}'));
  }

  group('ImageSearchController', () {
    group('initial state', () {
      test('should have correct initial state values', () {
        expect(controller.state.images, isEmpty);
        expect(controller.state.isLoading, isFalse);
        expect(controller.state.isLoadingMore, isFalse);
        expect(controller.state.query, isEmpty);
        expect(controller.state.page, equals(1));
        expect(controller.state.hasMore, isTrue);
        expect(controller.state.error, isNull);
      });
    });

    group('search()', () {
      group('state transitions', () {
        test('should transition: idle → loading → success', () async {
          final results = createTestImages(5);
          fakeRepository.onSearchImages = (q, p, pp) => results;

          // Initial state: idle
          expect(controller.state.isLoading, isFalse);
          expect(controller.state.images, isEmpty);

          final future = controller.search('cats');

          // During search: loading
          expect(controller.state.isLoading, isTrue);
          expect(controller.state.query, equals('cats'));
          expect(controller.state.images, isEmpty);
          expect(controller.state.error, isNull);

          await future;

          // After search: success
          expect(controller.state.isLoading, isFalse);
          expect(controller.state.images, equals(results));
          expect(controller.state.error, isNull);
        });

        test('should transition: idle → loading → error', () async {
          fakeRepository.throwException = Exception('Network error');

          final future = controller.search('cats');

          expect(controller.state.isLoading, isTrue);

          await future;

          expect(controller.state.isLoading, isFalse);
          expect(controller.state.images, isEmpty);
          expect(controller.state.error, contains('Network error'));
        });

        test('should clear previous state when starting new search', () async {
          // First search with results
          fakeRepository.onSearchImages = (q, p, pp) => createTestImages(3);
          await controller.search('cats');
          expect(controller.state.images, hasLength(3));

          // Second search should clear previous results immediately
          fakeRepository.onSearchImages = (q, p, pp) => createTestImages(5);
          final future = controller.search('dogs');

          expect(controller.state.images, isEmpty);
          expect(controller.state.page, equals(1));
          expect(controller.state.hasMore, isTrue);

          await future;
          expect(controller.state.images, hasLength(5));
        });

        test('should clear previous error when starting new search', () async {
          fakeRepository.throwException = Exception('First error');
          await controller.search('cats');
          expect(controller.state.error, isNotNull);

          fakeRepository.throwException = null;
          fakeRepository.onSearchImages = (q, p, pp) => createTestImages(2);

          final future = controller.search('dogs');
          expect(controller.state.error, isNull);

          await future;
          expect(controller.state.error, isNull);
        });
      });

      group('empty/whitespace query handling', () {
        test('should ignore empty query', () async {
          await controller.search('');

          expect(controller.state.isLoading, isFalse);
          expect(controller.state.query, isEmpty);
          expect(fakeRepository.searchCalls, isEmpty);
        });

        test('should ignore whitespace-only query', () async {
          await controller.search('   \t\n  ');

          expect(controller.state.isLoading, isFalse);
          expect(fakeRepository.searchCalls, isEmpty);
        });
      });

      group('error handling', () {
        test('should handle network failure gracefully', () async {
          fakeRepository.throwException = Exception('Failed to connect');

          await controller.search('cats');

          expect(controller.state.isLoading, isFalse);
          expect(controller.state.error, contains('Failed to connect'));
          expect(controller.state.images, isEmpty);
        });

        test('should handle empty results (not an error)', () async {
          fakeRepository.onSearchImages = (q, p, pp) => [];

          await controller.search('xyznonexistent');

          expect(controller.state.isLoading, isFalse);
          expect(controller.state.error, isNull);
          expect(controller.state.images, isEmpty);
          expect(controller.state.hasMore, isFalse);
        });
      });

      group('pagination parameters', () {
        test('should call repository with page 1 on initial search', () async {
          fakeRepository.onSearchImages = (q, p, pp) => createTestImages(5);

          await controller.search('cats');

          expect(fakeRepository.searchCalls, hasLength(1));
          expect(fakeRepository.searchCalls[0].query, equals('cats'));
          expect(fakeRepository.searchCalls[0].page, equals(1));
        });
      });
    });

    group('loadMore() - infinite scroll pagination', () {
      test('should append results to existing images', () async {
        fakeRepository.onSearchImages = (q, p, pp) {
          if (p == 1) return createTestImages(5, startId: 1);
          if (p == 2) return createTestImages(5, startId: 6);
          return [];
        };

        await controller.search('cats');
        expect(controller.state.images, hasLength(5));
        expect(controller.state.page, equals(1));

        await controller.loadMore();
        expect(controller.state.images, hasLength(10));
        expect(controller.state.page, equals(2));
        expect(controller.state.images[0].id, equals('1'));
        expect(controller.state.images[5].id, equals('6'));
      });

      test('should set isLoadingMore=true only during pagination (not isLoading)', () async {
        fakeRepository.onSearchImages = (q, p, pp) => createTestImages(5);
        await controller.search('cats');

        var checkedDuringLoad = false;
        fakeRepository.onSearchImages = (q, p, pp) {
          // Verify state during the repository call
          checkedDuringLoad = true;
          expect(controller.state.isLoadingMore, isTrue);
          expect(controller.state.isLoading, isFalse);
          return createTestImages(5, startId: 6);
        };

        await controller.loadMore();

        expect(checkedDuringLoad, isTrue);
        expect(controller.state.isLoadingMore, isFalse);
      });

      test('should set hasMore=false when API returns empty results', () async {
        fakeRepository.onSearchImages = (q, p, pp) {
          if (p == 1) return createTestImages(5);
          return []; // No more results on page 2
        };

        await controller.search('cats');
        expect(controller.state.hasMore, isTrue);

        await controller.loadMore();
        expect(controller.state.hasMore, isFalse);
      });

      test('should prevent duplicate calls when already loading', () async {
        fakeRepository.onSearchImages = (q, p, pp) => createTestImages(5);
        await controller.search('cats');
        fakeRepository.searchCalls.clear();

        // Start first loadMore
        final future1 = controller.loadMore();
        // Immediately try second loadMore - should be blocked
        final future2 = controller.loadMore();

        await Future.wait([future1, future2]);

        // Only one page 2 call should have been made
        expect(fakeRepository.searchCalls.where((c) => c.page == 2).length, equals(1));
      });

      test('should not call API when hasMore=false', () async {
        fakeRepository.onSearchImages = (q, p, pp) {
          if (p == 1) return createTestImages(5);
          return [];
        };

        await controller.search('cats');
        await controller.loadMore(); // Sets hasMore=false
        fakeRepository.searchCalls.clear();

        await controller.loadMore();

        expect(fakeRepository.searchCalls, isEmpty);
      });

      test('should not call API when query is empty', () async {
        await controller.loadMore();

        expect(fakeRepository.searchCalls, isEmpty);
      });

      test('should handle pagination error gracefully', () async {
        fakeRepository.onSearchImages = (q, p, pp) {
          if (p == 1) return createTestImages(5);
          throw Exception('Pagination failed');
        };

        await controller.search('cats');
        final originalImages = [...controller.state.images];

        await controller.loadMore();

        expect(controller.state.isLoadingMore, isFalse);
        expect(controller.state.error, contains('Pagination failed'));
        expect(controller.state.images, equals(originalImages)); // Preserved
      });
    });

    group('retry()', () {
      test('should re-execute search with current query', () async {
        fakeRepository.throwException = Exception('First error');
        await controller.search('cats');
        expect(controller.state.error, isNotNull);

        fakeRepository.throwException = null;
        fakeRepository.onSearchImages = (q, p, pp) => createTestImages(3);
        fakeRepository.searchCalls.clear();

        await controller.retry();

        expect(fakeRepository.searchCalls, hasLength(1));
        expect(fakeRepository.searchCalls[0].query, equals('cats'));
        expect(controller.state.error, isNull);
        expect(controller.state.images, hasLength(3));
      });

      test('should do nothing when query is empty', () async {
        await controller.retry();

        expect(fakeRepository.searchCalls, isEmpty);
      });
    });
  });

  group('ImageSearchState', () {
    test('copyWith should preserve values when not specified', () {
      const state = ImageSearchState(
        images: [],
        isLoading: true,
        isLoadingMore: true,
        query: 'test',
        page: 5,
        hasMore: false,
        error: 'some error',
      );

      final copied = state.copyWith();

      expect(copied.isLoading, isTrue);
      expect(copied.isLoadingMore, isTrue);
      expect(copied.query, equals('test'));
      expect(copied.page, equals(5));
      expect(copied.hasMore, isFalse);
    });

    test('copyWith should override specified values', () {
      const state = ImageSearchState();

      final copied = state.copyWith(
        isLoading: true,
        query: 'cats',
        page: 3,
      );

      expect(copied.isLoading, isTrue);
      expect(copied.query, equals('cats'));
      expect(copied.page, equals(3));
      expect(copied.isLoadingMore, isFalse);
      expect(copied.hasMore, isTrue);
    });

    test('copyWith with error=null clears error', () {
      const state = ImageSearchState(error: 'some error');
      final copied = state.copyWith(error: null);
      expect(copied.error, isNull);
    });
  });
}
