import 'package:domain/domain.dart';
import 'package:use_cases/use_cases.dart';

import 'seed.dart';

final class FakeCenter implements OrderRepository, BoardRepository {
  FakeCenter({required this.clock, this.latency = const Duration(milliseconds: 400)})
    : _orders = seedOrders(clock.now());

  final Clock clock;
  final Duration latency;
  final List<ServiceOrder> _orders;

  int _nextId = 1;

  Future<void> _roundTrip() => Future<void>.delayed(latency);

  @override
  Future<CenterBoard> board() async {
    await _roundTrip();
    return CenterBoard(
      // A copy, so the board a screen holds does not change when an order is saved.
      orders: List.unmodifiable(_orders),
      pets: {for (final pet in fakePets) pet.id: pet},
      people: {
        for (final person in [...fakeOwners, ...fakeStaff]) person.id: person,
      },
      kennels: fakeKennels,
    );
  }

  @override
  Future<List<ServiceOrder>> ordersOf(UserId ownerId) async {
    await _roundTrip();
    return _orders.where((order) => order.ownerId == ownerId).toList();
  }

  @override
  Future<ServiceOrder?> find(OrderId id) async {
    await _roundTrip();
    return _orders.where((order) => order.id == id).firstOrNull;
  }

  @override
  Future<Result<ServiceOrder>> create(OrderRequest request) async {
    await _roundTrip();
    final result = placeOrder(
      id: OrderId('o-local-${_nextId++}'),
      by: request.owner,
      pet: request.pet,
      service: request.service,
      period: request.period,
      orders: _orders,
      now: clock.now(),
      note: request.note,
    );
    if (result case Success(:final value)) _orders.add(value);
    return result;
  }

  @override
  Future<ServiceOrder> save(ServiceOrder order) async {
    await _roundTrip();
    _orders[_orders.indexWhere((existing) => existing.id == order.id)] = order;
    return order;
  }
}
