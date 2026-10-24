import 'package:domain/domain.dart';

import 'clock.dart';
import 'ports/order_repository.dart';

final class CancelOrder {
  const CancelOrder({required this.orders, required this.clock});

  final OrderRepository orders;
  final Clock clock;

  /// Finds the order, lets the domain decide (roles, R5, R4), and saves the cancelled order.
  Future<Result<ServiceOrder>> call({required OrderId id, required User by, String reason = ''}) async {
    final order = await orders.find(id);
    if (order == null) return const Failure(NotFound());
    return switch (cancelOrder(order, by: by, now: clock.now(), reason: reason)) {
      Failure(:final error) => Failure(error),
      Success(:final value) => Success(await orders.save(value)),
    };
  }
}
