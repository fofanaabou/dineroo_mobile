import 'package:dineroo_mobile/shared/common/widgets/app_loader.dart';
import 'package:flutter/material.dart';

class AppPaginatedList<T> extends StatefulWidget {
  final List<T> items;
  final Widget Function(T item) itemBuilder;
  final Future<void> Function() onRefresh;
  final Future<void> Function() onLoadMore;
  final bool canLoadMore;
  final bool isLoading;

  const AppPaginatedList({
    super.key,
    required this.items,
    required this.itemBuilder,
    required this.onRefresh,
    required this.onLoadMore,
    required this.canLoadMore,
    required this.isLoading,
  });

  @override
  State<AppPaginatedList<T>> createState() => _AppPaginatedListState<T>();
}

class _AppPaginatedListState<T> extends State<AppPaginatedList<T>> {
  final ScrollController _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onScroll);
  }

  @override
  void dispose() {
    _controller.removeListener(_onScroll);
    _controller.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_controller.position.pixels >=
            _controller.position.maxScrollExtent - 100 &&
        widget.canLoadMore &&
        !widget.isLoading) {
      widget.onLoadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: ListView.builder(
        controller: _controller,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        itemCount: widget.items.length + 1,
        itemBuilder: (context, index) {
          if (index < widget.items.length) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: widget.itemBuilder(widget.items[index]),
            );
          } else {
            return widget.canLoadMore
                ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: AppLoader(size: 20)),
                )
                : const SizedBox.shrink();
          }
        },
      ),
    );
  }
}
