import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/fake_data.dart';
import '../widgets/order_card.dart';

/// A titled part of one tab, such as the orders that are happening right now.
typedef _Group = (String title, List<ServiceOrder> orders);

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  /// Only this pet's orders are shown; null shows the orders of all pets.
  PetId? _petFilter;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: fakeOrders,
      builder: (context, _) {
        final petFilter = _petFilter;
        final pets = fakePets.where((pet) => pet.ownerId == currentOwner.id).toList();
        final mine = fakeOrders.all.where((order) => AccessPolicy.canView(currentOwner, order)).toList();
        final shown = mine.where((order) => petFilter == null || order.petId == petFilter);
        final current = shown.where((order) => order.isActive).toList()
          ..sort((a, b) => a.period.start.compareTo(b.period.start));
        final history = shown.where((order) => !order.isActive).toList()
          ..sort((a, b) => _closedAt(b).compareTo(_closedAt(a)));
        final filter = pets.length < 2
            ? null
            : _PetFilter(pets: pets, selected: petFilter, onSelected: (id) => setState(() => _petFilter = id));
        final forPet = petFilter == null ? '' : ' za ljubimca ${petById(petFilter)?.name}';
        return DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Moji nalozi'),
              bottom: mine.isEmpty
                  ? null
                  : TabBar(
                      tabs: [
                        _TabLabel('Aktuelni', count: current.length),
                        _TabLabel('Prethodni', count: history.length),
                      ],
                    ),
            ),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () => context.push(petFilter == null ? '/orders/new' : '/orders/new?pet=${petFilter.value}'),
              icon: const Icon(Icons.add),
              label: const Text('Zakaži uslugu'),
            ),
            body: mine.isEmpty
                ? const _EmptyState()
                : TabBarView(
                    children: [
                      _OrderList(
                        key: const PageStorageKey('current'),
                        filter: filter,
                        groups: _currentGroups(current),
                        emptyText: 'Nema aktuelnih naloga$forPet.',
                      ),
                      _OrderList(
                        key: const PageStorageKey('history'),
                        filter: filter,
                        groups: _historyGroups(history),
                        emptyText: 'Nema prethodnih naloga$forPet.',
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}

/// What is happening now first, then what comes this week, then the rest.
List<_Group> _currentGroups(List<ServiceOrder> orders) {
  final weekAhead = DateTime.now().add(const Duration(days: 7));
  bool isHappening(ServiceOrder order) => order.status is InProgress || order.status is ReadyForPickup;
  final happening = orders.where(isHappening).toList();
  final upcoming = orders.where((order) => !isHappening(order));
  return [
    ('U toku', happening),
    ('Uskoro', upcoming.where((order) => order.period.start.isBefore(weekAhead)).toList()),
    ('Kasnije', upcoming.where((order) => !order.period.start.isBefore(weekAhead)).toList()),
  ];
}

List<_Group> _historyGroups(List<ServiceOrder> orders) => [
  ('Završeni', orders.where((order) => order.status is Completed).toList()),
  ('Otkazani i odbijeni', orders.where((order) => order.status is Rejected || order.status is Cancelled).toList()),
];

/// When an order that is over was completed, rejected or cancelled, so the latest news comes first.
DateTime _closedAt(ServiceOrder order) => switch (order.status) {
  Completed(:final at) || Rejected(:final at) || Cancelled(:final at) => at,
  Pending() || Confirmed() || InProgress() || ReadyForPickup() => order.period.end,
};

class _TabLabel extends StatelessWidget {
  const _TabLabel(this.text, {required this.count});

  final String text;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(text),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: scheme.secondaryContainer, borderRadius: BorderRadius.circular(999)),
            child: Text('$count', style: theme.textTheme.labelMedium?.copyWith(color: scheme.onSecondaryContainer)),
          ),
        ],
      ),
    );
  }
}

class _PetFilter extends StatelessWidget {
  const _PetFilter({required this.pets, required this.selected, required this.onSelected});

  final List<Pet> pets;
  final PetId? selected;
  final ValueChanged<PetId?> onSelected;

  @override
  Widget build(BuildContext context) {
    final petIcon = Icon(Icons.pets, size: 18, color: Theme.of(context).colorScheme.tertiary);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ChoiceChip(label: const Text('Svi'), selected: selected == null, onSelected: (_) => onSelected(null)),
        for (final pet in pets)
          ChoiceChip(
            avatar: petIcon,
            label: Text(pet.name),
            selected: selected == pet.id,
            onSelected: (_) => onSelected(selected == pet.id ? null : pet.id),
          ),
      ],
    );
  }
}

class _OrderList extends StatelessWidget {
  const _OrderList({super.key, required this.filter, required this.groups, required this.emptyText});

  final Widget? filter;
  final List<_Group> groups;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filter = this.filter;
    final filled = groups.where((group) => group.$2.isNotEmpty).toList();
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          children: [
            ?filter,
            if (filled.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 48),
                child: Text(
                  emptyText,
                  style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
              ),
            for (final (title, orders) in filled) ...[
              _SectionTitle(title, count: orders.length),
              for (final order in orders) _OrderTile(order: order),
            ],
          ],
        ),
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
  const _SectionTitle(this.text, {required this.count});

  final String text;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 0, 10),
      child: MergeSemantics(
        child: Semantics(
          header: true,
          child: Row(
            children: [
              Text(text, style: theme.textTheme.titleMedium),
              const SizedBox(width: 8),
              Text('$count', style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
      ),
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
