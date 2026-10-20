import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

import '../data/fake_data.dart';
import '../text/serbian.dart';
import 'service_avatar.dart';
import 'status_badge.dart';

class OrderCard extends StatelessWidget {
  const OrderCard({super.key, required this.order, required this.onOpen});

  final ServiceOrder order;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mutedStyle = theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final pet = petById(order.petId);
    return Card(
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: MergeSemantics(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ServiceAvatar(service: order.service),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pet == null ? order.service.label : '${order.service.label} · ${pet.name}',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(periodLabel(order), style: mutedStyle),
                      const SizedBox(height: 10),
                      StatusBadge(status: order.status, service: order.service),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
