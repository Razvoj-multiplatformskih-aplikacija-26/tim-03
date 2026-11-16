import 'package:domain/domain.dart';
import 'package:postgres/postgres.dart' show ServerException;
import 'package:use_cases/use_cases.dart';

import 'center_store.dart';

const _reassignAttempts = 5;

final class PostgresCenter implements OrderRepository, BoardRepository, PetRepository, CenterRepository {
  PostgresCenter(this._store, {required this.clock});

  final CenterStore _store;
  final Clock clock;

  @override
  Future<OpeningHours> openingHours() => _store.openingHours();

  @override
  Future<List<Pet>> petsOf(UserId ownerId) => _store.petsOf(ownerId);

  @override
  Future<List<ServiceOrder>> ordersOf(UserId ownerId) => _store.ordersOf(ownerId);

  @override
  Future<ServiceOrder?> find(OrderId id) => _store.find(id);

  @override
  Future<CenterBoard> board() async => CenterBoard(
    orders: await _store.orders(),
    pets: {for (final pet in await _store.pets()) pet.id: pet},
    people: {for (final person in await _store.people()) person.id: person},
    kennels: await _store.kennels(),
  );

  /// The domain decides on the active orders around the period (R6), and the database decides for good:
  /// when another call stored an overlapping order for the same pet first, the insert fails with 23P01.
  @override
  Future<Result<ServiceOrder>> create(OrderRequest request) async {
    final decided = placeOrder(
      // The database gives the order its id when it is stored.
      id: const OrderId(''),
      by: request.owner,
      pet: request.pet,
      service: request.service,
      period: request.period,
      orders: await _store.activeOrdersAround(request.period),
      now: clock.now(),
      note: request.note,
    );
    if (decided case Failure(:final error)) return Failure(error);
    try {
      return Success(await _store.insert(decided.valueOrNull!));
    } on ServerException catch (error) {
      if (error.code != exclusionViolation) rethrow;
      return const Failure(PetAlreadyBooked());
    }
  }

  /// UPDATE … WHERE status = [from]. Zero changed rows means someone changed the order in the meantime, and
  /// changeStatus in the use cases decides again on the fresh order. A 23P01 means a confirmation at the same
  /// time took the kennel (R7) or the staff member (R8) first, so the domain chooses again on fresh data.
  @override
  Future<Result<ServiceOrder>> save(ServiceOrder order, {required OrderStatus from}) async {
    var changed = order;
    for (var attempt = 0; attempt < _reassignAttempts; attempt++) {
      try {
        if (await _store.changeStatus(changed, from: from)) return Success(changed);
        final current = await _store.find(changed.id);
        if (current == null) return const Failure(NotFound());
        return Failure(InvalidTransition(from: current.status, to: changed.status));
      } on ServerException catch (error) {
        if (error.code != exclusionViolation) rethrow;
        switch (await _assignAgain(changed)) {
          case Success(:final value):
            changed = value;
          case Failure(:final error):
            return Failure(error);
        }
      }
    }
    return Failure(changed.kennelId != null ? const NoKennelAvailable() : const StaffNotAvailable());
  }

  Future<Result<ServiceOrder>> _assignAgain(ServiceOrder order) async {
    final others = [
      for (final other in await _store.activeOrdersAround(order.period))
        if (other.id != order.id) other,
    ];
    if (order.service.needsKennel) {
      final pet = await _store.pet(order.petId);
      if (pet == null) return const Failure(NotFound());
      return switch (assignKennel(
        kennels: await _store.kennels(),
        orders: others,
        period: order.period,
        petSize: pet.size,
      )) {
        Success(value: final kennel) => Success(order.copyWith(kennelId: kennel.id)),
        Failure(:final error) => Failure(error),
      };
    }
    return switch (assignStaff(
      staff: await _store.staff(),
      orders: others,
      service: order.service,
      period: order.period,
    )) {
      Success(value: final member) => Success(order.copyWith(assigneeId: member.id)),
      Failure(:final error) => Failure(error),
    };
  }
}
