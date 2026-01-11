import '../domain/image_result.dart';
import 'image_api.dart';

class ImageRepository {
  final ImageApi _api;

  ImageRepository({ImageApi? api}) : _api = api ?? ImageApi();

  Future<List<ImageResult>> searchImages(String query, {int page = 1, int perPage = 20}) async {
    final response = await _api.searchImages(query, page: page, perPage: perPage);
    final photos = response['photos'] as List<dynamic>;
    return photos
        .map((json) => ImageResult.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
