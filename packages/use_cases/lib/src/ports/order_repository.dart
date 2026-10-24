import 'package:domain/domain.dart';

import '../order_request.dart';

/// Port to the orders. In KT1 every app has its own fake implementation in memory; from KT2 an HTTP adapter talks to
/// the server. A method that cannot reach the data throws a [RepositoryException].
abstract interface class OrderRepository {
  Future<List<ServiceOrder>> ordersOf(UserId ownerId);

  Future<ServiceOrder?> find(OrderId id);

  /// Stores a new order and gives it an id. The implementation checks the rules over everyone's orders once more
  /// (R6), so the answer can still be a [Failure]; from KT2 that decision is the server's.
  Future<Result<ServiceOrder>> create(OrderRequest request);

  Future<ServiceOrder> save(ServiceOrder order);
}
