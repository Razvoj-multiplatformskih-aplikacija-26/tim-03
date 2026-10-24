import 'package:domain/domain.dart';

import 'order_request.dart';
import 'ports/order_repository.dart';

final class PlaceOrder {
  const PlaceOrder({required this.orders});

  final OrderRepository orders;

  /// The client refuses what it can decide on its own; the repository decides the rest over everyone's orders.
  Future<Result<ServiceOrder>> call(OrderRequest request) async {
    if (!AccessPolicy.canPlaceOrder(request.owner, request.pet)) return const Failure(NotAllowed());
    return orders.create(request);
  }
}
