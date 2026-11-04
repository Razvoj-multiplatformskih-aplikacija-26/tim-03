import 'package:domain/domain.dart';

import 'clock.dart';
import 'ports/order_repository.dart';

final class RejectOrder {
  const RejectOrder({required this.orders, required this.clock});

  final OrderRepository orders;
  final Clock clock;

  Future<Result<ServiceOrder>> call({required OrderId id, required User by, String reason = ''}) async {
    final order = await orders.find(id);
    if (order == null) return const Failure(NotFound());
    return switch (rejectOrder(order, by: by, now: clock.now(), reason: reason)) {
      Failure(:final error) => Failure(error),
      Success(:final value) => Success(await orders.save(value)),
    };
  }
}
