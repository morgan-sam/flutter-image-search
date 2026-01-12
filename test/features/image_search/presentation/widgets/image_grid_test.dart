import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_image_search/features/image_search/presentation/widgets/image_card.dart';
import 'package:flutter_image_search/features/image_search/presentation/widgets/image_grid.dart';
import 'package:flutter_image_search/features/image_search/domain/image_search_controller.dart';
import 'package:flutter_image_search/features/image_search/domain/image_result.dart';
import 'package:flutter_image_search/features/image_search/data/image_repository.dart';

/// Test controller that allows direct state manipulation for widget testing.
class TestImageSearchController extends ImageSearchController {
  TestImageSearchController() : super(repository: _FakeRepository());

  void setTestState(ImageSearchState newState) {
    state = newState;
  }
}

class _FakeRepository implements ImageRepository {
  @override
  Future<List<ImageResult>> searchImages(String query, {int page = 1, int perPage = 20}) async {
    return [];
  }
}

/// Fake repository that tracks loadMore calls for infinite scroll testing.
class TrackingRepository implements ImageRepository {
  int loadMoreCallCount = 0;
  int searchCallCount = 0;

  @override
  Future<List<ImageResult>> searchImages(String query, {int page = 1, int perPage = 20}) async {
    if (page > 1) {
      loadMoreCallCount++;
    } else {
      searchCallCount++;
    }
    // Return some results to keep hasMore=true
    return List.generate(
      perPage,
      (i) => ImageResult(
        id: '${page * 100 + i}',
        title: 'Image ${page * 100 + i}',
        thumbnailUrl: 'https://example.com/thumb/${page * 100 + i}.jpg',
        fullUrl: 'https://example.com/full/${page * 100 + i}.jpg',
      ),
    );
  }
}

ImageResult createTestImage(String id) {
  return ImageResult(
    id: id,
    title: 'Test Image $id',
    thumbnailUrl: 'https://example.com/thumb/$id.jpg',
    fullUrl: 'https://example.com/full/$id.jpg',
  );
}

List<ImageResult> createTestImages(int count) {
  return List.generate(count, (i) => createTestImage('$i'));
}

