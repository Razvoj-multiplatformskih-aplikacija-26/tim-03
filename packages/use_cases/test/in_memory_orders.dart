import 'package:domain/domain.dart';
import 'package:use_cases/use_cases.dart';

const owner = User(id: UserId('u-owner'), name: 'Ana', role: Role.owner);
const otherOwner = User(id: UserId('u-owner-2'), name: 'Marko', role: Role.owner);
const manager = User(id: UserId('u-manager'), name: 'Milica', role: Role.manager);

const rex = Pet(
  id: PetId('p-rex'),
  ownerId: UserId('u-owner'),
  name: 'Reks',
  species: Species.dog,
  size: PetSize.large,
);

final tuesdayTen = DateTime.utc(2026, 10, 20, 8);

ServicePeriod grooming(DateTime start) =>
    ServicePeriod.existing(start: start, end: start.add(const Duration(hours: 2)));

ServiceOrder orderAt(DateTime start, {String id = 'o-1', UserId ownerId = const UserId('u-owner')}) => ServiceOrder(
  id: OrderId(id),
  ownerId: ownerId,
  petId: rex.id,
  service: ServiceType.grooming,
  period: grooming(start),
  createdAt: start.subtract(const Duration(days: 3)),
);

/// A repository in memory that decides like the server will: new orders go through the domain's placeOrder.
final class InMemoryOrders implements OrderRepository {
  InMemoryOrders({required this.clock, List<ServiceOrder> orders = const []}) : orders = List.of(orders);

  final Clock clock;
  final List<ServiceOrder> orders;
  bool failing = false;
  int _nextId = 1;

  void _maybeFail() {
    if (failing) throw const RepositoryException('simulated outage');
  }

  @override
  Future<List<ServiceOrder>> ordersOf(UserId ownerId) async {
    _maybeFail();
    return orders.where((o) => o.ownerId == ownerId).toList();
  }

  @override
  Future<ServiceOrder?> find(OrderId id) async {
    _maybeFail();
    return orders.where((o) => o.id == id).firstOrNull;
  }

  @override
  Future<Result<ServiceOrder>> create(OrderRequest request) async {
    _maybeFail();
    final result = placeOrder(
      id: OrderId('o-new-${_nextId++}'),
      by: request.owner,
      pet: request.pet,
      service: request.service,
      period: request.period,
      orders: orders,
      now: clock.now(),
      note: request.note,
    );
    if (result case Success(:final value)) orders.add(value);
    return result;
  }

  @override
  Future<ServiceOrder> save(ServiceOrder order) async {
    _maybeFail();
    orders[orders.indexWhere((o) => o.id == order.id)] = order;
    return order;
  }
}
