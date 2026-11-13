import 'package:domain/domain.dart';

import '../order_request.dart';

abstract interface class OrderRepository {
  Future<List<ServiceOrder>> ordersOf(UserId ownerId);

  Future<ServiceOrder?> find(OrderId id);

  Future<Result<ServiceOrder>> create(OrderRequest request);

  /// Stores [order] only if the stored order is still in the [from] state; otherwise answers [InvalidTransition]
  /// from the state it is in now.
  Future<Result<ServiceOrder>> save(ServiceOrder order, {required OrderStatus from});
}
