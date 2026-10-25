import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ui/ui.dart';

import '../data/fake_data.dart';
import '../dependencies.dart';

class PetsScreen extends StatelessWidget {
  const PetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final owner = context.read<AppDependencies>().owner;
    final pets = fakePets.where((pet) => pet.ownerId == owner.id).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Moji ljubimci')),
      body: BlocBuilder<MyOrdersBloc, MyOrdersState>(
        builder: (context, state) => Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                for (final pet in pets)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _PetCard(pet: pet, activeOrders: _activeOrders(state, pet)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Null while the orders are not loaded, so the card does not claim a number it does not know.
int? _activeOrders(MyOrdersState state, Pet pet) => switch (state) {
  MyOrdersLoaded(:final orders) => orders.where((order) => order.petId == pet.id && order.isActive).length,
  MyOrdersEmpty() => 0,
  MyOrdersLoading() || MyOrdersFailure() => null,
};

class _PetCard extends StatelessWidget {
  const _PetCard({required this.pet, required this.activeOrders});

  final Pet pet;
  final int? activeOrders;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final mutedStyle = theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MergeSemantics(
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: scheme.tertiaryContainer,
                    child: Icon(Icons.pets, color: scheme.onTertiaryContainer),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(pet.name, style: theme.textTheme.titleLarge),
                        const SizedBox(height: 2),
                        Text(pet.description, style: mutedStyle),
                        if (activeOrders case final count?) ...[
                          const SizedBox(height: 2),
                          Text(activeOrdersLabel(count), style: mutedStyle),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => context.push('/orders/new?pet=${pet.id.value}'),
                icon: const Icon(Icons.add),
                label: Text('Zakaži za ljubimca ${pet.name}'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
