import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'widgets/search_bar_widget.dart';
import 'widgets/image_grid.dart';

class ImageSearchPage extends ConsumerWidget {
  const ImageSearchPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Image Search'),
      ),
      body: Column(
        children: [
          SearchBarWidget(),
          const Expanded(
            child: ImageGrid(),
          ),
        ],
      ),
    );
  }
}
