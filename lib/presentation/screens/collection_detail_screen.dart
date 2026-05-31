import 'package:flutter/material.dart';

class CollectionDetailScreen extends StatelessWidget {
  const CollectionDetailScreen({super.key, required this.itemId});

  final String itemId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Collection Item')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            itemId,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
