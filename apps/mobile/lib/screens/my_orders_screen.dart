import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../data/fake_center.dart';
import '../data/fake_data.dart';
import '../dependencies.dart';
import '../text/domain_errors.dart';
import '../widgets/order_card.dart';

/// A titled part of one tab, such as the orders that are happening right now.
typedef _Group = (String title, List<ServiceOrder> orders);

/// The owner's main flow. The screen only draws the state of [MyOrdersBloc] and sends it events.
class MyOrdersScreen extends StatelessWidget {
  const MyOrdersScreen({super.key});

  /// Shown once, wherever the owner cancelled from, and then acknowledged so it is not shown again.
  void _showNotice(BuildContext context, MyOrdersNotice notice) {
    final message = switch (notice) {
      OrderCancelled() => 'Nalog je otkazan.',
      CancellationRejected(:final error) => error.message,
      CancellationFailed() => 'Otkazivanje nije uspelo. Proverite vezu i pokušajte ponovo.',
    };
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
    context.read<MyOrdersBloc>().add(const MyOrdersNoticeAcknowledged());
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<MyOrdersBloc>();
    final owner = context.read<AppDependencies>().owner;
    final pets = fakePets.where((pet) => pet.ownerId == owner.id).toList();
    return BlocConsumer<MyOrdersBloc, MyOrdersState>(
      listenWhen: (previous, current) => current is MyOrdersLoaded && current.notice != null,
      listener: (context, state) => _showNotice(context, (state as MyOrdersLoaded).notice!),
      builder: (context, state) {
        final petFilter = switch (state) {
          MyOrdersLoaded(:final petFilter) => petFilter,
          MyOrdersLoading() || MyOrdersFailure() || MyOrdersEmpty() => null,
        };
        return DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Moji nalozi'),
              actions: [
                IconButton(
                  tooltip: 'Osveži',
                  icon: const Icon(Icons.refresh),
                  onPressed: () => bloc.add(const MyOrdersRequested()),
                ),
                const _FakeDataMenu(),
              ],
              bottom: switch (state) {
                MyOrdersLoaded() => TabBar(
                  tabs: [
                    _TabLabel('Aktuelni', count: state.current.length),
                    _TabLabel('Prethodni', count: state.history.length),
                  ],
                ),
                MyOrdersLoading() || MyOrdersFailure() || MyOrdersEmpty() => null,
              },
            ),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () => context.push(petFilter == null ? '/orders/new' : '/orders/new?pet=${petFilter.value}'),
              icon: const Icon(Icons.add),
              label: const Text('Zakaži uslugu'),
            ),
            body: switch (state) {
              MyOrdersLoading() => Center(
                child: Semantics(label: 'Učitavanje naloga', child: const CircularProgressIndicator()),
              ),
              MyOrdersFailure() => _FailureView(onRetry: () => bloc.add(const MyOrdersRequested())),
              MyOrdersEmpty() => const _EmptyState(),
              MyOrdersLoaded() => _LoadedBody(
                state: state,
                filter: pets.length < 2
                    ? null
                    : _PetFilter(
                        pets: pets,
                        selected: petFilter,
                        onSelected: (id) => bloc.add(MyOrdersPetFilterChanged(id)),
                      ),
              ),
            },
          ),
        );
      },
    );
  }
}

class _LoadedBody extends StatelessWidget {
  const _LoadedBody({required this.state, required this.filter});

  final MyOrdersLoaded state;
  final Widget? filter;

  @override
  Widget build(BuildContext context) {
    final petFilter = state.petFilter;
    final forPet = petFilter == null ? '' : ' za ljubimca ${petById(petFilter)?.name}';
    return TabBarView(
      children: [
        _OrderList(
          key: const PageStorageKey('current'),
          filter: filter,
          groups: _currentGroups(state.current, now: state.now),
          emptyText: 'Nema aktuelnih naloga$forPet.',
        ),
        _OrderList(
          key: const PageStorageKey('history'),
          filter: filter,
          groups: _historyGroups(state.history),
          emptyText: 'Nema prethodnih naloga$forPet.',
        ),
      ],
    );
  }
}

/// What is happening now first, then what comes this week, then the rest.
List<_Group> _currentGroups(List<ServiceOrder> orders, {required DateTime now}) {
  final weekAhead = now.add(const Duration(days: 7));
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

class _FailureView extends StatelessWidget {
  const _FailureView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_outlined, size: 96, color: theme.colorScheme.error),
            const SizedBox(height: 24),
            Text('Nalozi nisu učitani.', style: theme.textTheme.titleLarge, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              'Proverite vezu sa internetom i pokušajte ponovo.',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Pokušaj ponovo')),
          ],
        ),
      ),
    );
  }
}

/// Switches of the fake repository, so every state of the screen can be shown. With a real adapter it disappears.
class _FakeDataMenu extends StatelessWidget {
  const _FakeDataMenu();

  void _announce(BuildContext context, String message) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) {
    final orders = context.read<AppDependencies>().orders;
    if (orders is! FakeCenter) return const SizedBox.shrink();
    return PopupMenuButton<void>(
      tooltip: 'Lažni podaci',
      itemBuilder: (_) => [
        PopupMenuItem(
          onTap: () {
            orders.failingRequests = 1;
            _announce(context, 'Sledeći zahtev neće uspeti. Osvežite listu.');
          },
          child: const ListTile(leading: Icon(Icons.cloud_off_outlined), title: Text('Simuliraj grešku')),
        ),
        PopupMenuItem(
          onTap: () {
            orders.emptyResponses = 1;
            _announce(context, 'Sledeći odgovor biće prazan. Osvežite listu.');
          },
          child: const ListTile(leading: Icon(Icons.inbox_outlined), title: Text('Simuliraj prazan odgovor')),
        ),
      ],
    );
  }
}
