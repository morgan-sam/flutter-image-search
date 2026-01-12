import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_image_search/core/responsive.dart';
import '../../domain/image_search_controller.dart';
import 'image_card.dart';
import 'skeleton_card.dart';

class ImageGrid extends HookConsumerWidget {
  const ImageGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(imageSearchControllerProvider);
    final scrollController = useScrollController();
    
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = Responsive.getGridColumns(screenWidth);
    final skeletonCount = state.isLoadingMore 
      ? Responsive.calculateSkeletonCount(state.images.length, crossAxisCount)
      : 0;
    
    useEffect(() {
      void onScroll() {
        if (!scrollController.hasClients) return;

        final maxScroll = scrollController.position.maxScrollExtent;
        final currentScroll = scrollController.position.pixels;
        final threshold = maxScroll * 0.8;

        if (currentScroll >= threshold && 
            !state.isLoadingMore && 
            state.hasMore) {
          ref.read(imageSearchControllerProvider.notifier).loadMore();
        }
      }

      scrollController.addListener(onScroll);
      return () => scrollController.removeListener(onScroll);
    }, [scrollController]);

    if (state.isLoading) {
      return GridView.builder(
        padding: const EdgeInsets.all(16.0),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 12.0,
          mainAxisSpacing: 12.0,
          childAspectRatio: 1.0,
        ),
        itemCount: 12,
        itemBuilder: (context, index) => const SkeletonCard(),
      );
    }

    if (state.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                state.error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () {
                  ref.read(imageSearchControllerProvider.notifier).retry();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (state.images.isEmpty) {
      return const Center(
        child: Text('Search for images to get started'),
      );
    }

    return CustomScrollView(
      controller: scrollController,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16.0),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 12.0,
              mainAxisSpacing: 12.0,
              childAspectRatio: 1.0,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (index < state.images.length) {
                  return ImageCard(image: state.images[index]);
                }
                
                final skeletonIndex = index - state.images.length;
                if (state.isLoadingMore && skeletonIndex < skeletonCount) {
                  return const SkeletonCard();
                }
                
                return null;
              },
              childCount: state.images.length + skeletonCount,
            ),
          ),
        ),
      ],
    );
  }
}