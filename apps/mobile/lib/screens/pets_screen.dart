import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/fake_data.dart';
import '../text/serbian.dart';

class PetsScreen extends StatelessWidget {
  const PetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final pets = fakePets.where((pet) => pet.ownerId == currentOwner.id).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Moji ljubimci')),
      body: ListenableBuilder(
        listenable: fakeOrders,
        builder: (context, _) => Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                for (final pet in pets)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _PetCard(
                      pet: pet,
                      activeOrders: fakeOrders.all.where((order) => order.petId == pet.id && order.isActive).length,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PetCard extends StatelessWidget {
  const _PetCard({required this.pet, required this.activeOrders});

  final Pet pet;
  final int activeOrders;

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
                        const SizedBox(height: 2),
                        Text(activeOrdersLabel(activeOrders), style: mutedStyle),
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
