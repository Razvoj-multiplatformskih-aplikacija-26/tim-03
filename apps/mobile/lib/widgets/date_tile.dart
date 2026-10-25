import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:ui/ui.dart';

/// A small calendar page with the weekday, day and month of [instant] in the center's time zone.
class DateTile extends StatelessWidget {
  const DateTile({super.key, required this.instant, this.today = false, this.muted = false});

  final DateTime instant;

  /// Drawn in the primary color, so today's orders stand out.
  final bool today;

  /// Drawn in grey, for orders that are over.
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final (background, foreground) = switch ((today, muted)) {
      (true, _) => (scheme.primary, scheme.onPrimary),
      (false, true) => (scheme.surfaceContainerHighest, scheme.onSurfaceVariant),
      (false, false) => (scheme.secondaryContainer, scheme.onSecondaryContainer),
    };
    final smallStyle = theme.textTheme.labelSmall?.copyWith(color: foreground, letterSpacing: 0.8);
    return Semantics(
      label: capitalize(formatDate(instant)),
      excludeSemantics: true,
      child: Container(
        width: 56,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(14)),
        child: Column(
          children: [
            Text(formatWeekdayShort(instant).toUpperCase(), style: smallStyle),
            Text(
              '${centerTime(instant).day}',
              style: theme.textTheme.headlineSmall?.copyWith(color: foreground, fontWeight: FontWeight.w700),
            ),
            Text(formatMonthShort(instant).toUpperCase(), style: smallStyle),
          ],
        ),
      ),
    );
  }
}
