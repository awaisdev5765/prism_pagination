import 'package:flutter/material.dart';
import 'package:prism_pagination/prism_pagination.dart';

/// Demo app for prism_pagination.
void main() => runApp(const DemoApp());

/// Root widget faking a paged API.
class DemoApp extends StatelessWidget {
  /// Creates the demo.
  const DemoApp({super.key});

  Future<List<String>> _load(int page) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (page >= 4) return <String>[];
    return [for (var i = 0; i < 20; i++) 'Item ${page * 20 + i}'];
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('prism_pagination demo')),
        body: PrismPaginatedList<String>(
          pageLoader: _load,
          itemBuilder: (context, item, index) => ListTile(
            leading: CircleAvatar(child: Text('${index + 1}')),
            title: Text(item),
          ),
        ),
      ),
    );
  }
}
