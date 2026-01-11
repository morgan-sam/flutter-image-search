import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../domain/image_search_controller.dart';

class SearchBarWidget extends HookConsumerWidget {
  const SearchBarWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = useTextEditingController();
    final debounce = useRef<Timer?>(null);

    useEffect(() {
      return () => debounce.value?.cancel();
    }, []);

    void onChanged(String query) {
      debounce.value?.cancel();
      debounce.value = Timer(const Duration(milliseconds: 400), () {
        if (query.trim().isNotEmpty) {
          ref.read(imageSearchControllerProvider.notifier).search(query);
        }
      });
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
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