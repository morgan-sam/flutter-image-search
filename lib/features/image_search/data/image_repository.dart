import 'image_api.dart';

class ImageRepository {
  final ImageApi _api;

  ImageRepository({ImageApi? api}) : _api = api ?? ImageApi();

  Future<Map<String, dynamic>> searchImages(String query, {int page = 1, int perPage = 20}) {
    return _api.searchImages(query, page: page, perPage: perPage);
  }
}
