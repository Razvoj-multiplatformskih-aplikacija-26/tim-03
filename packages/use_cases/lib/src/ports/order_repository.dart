import 'package:domain/domain.dart';

import '../order_request.dart';

abstract interface class OrderRepository {
  Future<List<ServiceOrder>> ordersOf(UserId ownerId);

  Future<ServiceOrder?> find(OrderId id);

  Future<Result<ServiceOrder>> create(OrderRequest request);

  Future<ServiceOrder> save(ServiceOrder order);
}
