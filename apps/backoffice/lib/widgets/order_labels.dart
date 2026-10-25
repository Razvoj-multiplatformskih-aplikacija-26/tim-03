import 'package:domain/domain.dart';
import 'package:ui/ui.dart';

/// The day an order starts, short: 'Pon 26. 10.'.
String orderDayLabel(ServiceOrder order) {
  final start = order.period.start;
  return '${capitalize(formatWeekdayShort(start))} ${formatShortDate(start)}';
}

/// The hours of a visit, or the hand-over time and the nights of a stay.
String orderHoursLabel(ServiceOrder order) {
  final period = order.period;
  return switch (order.service.visitLength) {
    null => '${formatTime(period.start)} · ${nightsLabel(nightsOf(period))}',
    _ => '${formatTime(period.start)}–${formatTime(period.end)}',
  };
}
