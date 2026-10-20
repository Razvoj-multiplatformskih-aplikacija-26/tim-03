import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/fake_data.dart';
import '../widgets/order_card.dart';

class MyOrdersScreen extends StatelessWidget {
  const MyOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Moji nalozi')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/orders/new'),
        icon: const Icon(Icons.add),
        label: const Text('Zakaži uslugu'),
      ),
      body: ListenableBuilder(
        listenable: fakeOrders,
        builder: (context, _) {
          final mine = fakeOrders.all.where((order) => AccessPolicy.canView(currentOwner, order));
          final current = mine.where((order) => order.isActive).toList()
            ..sort((a, b) => a.period.start.compareTo(b.period.start));
          final history = mine.where((order) => !order.isActive).toList()
            ..sort((a, b) => b.period.start.compareTo(a.period.start));
          if (current.isEmpty && history.isEmpty) return const _EmptyState();
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                children: [
                  if (current.isNotEmpty) ...[
                    const _SectionTitle('Aktuelni'),
                    for (final order in current) _OrderTile(order: order),
                  ],
                  if (history.isNotEmpty) ...[
                    const _SectionTitle('Prethodni'),
                    for (final order in history) _OrderTile(order: order),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _OrderTile extends StatelessWidget {
  const _OrderTile({required this.order});

  final ServiceOrder order;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: OrderCard(order: order, onOpen: () => context.push('/orders/${order.id.value}')),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 12),
      child: Semantics(header: true, child: Text(text, style: Theme.of(context).textTheme.titleLarge)),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.pets, size: 96, color: theme.colorScheme.primary),
            const SizedBox(height: 24),
            Text('Nemate naloga.', style: theme.textTheme.titleLarge, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              'Zakažite pansion, kupanje, pregled ili šetnju za svog ljubimca.',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
