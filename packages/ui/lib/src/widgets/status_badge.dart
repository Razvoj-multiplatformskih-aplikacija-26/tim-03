import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

import '../status_colors.dart';
import '../text/serbian.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status, required this.service});

  final OrderStatus status;
  final ServiceType service;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.statusColors;
    final tone = switch (status) {
      Pending() => colors.pending,
      Confirmed() => colors.confirmed,
      InProgress() => colors.inProgress,
      ReadyForPickup() => colors.readyForPickup,
      Completed() => colors.completed,
      Rejected() => colors.rejected,
      Cancelled() => colors.cancelled,
    };
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: tone.background, borderRadius: BorderRadius.circular(999)),
      child: Text(statusLabel(status, service), style: theme.textTheme.labelMedium?.copyWith(color: tone.foreground)),
    );
  }
}
