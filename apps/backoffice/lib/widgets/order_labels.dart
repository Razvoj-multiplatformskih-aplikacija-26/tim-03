import 'package:domain/domain.dart';
import 'package:ui/ui.dart';

String orderDayLabel(ServiceOrder order) {
  final start = order.period.start;
  return '${capitalize(formatWeekdayShort(start))} ${formatShortDate(start)}';
}

String orderHoursLabel(ServiceOrder order) {
  final period = order.period;
  return switch (order.service.visitLength) {
    null => '${formatTime(period.start)} · ${nightsLabel(nightsOf(period))}',
    _ => '${formatTime(period.start)}–${formatTime(period.end)}',
  };
}
