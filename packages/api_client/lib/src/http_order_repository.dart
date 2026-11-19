import 'package:api_contract/api_contract.dart';
import 'package:api_mapping/api_mapping.dart';
import 'package:domain/domain.dart';
import 'package:use_cases/use_cases.dart';

import 'api_client.dart';

final class HttpOrderRepository implements OrderRepository {
  const HttpOrderRepository(this._api);

  final ApiClient _api;

  @override
  Future<List<ServiceOrder>> ordersOf(UserId ownerId) async {
    final answer = await _api.get(ApiPaths.ordersOfOwner(ownerId.value));
    return accepted(answer, (json) => [for (final item in objects(json)) _order(item)]);
  }

  @override
  Future<ServiceOrder?> find(OrderId id) async {
    final answer = await _api.get(ApiPaths.order(id.value));
    if (answer case ApiRejected(error: NotFound())) return null;
    return accepted(answer, _order);
  }

  @override
  Future<Result<ServiceOrder>> create(OrderRequest request) async =>
      resultOf(await _api.post(ApiPaths.orders, body: request.toDto().toJson()), _order);

  /// The new state picks the action. [from] stays on the client: the server reads the current state itself and
  /// answers 409 invalid-transition when it changed, so changeStatus reads the order again.
  @override
  Future<Result<ServiceOrder>> save(ServiceOrder order, {required OrderStatus from}) async {
    final id = order.id.value;
    final answer = await switch (order.status) {
      Confirmed() => _api.post(ApiPaths.confirmation(id)),
      Rejected(:final reason) => _api.post(ApiPaths.rejection(id), body: ReasonDto(reason: reason).toJson()),
      Cancelled(:final reason) => _api.post(ApiPaths.cancellation(id), body: ReasonDto(reason: reason).toJson()),
      Pending() => throw ArgumentError.value(order, 'order', 'A pending order is created, not saved'),
      InProgress() ||
      ReadyForPickup() ||
      Completed() => throw ArgumentError.value(order, 'order', 'The server has no action for this state yet'),
    };
    return resultOf(answer, _order);
  }

  ServiceOrder _order(Object? json) => OrderDto.fromJson(object(json)).toDomain();
}
