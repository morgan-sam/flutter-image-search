import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class ImageApi {
  static const String _baseUrl = 'https://api.pexels.com/v1';

  String get _apiKey => dotenv.env['PEXELS_API_KEY'] ?? '';

  Future<Map<String, dynamic>> searchImages(String query, {int page = 1, int perPage = 20}) async {
    final uri = Uri.parse('$_baseUrl/search').replace(
      queryParameters: {
        'query': query,
        'page': page.toString(),
        'per_page': perPage.toString(),
      },
    );

    final response = await http.get(
      uri,
      headers: {
        'Authorization': _apiKey,
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to search images: ${response.statusCode}');
    }
  }
}
