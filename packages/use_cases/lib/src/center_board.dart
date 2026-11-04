import 'package:collection/collection.dart' show ListEquality, MapEquality;
import 'package:domain/domain.dart';

final class CenterBoard {
  const CenterBoard({required this.orders, required this.pets, required this.people, required this.kennels});

  final List<ServiceOrder> orders;
  final Map<PetId, Pet> pets;

  final Map<UserId, User> people;

  final List<Kennel> kennels;

  List<User> get staff => [
    for (final person in people.values)
      if (person.role.isStaff) person,
  ];

  ServiceOrder? orderById(OrderId id) => orders.where((order) => order.id == id).firstOrNull;

  Pet? petOf(ServiceOrder order) => pets[order.petId];

  User? ownerOf(ServiceOrder order) => people[order.ownerId];

  User? assigneeOf(ServiceOrder order) => switch (order.assigneeId) {
    final id? => people[id],
    null => null,
  };

  Kennel? kennelOf(ServiceOrder order) => switch (order.kennelId) {
    final id? => kennels.where((kennel) => kennel.id == id).firstOrNull,
    null => null,
  };

  @override
  bool operator ==(Object other) =>
      other is CenterBoard &&
      const ListEquality<ServiceOrder>().equals(other.orders, orders) &&
      const MapEquality<PetId, Pet>().equals(other.pets, pets) &&
      const MapEquality<UserId, User>().equals(other.people, people) &&
      const ListEquality<Kennel>().equals(other.kennels, kennels);

  @override
  int get hashCode => Object.hash(Object.hashAll(orders), pets.length, people.length, Object.hashAll(kennels));

  @override
  String toString() => 'CenterBoard(${orders.length} orders)';
}
