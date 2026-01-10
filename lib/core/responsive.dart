class Responsive {
  static int getGridColumns(double width) {
    if (width > 1400) return 5;
    if (width > 1000) return 4;
    if (width > 600) return 3;
    return 2;
  }
}