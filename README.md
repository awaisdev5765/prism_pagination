# prism_pagination

Infinite-scroll pagination for Flutter — automatic load-more, retryable
errors, empty and end-of-list states, with a pluggable page loader. One
widget, every state handled.

Part of the **Prism** package family.

## Features

- ✅ `PrismPaginatedList` — drop-in infinite scroll for any paged API
- ✅ Automatic load-more before the user reaches the bottom
- ✅ First-load spinner, full-screen error with retry, empty state
- ✅ Footer states: loading spinner, retryable error, "no more items"
- ✅ Pull-to-refresh resets to page 0
- ✅ Reusable `PrismScrollTrigger` for custom scroll layouts
- ✅ Pure Flutter, all six platforms, zero dependencies

## Installation

```yaml
dependencies:
  prism_pagination: ^0.1.0
```

## Quick start

```dart
PrismPaginatedList<Post>(
  pageLoader: (page) => api.fetchPosts(page), // page starts at 0
  itemBuilder: (context, post, index) => PostTile(post),
)
```

Return an empty list from `pageLoader` to signal the end of the data set;
throw to surface the retry states. Everything else — spinners, retries,
end markers — is handled for you.

## Custom states

```dart
PrismPaginatedList<Post>(
  pageLoader: api.fetchPosts,
  itemBuilder: (context, post, index) => PostTile(post),
  emptyBuilder: (_) => const EmptyIllustration(),
  errorBuilder: (context, retry) => ErrorCard(onRetry: retry),
  noMoreLabel: 'You\u2019ve reached the end!',
)
```

## The Prism package family

| Package | What it does |
| --- | --- |
| [prism_markdown](https://pub.dev/packages/prism_markdown) | Markdown widget with full CommonMark + GFM support |
| [prism_code_view](https://pub.dev/packages/prism_code_view) | Syntax-highlighted code viewer (Dart/JSON/YAML built in) |
| [prism_adaptive_scaffold](https://pub.dev/packages/prism_adaptive_scaffold) | Responsive scaffolds: bottom bar → rail → extended rail |
| [prism_adaptive_dialog](https://pub.dev/packages/prism_adaptive_dialog) | Dialogs that become bottom sheets on phones |
| [prism_state_views](https://pub.dev/packages/prism_state_views) | Empty, loading, error, and success states from one widget |
| [prism_master_detail](https://pub.dev/packages/prism_master_detail) | Adaptive master-detail layouts |
| [prism_banner](https://pub.dev/packages/prism_banner) | Dismissible announcement banners |
| [prism_search](https://pub.dev/packages/prism_search) | Adaptive search with suggestions |
| [prism_toast](https://pub.dev/packages/prism_toast) | Adaptive toast notifications |
| **prism_pagination** | Infinite-scroll lists with all states handled |

All pure Flutter, all six platforms, MIT licensed, built to work together.

## License

MIT — see [LICENSE](LICENSE).
