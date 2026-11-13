import 'package:domain/domain.dart';
import 'package:use_cases/use_cases.dart';

const owner = User(id: UserId('u-owner'), name: 'Ana', role: Role.owner);

const rex = PetId('p-rex');
const mica = PetId('p-mica');

const ownerPets = [
  Pet(id: rex, ownerId: UserId('u-owner'), name: 'Reks', species: Species.dog, size: PetSize.large),
  Pet(id: mica, ownerId: UserId('u-owner'), name: 'Mica', species: Species.cat, size: PetSize.small),
];

final mondayNine = DateTime.utc(2026, 10, 19, 7);

ServiceOrder orderAt(DateTime start, {required String id, PetId petId = rex, OrderStatus status = const Pending()}) =>
    ServiceOrder(
      id: OrderId(id),
      ownerId: owner.id,
      petId: petId,
      service: ServiceType.grooming,
      period: ServicePeriod.existing(start: start, end: start.add(const Duration(hours: 2))),
      status: status,
      createdAt: start.subtract(const Duration(days: 7)),
    );

/// Orders in memory, without delay; [failing] makes every request throw, like a lost connection.
final class InMemoryOrders implements OrderRepository {
  InMemoryOrders([List<ServiceOrder> orders = const []]) : orders = List.of(orders);

  final List<ServiceOrder> orders;
  bool failing = false;

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
    final order = ServiceOrder(
      id: OrderId('o-new-${orders.length + 1}'),
      ownerId: request.owner.id,
      petId: request.pet.id,
      service: request.service,
      period: request.period,
      note: request.note,
      createdAt: mondayNine,
    );
    orders.add(order);
    return Success(order);
  }

  @override
  Future<Result<ServiceOrder>> save(ServiceOrder order, {required OrderStatus from}) async {
    _maybeFail();
    orders[orders.indexWhere((o) => o.id == order.id)] = order;
    return Success(order);
  }
}

/// The owner's pets and the center's opening hours, without delay. The hours need the domain's time zones.
final class InMemoryCenter implements PetRepository, CenterRepository {
  InMemoryCenter([this.pets = ownerPets]);

  final List<Pet> pets;

  @override
  Future<List<Pet>> petsOf(UserId ownerId) async => pets.where((pet) => pet.ownerId == ownerId).toList();

  @override
  Future<OpeningHours> openingHours() async => OpeningHours({
    for (var weekday = DateTime.monday; weekday <= DateTime.saturday; weekday++)
      weekday: const DayHours(open: LocalTime(8, 0), close: LocalTime(20, 0)),
  });
}