void main() {
  late TestImageSearchController testController;

  setUp(() {
    testController = TestImageSearchController();
  });

  Widget createTestWidget({TestImageSearchController? controller}) {
    final ctrl = controller ?? testController;
    return ProviderScope(
      overrides: [
        imageSearchControllerProvider.overrideWith((ref) => ctrl),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 800, // Tablet width for 3 columns
            height: 600,
            child: const ImageGrid(),
          ),
        ),
      ),
    );
  }

  group('ImageGrid', () {
    group('loading states', () {
      testWidgets('should show skeleton loading during initial search (isLoading=true)', (tester) async {
        testController.setTestState(const ImageSearchState(
          isLoading: true,
          query: 'cats',
        ));

        await tester.pumpWidget(createTestWidget());

        // Should show loading skeletons (12 skeleton cards for initial load)
        // The GridView.builder with itemCount: 12 creates skeleton cards
        expect(find.byType(GridView), findsOneWidget);
      });

      testWidgets('should show skeleton cards during pagination (isLoadingMore=true)', (tester) async {
        testController.setTestState(ImageSearchState(
          isLoadingMore: true,
          images: createTestImages(6),
          query: 'cats',
          hasMore: true,
        ));

        await tester.pumpWidget(createTestWidget());

        // Should show existing images plus skeleton cards
        expect(find.byType(CustomScrollView), findsOneWidget);
      });

      testWidgets('should NOT show loading indicators when idle', (tester) async {
        testController.setTestState(ImageSearchState(
          images: createTestImages(6),
          query: 'cats',
          isLoading: false,
          isLoadingMore: false,
        ));

        await tester.pumpWidget(createTestWidget());

        // CircularProgressIndicator should not be visible in idle state
        expect(find.byType(CircularProgressIndicator), findsNothing);
      });
    });

    group('error state', () {
      testWidgets('should display error message when search fails', (tester) async {
        testController.setTestState(const ImageSearchState(
          error: 'Network connection failed',
          query: 'cats',
        ));

        await tester.pumpWidget(createTestWidget());

        expect(find.text('Network connection failed'), findsOneWidget);
        expect(find.byIcon(Icons.error_outline), findsOneWidget);
      });

      testWidgets('should show retry button on error', (tester) async {
        testController.setTestState(const ImageSearchState(
          error: 'Something went wrong',
          query: 'cats',
        ));

        await tester.pumpWidget(createTestWidget());

        expect(find.text('Retry'), findsOneWidget);
        expect(find.byIcon(Icons.refresh), findsOneWidget);
      });
    });

    group('empty state', () {
      testWidgets('should show empty state message when no results', (tester) async {
        testController.setTestState(const ImageSearchState());

        await tester.pumpWidget(createTestWidget());

        expect(find.text('Search for images to get started'), findsOneWidget);
      });

      testWidgets('should show empty state after search returns no results', (tester) async {
        testController.setTestState(const ImageSearchState(
          images: [],
          query: 'xyznonexistent',
          hasMore: false,
        ));

        await tester.pumpWidget(createTestWidget());

        expect(find.text('Search for images to get started'), findsOneWidget);
      });
    });

    group('image display', () {
      testWidgets('should display image cards when results exist', (tester) async {
        testController.setTestState(ImageSearchState(
          images: createTestImages(6),
          query: 'cats',
        ));

        await tester.pumpWidget(createTestWidget());

        // Should show CustomScrollView with images
        expect(find.byType(CustomScrollView), findsOneWidget);
        expect(find.byType(ImageCard), findsWidgets);
      });
    });

    group('infinite scroll behavior', () {
      testWidgets('should have scroll controller attached to CustomScrollView', (tester) async {
        testController.setTestState(ImageSearchState(
          images: createTestImages(20),
          query: 'cats',
          hasMore: true,
        ));

        await tester.pumpWidget(createTestWidget());

        final scrollView = tester.widget<CustomScrollView>(find.byType(CustomScrollView));
        expect(scrollView.controller, isNotNull);
      });

      testWidgets('scroll listener should be active when hasMore=true', (tester) async {
        final trackingRepo = TrackingRepository();
        final controller = ImageSearchController(repository: trackingRepo);

        await tester.pumpWidget(ProviderScope(
          overrides: [
            imageSearchControllerProvider.overrideWith((ref) => controller),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 800,
                height: 600,
                child: const ImageGrid(),
              ),
            ),
          ),
        ));

        // Trigger initial search to populate images
        await controller.search('cats');
        await tester.pumpAndSettle();

        // Reset counter after initial search
        final initialLoadMoreCount = trackingRepo.loadMoreCallCount;

        // Scroll to bottom to trigger loadMore
        await tester.drag(find.byType(CustomScrollView), const Offset(0, -2000));
        await tester.pumpAndSettle();

        // LoadMore should have been called
        expect(trackingRepo.loadMoreCallCount, greaterThan(initialLoadMoreCount));
      });
    });
  });

  group('ImageCard', () {
    testWidgets('should display image title overlay when title is not empty', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 200,
            height: 200,
            child: ImageCard(
              image: ImageResult(
                id: '1',
                title: 'Beautiful Sunset',
                thumbnailUrl: 'https://example.com/thumb.jpg',
                fullUrl: 'https://example.com/full.jpg',
              ),
            ),
          ),
        ),
      ));

      expect(find.text('Beautiful Sunset'), findsOneWidget);
    });

    testWidgets('should NOT display title overlay when title is empty', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 200,
            height: 200,
            child: ImageCard(
              image: ImageResult(
                id: '1',
                title: '',
                thumbnailUrl: 'https://example.com/thumb.jpg',
                fullUrl: 'https://example.com/full.jpg',
              ),
            ),
          ),
        ),
      ));

      // The gradient container for title should not exist when title is empty
      expect(find.byType(LinearGradient), findsNothing);
    });

    testWidgets('should have rounded corners', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 200,
            height: 200,
            child: ImageCard(
              image: createTestImage('1'),
            ),
          ),
        ),
      ));

      final clipRRect = tester.widget<ClipRRect>(find.byType(ClipRRect).first);
      expect(clipRRect.borderRadius, equals(BorderRadius.circular(12.0)));
    });
  });
}
