import 'dart:async';

import 'package:domain/domain.dart';

import 'ports/order_repository.dart';

const _attempts = 3;

/// Reads the order, lets the domain decide [change] and saves it from the state that was read. When someone
/// changed the order in the meantime, the repository answers InvalidTransition from the new state and the
/// change is decided again on the fresh order.
Future<Result<ServiceOrder>> changeStatus(
  OrderRepository orders,
  OrderId id, {
  required User by,
  required FutureOr<Result<ServiceOrder>> Function(ServiceOrder current) change,
}) async {
  Result<ServiceOrder> outcome = const Failure(NotFound());
  for (var attempt = 0; attempt < _attempts; attempt++) {
    final order = await orders.find(id);
    if (order == null || !AccessPolicy.canView(by, order)) return const Failure(NotFound());
    switch (await change(order)) {
      case Failure(:final error):
        return Failure(error);
      case Success(:final value):
        outcome = await orders.save(value, from: order.status);
        if (outcome case Failure(error: InvalidTransition(:final from)) when from != order.status) continue;
        return outcome;
    }
  }
  return outcome;
}
