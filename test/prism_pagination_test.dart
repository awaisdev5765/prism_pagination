import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prism_pagination/prism_pagination.dart';

/// Test loader serving [pageCount] pages of [itemsPerPage] items, then an
/// empty page.
class FakeLoader {
  FakeLoader(this.pageCount, {this.itemsPerPage = 20, this.failFrom});

  final int pageCount;
  final int itemsPerPage;
  int? failFrom;
  final calls = <int>[];

  Future<List<String>> call(int page) async {
    calls.add(page);
    final fail = failFrom;
    if (fail != null && page >= fail) {
      throw StateError('boom');
    }
    await Future<void>.delayed(const Duration(milliseconds: 10));
    if (page >= pageCount) return <String>[];
    return [for (var i = 0; i < itemsPerPage; i++) 'p${page}_i$i'];
  }
}

Future<void> _pump(
  WidgetTester tester, {
  required FakeLoader loader,
  bool settle = true,
}) async {
  tester.view.physicalSize = const Size(400, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: PrismPaginatedList<String>(
          pageLoader: loader.call,
          itemBuilder: (context, item, index) => ListTile(title: Text(item)),
        ),
      ),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}

String pageItem(int page, int i) => 'p${page}_i$i';

void main() {
  testWidgets('first page renders after loading spinner', (tester) async {
    final loader = FakeLoader(1);
    await _pump(tester, loader: loader, settle: false);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text(pageItem(0, 0)), findsOneWidget);
    expect(find.text(pageItem(0, 1)), findsOneWidget);
  });

  testWidgets('scrolling near end loads the next page', (tester) async {
    final loader = FakeLoader(2);
    await _pump(tester, loader: loader);
    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pumpAndSettle();
    expect(loader.calls, contains(1));
    expect(find.text(pageItem(1, 0)), findsOneWidget);
  });

  testWidgets('empty first page shows empty state', (tester) async {
    final loader = FakeLoader(0);
    await _pump(tester, loader: loader);
    expect(find.text('No more items'), findsOneWidget);
  });

  testWidgets('first-page failure shows retry and recovers', (tester) async {
    final loader = FakeLoader(1, failFrom: 0);
    await _pump(tester, loader: loader);
    expect(find.text('Failed to load'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);

    loader.failFrom = null; // allow recovery
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text(pageItem(0, 0)), findsOneWidget);
  });

  testWidgets('footer error appears and retries load more', (tester) async {
    // Page 0 OK, page 1 fails, recovery after retry.
    final loader = FakeLoader(2, failFrom: 1);
    await _pump(tester, loader: loader);
    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pumpAndSettle();
    expect(find.text('Failed to load more'), findsOneWidget);

    loader.failFrom = null;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(loader.calls, contains(1));
  });

  testWidgets('end of list shows no-more marker once', (tester) async {
    final loader = FakeLoader(1);
    await _pump(tester, loader: loader);
    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pumpAndSettle();
    // Loader returns [] for page 1 → end reached.
    expect(find.text('No more items'), findsOneWidget);
    // Further scrolling must not request page 2.
    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pumpAndSettle();
    expect(loader.calls, [0, 1]);
  });

  testWidgets('pull-to-refresh reloads from page 0', (tester) async {
    final loader = FakeLoader(2);
    await _pump(tester, loader: loader);
    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pumpAndSettle();
    expect(find.text(pageItem(1, 0)), findsOneWidget);

    // Over-scroll from the top triggers RefreshIndicator.
    await tester.drag(find.byType(ListView), const Offset(0, 600));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(loader.calls, contains(0));
    expect(
      find.text(pageItem(1, 0)),
      findsNothing,
    ); // list reset to page 0 only
  });

  testWidgets('empty builder override is used', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PrismPaginatedList<String>(
            pageLoader: (_) async => <String>[],
            itemBuilder: (context, item, index) => Text(item),
            emptyBuilder: (_) => const Text('NOTHING HERE'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('NOTHING HERE'), findsOneWidget);
  });
}
