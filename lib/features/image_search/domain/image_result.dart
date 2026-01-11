class ImageResult {
  final String id;
  final String title;
  final String thumbnailUrl;
  final String fullUrl;

  const ImageResult({
    required this.id,
    required this.title,
    required this.thumbnailUrl,
    required this.fullUrl,
  });

  factory ImageResult.fromJson(Map<String, dynamic> json) {
    final src = json['src'] as Map<String, dynamic>;
    return ImageResult(
      id: json['id'].toString(),
      title: json['alt'] as String? ?? '',
      thumbnailUrl: src['medium'] as String,
      fullUrl: src['original'] as String,
    );
  }
}
