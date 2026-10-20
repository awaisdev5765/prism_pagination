import 'dart:async';

import 'package:flutter/material.dart';

import 'scroll_trigger.dart';

/// Infinite-scroll list with built-in pagination states.
///
/// Give it a [pageLoader] that fetches one page at a time (`page` starts at
/// 0) and an [itemBuilder]; the list handles everything else:
///
/// - first-load spinner and full-screen error with retry
/// - automatic load-more when the user scrolls near the end
/// - footer spinner / retryable error / "no more items" end marker
/// - empty-state widget when the first page returns nothing
/// - refresh via `RefreshIndicator`
///
/// ```dart
/// PrismPaginatedList<Post>(
///   pageLoader: (page) => api.fetchPosts(page),
///   itemBuilder: (context, post, index) => PostTile(post),
/// )
/// ```
class PrismPaginatedList<T> extends StatefulWidget {
  /// Creates a paginated list.
  const PrismPaginatedList({
    super.key,
    required this.pageLoader,
    required this.itemBuilder,
    this.emptyBuilder,
    this.errorBuilder,
    this.loadingBuilder,
    this.footerErrorLabel = 'Failed to load more',
    this.retryLabel = 'Retry',
    this.noMoreLabel = 'No more items',
    this.pageSizeHint = 20,
    this.physics,
    this.padding = EdgeInsets.zero,
  });

  /// Fetches page [page] (0-based). Return an empty list to signal the end
  /// of the data set. Throw to surface an error state.
  final Future<List<T>> Function(int page) pageLoader;

  /// Builds a row for item [item] at absolute index [index].
  final Widget Function(BuildContext context, T item, int index) itemBuilder;

  /// Shown when the first page is empty. Defaults to a centered
  /// "No more items" text.
  final WidgetBuilder? emptyBuilder;

  /// Shown when the first page fails to load. Receives a retry callback.
  final Widget Function(BuildContext context, VoidCallback retry)? errorBuilder;

  /// Shown while the first page loads. Defaults to a centered spinner.
  final WidgetBuilder? loadingBuilder;

  /// Footer text shown when loading more items fails.
  final String footerErrorLabel;

  /// Footer retry button label.
  final String retryLabel;

  /// Footer text shown once all pages have been loaded.
  final String noMoreLabel;

  /// Rough number of items per page — used only to size the scroll
  /// pre-trigger. Adjust if your rows are very tall.
  final int pageSizeHint;

  /// Scroll physics for the inner list.
  final ScrollPhysics? physics;

  /// Padding around the list.
  final EdgeInsetsGeometry padding;

  @override
  State<PrismPaginatedList<T>> createState() => _PrismPaginatedListState<T>();
}

class _PrismPaginatedListState<T> extends State<PrismPaginatedList<T>> {
  final _items = <T>[];
  final _controller = ScrollController();
  late final PrismScrollTrigger _trigger = PrismScrollTrigger(
    thresholdExtent: 400,
  )..onNearEnd = _maybeLoadMore;

  int _nextPage = 0;
  bool _loadingFirst = true;
  bool _loadingMore = false;
  bool _footerError = false;
  bool _reachedEnd = false;
  bool _firstFailed = false;

  @override
  void initState() {
    super.initState();
    _trigger.attach(_controller);
    _loadFirst();
  }

  @override
  void dispose() {
    _trigger.detach();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadFirst() async {
    setState(() {
      _loadingFirst = true;
      _firstFailed = false;
    });
    try {
      final page = await widget.pageLoader(0);
      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll(page);
        _nextPage = 1;
        _reachedEnd = page.isEmpty;
        _loadingFirst = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingFirst = false;
        _firstFailed = true;
      });
    }
  }

  void _maybeLoadMore() {
    if (_loadingFirst || _loadingMore || _reachedEnd || _footerError) return;
    _loadMore();
  }

  Future<void> _loadMore() async {
    if (_loadingMore || _reachedEnd) return;
    setState(() {
      _loadingMore = true;
      _footerError = false;
    });
    try {
      final page = await widget.pageLoader(_nextPage);
      if (!mounted) return;
      setState(() {
        _items.addAll(page);
        _nextPage++;
        _reachedEnd = page.isEmpty;
        _loadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingMore = false;
        _footerError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingFirst) {
      return widget.loadingBuilder?.call(context) ??
          const Center(child: CircularProgressIndicator());
    }
    if (_firstFailed) {
      if (widget.errorBuilder != null) {
        return widget.errorBuilder!(context, _loadFirst);
      }
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Failed to load'),
            const SizedBox(height: 8),
            FilledButton.tonal(
              onPressed: _loadFirst,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    if (_items.isEmpty) {
      return widget.emptyBuilder?.call(context) ??
          const Center(child: Text('No more items'));
    }

    return RefreshIndicator(
      onRefresh: _loadFirst,
      child: ListView.separated(
        controller: _controller,
        physics: widget.physics ?? const AlwaysScrollableScrollPhysics(),
        padding: widget.padding,
        itemCount: _items.length + 1, // +1 footer
        separatorBuilder: (_, _) => const SizedBox(height: 4),
        itemBuilder: (context, index) {
          if (index == _items.length) {
            return _buildFooter(context);
          }
          return widget.itemBuilder(context, _items[index], index);
        },
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    if (_footerError) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              widget.footerErrorLabel,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () {
                setState(() => _footerError = false);
                _loadMore();
              },
              child: Text(widget.retryLabel),
            ),
          ],
        ),
      );
    }
    if (_loadingMore) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    if (_reachedEnd) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Text(
            widget.noMoreLabel,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      );
    }
    // More pages likely exist but the user hasn't scrolled near the end yet.
    return const SizedBox(height: 1);
  }
}
