import 'package:flutter/material.dart';
import '../../data/image_api.dart';

class SearchBarWidget extends StatelessWidget {
  SearchBarWidget({super.key});

  final TextEditingController _controller = TextEditingController();
  final ImageApi _imageApi = ImageApi();

  Future<void> _onSubmitted(String query) async {
    if (query.trim().isEmpty) return;

    try {
      final results = await _imageApi.searchImages(query);
      debugPrint('Search results for "$query":');
      debugPrint(results.toString());
    } catch (e) {
      debugPrint('Error searching: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: _controller,
        onSubmitted: _onSubmitted,
        decoration: InputDecoration(
          hintText: 'Search images...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16.0,
            vertical: 12.0,
          ),
        ),
      ),
    );
  }
}
