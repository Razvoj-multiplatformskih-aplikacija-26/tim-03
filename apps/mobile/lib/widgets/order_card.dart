import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

import '../data/fake_data.dart';
import '../text/serbian.dart';
import 'date_tile.dart';
import 'service_avatar.dart';
import 'status_badge.dart';

class OrderCard extends StatelessWidget {
  const OrderCard({super.key, required this.order, required this.onOpen});

  final ServiceOrder order;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final now = DateTime.now();
    final pet = petById(order.petId);
    final start = order.period.start;
    final reason = switch (order.status) {
      Rejected(:final reason) || Cancelled(:final reason) when reason.isNotEmpty => reason,
      _ => null,
    };
    return Card(
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: MergeSemantics(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DateTile(instant: start, today: centerDay(start) == centerDay(now), muted: !order.isActive),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(serviceIcon(order.service), size: 18, color: scheme.primary),
                          const SizedBox(width: 6),
                          Expanded(child: Text(order.service.label, style: theme.textTheme.titleMedium)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 14,
                        runSpacing: 4,
                        children: [
                          if (pet != null) _Detail(icon: Icons.pets, iconColor: scheme.tertiary, text: pet.name),
                          _Detail(
                            icon: order.service.visitLength == null ? Icons.nights_stay_outlined : Icons.schedule,
                            text: timeLabel(order, now: now),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      StatusBadge(status: order.status, service: order.service),
                      if (reason != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          reason,
                          style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({required this.icon, required this.text, this.iconColor});

  final IconData icon;
  final String text;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: iconColor ?? muted),
        const SizedBox(width: 4),
        Flexible(
          child: Text(text, style: theme.textTheme.bodyMedium?.copyWith(color: muted)),
        ),
      ],
    );
  }
}
