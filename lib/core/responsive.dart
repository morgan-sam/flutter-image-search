class Responsive {
  static int getGridColumns(double width) {
    if (width > 1400) return 5;
    if (width > 1000) return 4;
    if (width > 600) return 3;
    return 2;
  }

  /// Calculates the number of skeleton loading cards needed to fill
  /// the current row plus one complete additional row during pagination.
  
  /// Example: If we have 7 images and 3 columns:
  /// - Partial row has 1 item (7 % 3 = 1)
  /// - Need 2 skeletons to complete the row (3 - 1 = 2)
  /// - Plus 3 more for a complete row below
  /// - Total: 5 skeleton cards
  /// 
  static int calculateSkeletonCount(int imageCount, int crossAxisCount) {
    final remainder = imageCount % crossAxisCount;
    final skeletonsToFillRow = remainder == 0 ? 0 : crossAxisCount - remainder;
    return skeletonsToFillRow + crossAxisCount;
  }
}