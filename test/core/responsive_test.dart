import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_image_search/core/responsive.dart';

void main() {
  group('Responsive', () {
    group('getGridColumns()', () {
      test('should return 5 columns for width > 1400 (large desktop)', () {
        expect(Responsive.getGridColumns(1401), equals(5));
        expect(Responsive.getGridColumns(1500), equals(5));
        expect(Responsive.getGridColumns(1920), equals(5));
        expect(Responsive.getGridColumns(2560), equals(5));
      });

      test('should return 4 columns for width > 1000 and <= 1400 (desktop)', () {
        expect(Responsive.getGridColumns(1001), equals(4));
        expect(Responsive.getGridColumns(1200), equals(4));
        expect(Responsive.getGridColumns(1400), equals(4));
      });

      test('should return 3 columns for width > 600 and <= 1000 (tablet)', () {
        expect(Responsive.getGridColumns(601), equals(3));
        expect(Responsive.getGridColumns(768), equals(3));
        expect(Responsive.getGridColumns(1000), equals(3));
      });

      test('should return 2 columns for width <= 600 (mobile)', () {
        expect(Responsive.getGridColumns(600), equals(2));
        expect(Responsive.getGridColumns(375), equals(2));
        expect(Responsive.getGridColumns(320), equals(2));
        expect(Responsive.getGridColumns(0), equals(2));
      });

      group('edge cases - exact breakpoints', () {
        test('exactly 600 should return 2 columns', () {
          expect(Responsive.getGridColumns(600), equals(2));
        });

        test('exactly 1000 should return 3 columns', () {
          expect(Responsive.getGridColumns(1000), equals(3));
        });

        test('exactly 1400 should return 4 columns', () {
          expect(Responsive.getGridColumns(1400), equals(4));
        });
      });
    });

    group('calculateSkeletonCount()', () {
      test('should return crossAxisCount when images fill complete rows', () {
        // 6 images with 3 columns = 2 complete rows, need 3 skeletons for next row
        expect(Responsive.calculateSkeletonCount(6, 3), equals(3));
        // 8 images with 4 columns = 2 complete rows, need 4 skeletons
        expect(Responsive.calculateSkeletonCount(8, 4), equals(4));
        // 10 images with 5 columns = 2 complete rows, need 5 skeletons
        expect(Responsive.calculateSkeletonCount(10, 5), equals(5));
      });

      test('should fill partial row plus one complete row', () {
        // 7 images with 3 columns: 1 in partial row + need 2 to fill + 3 for next row = 5
        expect(Responsive.calculateSkeletonCount(7, 3), equals(5));
        // 5 images with 3 columns: 2 in partial row + need 1 to fill + 3 for next row = 4
        expect(Responsive.calculateSkeletonCount(5, 3), equals(4));
        // 9 images with 4 columns: 1 in partial row + need 3 to fill + 4 for next row = 7
        expect(Responsive.calculateSkeletonCount(9, 4), equals(7));
      });

      test('should work with 2 columns (mobile)', () {
        // 3 images: 1 in partial row + 1 to fill + 2 for next row = 3
        expect(Responsive.calculateSkeletonCount(3, 2), equals(3));
        // 4 images: complete rows, need 2 for next row
        expect(Responsive.calculateSkeletonCount(4, 2), equals(2));
      });

      test('should work with 5 columns (large desktop)', () {
        // 12 images: 2 in partial row + 3 to fill + 5 for next row = 8
        expect(Responsive.calculateSkeletonCount(12, 5), equals(8));
        // 10 images: complete rows, need 5 for next row
        expect(Responsive.calculateSkeletonCount(10, 5), equals(5));
      });

      test('should handle zero images (initial load)', () {
        expect(Responsive.calculateSkeletonCount(0, 3), equals(3));
        expect(Responsive.calculateSkeletonCount(0, 4), equals(4));
        expect(Responsive.calculateSkeletonCount(0, 2), equals(2));
      });

      test('should handle single image', () {
        // 1 image with 3 columns: need 2 to fill + 3 for next row = 5
        expect(Responsive.calculateSkeletonCount(1, 3), equals(5));
        // 1 image with 2 columns: need 1 to fill + 2 for next row = 3
        expect(Responsive.calculateSkeletonCount(1, 2), equals(3));
      });
    });
  });
}
