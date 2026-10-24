import 'package:domain/domain.dart';

import 'ports/order_repository.dart';

final class GetMyOrders {
  const GetMyOrders({required this.orders});

  final OrderRepository orders;

  /// The owner's orders, earliest start first.
  Future<List<ServiceOrder>> call(User owner) async {
    final mine = await orders.ordersOf(owner.id);
    return [...mine]..sort((a, b) => a.period.start.compareTo(b.period.start));
  }
}
