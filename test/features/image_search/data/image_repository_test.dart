import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_image_search/features/image_search/data/image_repository.dart';
import 'package:flutter_image_search/features/image_search/data/image_api.dart';
import 'package:flutter_image_search/features/image_search/domain/image_result.dart';

/// Fake API for testing repository logic in isolation.
/// Demonstrates clean architecture: repository depends on API abstraction.
class FakeImageApi implements ImageApi {
  Map<String, dynamic> Function(String query, int page, int perPage)? onSearchImages;
  Exception? throwException;
  final List<({String query, int page, int perPage})> searchCalls = [];

  @override
  Future<Map<String, dynamic>> searchImages(String query, {int page = 1, int perPage = 20}) async {
    searchCalls.add((query: query, page: page, perPage: perPage));
    if (throwException != null) {
      throw throwException!;
    }
    return onSearchImages?.call(query, page, perPage) ?? {'photos': []};
  }
}

void main() {
  late FakeImageApi fakeApi;
  late ImageRepository repository;

  setUp(() {
    fakeApi = FakeImageApi();
    repository = ImageRepository(api: fakeApi);
  });

  group('ImageRepository', () {
    group('searchImages() - JSON parsing', () {
      test('should convert valid JSON response to List<ImageResult>', () async {
        fakeApi.onSearchImages = (query, page, perPage) => {
          'photos': [
            {
              'id': 123,
              'alt': 'A cute cat',
              'src': {
                'original': 'https://example.com/original/123.jpg',
                'medium': 'https://example.com/medium/123.jpg',
              },
            },
            {
              'id': 456,
              'alt': 'A playful dog',
              'src': {
                'original': 'https://example.com/original/456.jpg',
                'medium': 'https://example.com/medium/456.jpg',
              },
            },
          ],
        };

        final results = await repository.searchImages('animals');

        expect(results, isA<List<ImageResult>>());
        expect(results.length, equals(2));
        expect(results[0].id, equals('123'));
        expect(results[0].title, equals('A cute cat'));
        expect(results[1].id, equals('456'));
      });

      test('should map id field correctly (int to string conversion)', () async {
        fakeApi.onSearchImages = (query, page, perPage) => {
          'photos': [
            {
              'id': 12345678,
              'alt': 'Test',
              'src': {'original': 'url', 'medium': 'url'},
            },
          ],
        };

        final results = await repository.searchImages('test');

        expect(results[0].id, equals('12345678'));
        expect(results[0].id, isA<String>());
      });

      test('should map title from alt field', () async {
        fakeApi.onSearchImages = (query, page, perPage) => {
          'photos': [
            {
              'id': 1,
              'alt': 'Beautiful sunset over mountains',
              'src': {'original': 'url', 'medium': 'url'},
            },
          ],
        };

        final results = await repository.searchImages('sunset');

        expect(results[0].title, equals('Beautiful sunset over mountains'));
      });

      test('should map thumbnailUrl from src.medium', () async {
        fakeApi.onSearchImages = (query, page, perPage) => {
          'photos': [
            {
              'id': 1,
              'alt': 'Test',
              'src': {
                'original': 'https://example.com/full.jpg',
                'medium': 'https://example.com/thumb.jpg',
              },
            },
          ],
        };

        final results = await repository.searchImages('test');

        expect(results[0].thumbnailUrl, equals('https://example.com/thumb.jpg'));
      });

      test('should map fullUrl from src.original', () async {
        fakeApi.onSearchImages = (query, page, perPage) => {
          'photos': [
            {
              'id': 1,
              'alt': 'Test',
              'src': {
                'original': 'https://example.com/full.jpg',
                'medium': 'https://example.com/thumb.jpg',
              },
            },
          ],
        };

        final results = await repository.searchImages('test');

        expect(results[0].fullUrl, equals('https://example.com/full.jpg'));
      });

      test('should handle null alt field with empty string', () async {
        fakeApi.onSearchImages = (query, page, perPage) => {
          'photos': [
            {
              'id': 1,
              'alt': null,
              'src': {'original': 'url', 'medium': 'url'},
            },
          ],
        };

        final results = await repository.searchImages('test');

        expect(results[0].title, equals(''));
      });

      test('should handle missing alt field with empty string', () async {
        fakeApi.onSearchImages = (query, page, perPage) => {
          'photos': [
            {
              'id': 1,
              'src': {'original': 'url', 'medium': 'url'},
            },
          ],
        };

        final results = await repository.searchImages('test');

        expect(results[0].title, equals(''));
      });

      test('should return empty list when photos array is empty', () async {
        fakeApi.onSearchImages = (query, page, perPage) => {'photos': []};

        final results = await repository.searchImages('nonexistent');

        expect(results, isEmpty);
      });
    });

    group('searchImages() - error handling', () {
      test('should propagate HTTP errors (e.g., 404, 500)', () async {
        fakeApi.throwException = Exception('Failed to search images: 404');

        expect(
          () => repository.searchImages('cats'),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('404'),
          )),
        );
      });

      test('should propagate network timeout errors', () async {
        fakeApi.throwException = Exception('Connection timeout');

        expect(
          () => repository.searchImages('cats'),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('timeout'),
          )),
        );
      });

      test('should propagate server errors (500)', () async {
        fakeApi.throwException = Exception('Failed to search images: 500');

        expect(
          () => repository.searchImages('cats'),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('500'),
          )),
        );
      });
    });

    group('searchImages() - pagination parameters', () {
      test('should pass page parameter to API', () async {
        fakeApi.onSearchImages = (query, page, perPage) => {'photos': []};

        await repository.searchImages('cats', page: 5);

        expect(fakeApi.searchCalls, hasLength(1));
        expect(fakeApi.searchCalls[0].page, equals(5));
      });

      test('should pass perPage parameter to API', () async {
        fakeApi.onSearchImages = (query, page, perPage) => {'photos': []};

        await repository.searchImages('cats', perPage: 50);

        expect(fakeApi.searchCalls, hasLength(1));
        expect(fakeApi.searchCalls[0].perPage, equals(50));
      });

      test('should use default values (page=1, perPage=20)', () async {
        fakeApi.onSearchImages = (query, page, perPage) => {'photos': []};

        await repository.searchImages('cats');

        expect(fakeApi.searchCalls[0].page, equals(1));
        expect(fakeApi.searchCalls[0].perPage, equals(20));
      });

      test('should pass query string correctly', () async {
        fakeApi.onSearchImages = (query, page, perPage) => {'photos': []};

        await repository.searchImages('beautiful sunset');

        expect(fakeApi.searchCalls[0].query, equals('beautiful sunset'));
      });
    });
  });
}
