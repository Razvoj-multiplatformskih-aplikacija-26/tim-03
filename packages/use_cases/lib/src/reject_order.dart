import 'package:domain/domain.dart';

import 'change_status.dart';
import 'clock.dart';
import 'ports/order_repository.dart';

final class RejectOrder {
  const RejectOrder({required this.orders, required this.clock});

  final OrderRepository orders;
  final Clock clock;

  Future<Result<ServiceOrder>> call({required OrderId id, required User by, String reason = ''}) => changeStatus(
    orders,
    id,
    by: by,
    change: (order) => rejectOrder(order, by: by, now: clock.now(), reason: reason),
  );
}
