import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_image_search/features/image_search/presentation/widgets/search_bar_widget.dart';
import 'package:flutter_image_search/features/image_search/domain/image_search_controller.dart';
import 'package:flutter_image_search/features/image_search/domain/image_result.dart';
import 'package:flutter_image_search/features/image_search/data/image_repository.dart';

/// Fake repository that tracks search calls for testing debounce behavior.
class FakeImageRepository implements ImageRepository {
  final List<String> searchQueries = [];

  @override
  Future<List<ImageResult>> searchImages(String query, {int page = 1, int perPage = 20}) async {
    searchQueries.add(query);
    return [];
  }
}

void main() {
  late FakeImageRepository fakeRepository;

  setUp(() {
    fakeRepository = FakeImageRepository();
  });

  Widget createTestWidget() {
    return ProviderScope(
      overrides: [
        imageSearchControllerProvider.overrideWith(
          (ref) => ImageSearchController(repository: fakeRepository),
        ),
      ],
      child: const MaterialApp(
        home: Scaffold(
          body: SearchBarWidget(),
        ),
      ),
    );
  }

  group('SearchBarWidget', () {
    group('debounce behavior', () {
      testWidgets('should trigger search callback after 400ms debounce delay', (tester) async {
        await tester.pumpWidget(createTestWidget());

        // Type in the search field
        await tester.enterText(find.byType(TextField), 'cats');

        // Immediately after typing, no search should be triggered
        expect(fakeRepository.searchQueries, isEmpty);

        // Wait for debounce delay (400ms) plus some buffer
        await tester.pump(const Duration(milliseconds: 450));

        // Now search should have been triggered
        expect(fakeRepository.searchQueries, contains('cats'));
      });

      testWidgets('should only call search once for rapid typing (debounce)', (tester) async {
        await tester.pumpWidget(createTestWidget());

        final textField = find.byType(TextField);

        // Simulate rapid typing with pauses shorter than debounce
        await tester.enterText(textField, 'c');
        await tester.pump(const Duration(milliseconds: 100));

        await tester.enterText(textField, 'ca');
        await tester.pump(const Duration(milliseconds: 100));

        await tester.enterText(textField, 'cat');
        await tester.pump(const Duration(milliseconds: 100));

        await tester.enterText(textField, 'cats');
        await tester.pump(const Duration(milliseconds: 100));

        // No search should be triggered yet (total time < 400ms from last keystroke)
        expect(fakeRepository.searchQueries, isEmpty);

        // Wait for debounce after final keystroke
        await tester.pump(const Duration(milliseconds: 450));

        // Only one search should have been triggered with the final value
        expect(fakeRepository.searchQueries, hasLength(1));
        expect(fakeRepository.searchQueries.first, equals('cats'));
      });

      testWidgets('should cancel previous debounce timer on new input', (tester) async {
        await tester.pumpWidget(createTestWidget());

        // Type first query
        await tester.enterText(find.byType(TextField), 'dogs');
        await tester.pump(const Duration(milliseconds: 300)); // Wait 300ms

        // Before debounce completes, type new query
        await tester.enterText(find.byType(TextField), 'cats');
        await tester.pump(const Duration(milliseconds: 200)); // 200ms into new timer

        // Original timer should have been cancelled
        expect(fakeRepository.searchQueries, isEmpty);

        // Wait for new debounce to complete
        await tester.pump(const Duration(milliseconds: 250));

        // Only 'cats' should be searched, not 'dogs'
        expect(fakeRepository.searchQueries, hasLength(1));
        expect(fakeRepository.searchQueries.first, equals('cats'));
      });
    });

    group('empty/whitespace handling', () {
      testWidgets('should not trigger search for empty input', (tester) async {
        await tester.pumpWidget(createTestWidget());

        // Type something then clear it
        await tester.enterText(find.byType(TextField), 'cats');
        await tester.pump(const Duration(milliseconds: 100));
        await tester.enterText(find.byType(TextField), '');
        await tester.pump(const Duration(milliseconds: 450));

        // No search should be triggered for empty string
        expect(fakeRepository.searchQueries, isEmpty);
      });

      testWidgets('should not trigger search for whitespace-only input', (tester) async {
        await tester.pumpWidget(createTestWidget());

        await tester.enterText(find.byType(TextField), '   ');
        await tester.pump(const Duration(milliseconds: 450));

        expect(fakeRepository.searchQueries, isEmpty);
      });
    });

    group('UI elements', () {
      testWidgets('should display search icon', (tester) async {
        await tester.pumpWidget(createTestWidget());

        expect(find.byIcon(Icons.search), findsOneWidget);
      });

      testWidgets('should display placeholder hint text', (tester) async {
        await tester.pumpWidget(createTestWidget());

        expect(find.text('Search images...'), findsOneWidget);
      });

      testWidgets('should have rounded border', (tester) async {
        await tester.pumpWidget(createTestWidget());

        final textField = tester.widget<TextField>(find.byType(TextField));
        final decoration = textField.decoration as InputDecoration;
        final border = decoration.border as OutlineInputBorder;

        expect(border.borderRadius, equals(BorderRadius.circular(12.0)));
      });
    });
  });
}
