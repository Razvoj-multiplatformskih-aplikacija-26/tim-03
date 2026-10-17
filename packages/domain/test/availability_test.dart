import 'package:domain/domain.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

void main() {
  initializeDomainTimeZones();

  final now = belgrade(2026, 10, 19, 9, 0);
  final ten = belgrade(2026, 10, 20, 10, 0);
  final confirmed = Confirmed(confirmedBy: caretaker.id, at: now);
  final cancelled = Cancelled(reason: 'test', cancelledBy: owner.id, at: now);

  ServicePeriod period(DateTime start, Duration length) => ServicePeriod.existing(start: start, end: start.add(length));

  group('R6 · one pet, one order at a time', () {
    final grooming = period(ten, const Duration(hours: 2));

    test('a pet with an overlapping active order is not free', () {
      expect(petIsFree(petId: rex.id, orders: [orderAt(belgrade(2026, 10, 20, 11, 0))], period: grooming), isFalse);
    });

    test('cancelled orders, other pets and touching periods do not count', () {
      final orders = [
        orderAt(ten, id: 'o-1', status: cancelled),
        orderAt(ten, id: 'o-2', petId: mica.id),
        orderAt(belgrade(2026, 10, 20, 12, 0), id: 'o-3'),
      ];
      expect(petIsFree(petId: rex.id, orders: orders, period: grooming), isTrue);
    });

    test('placeOrder creates a pending order for the owner', () {
      final result = placeOrder(
        id: const OrderId('o-new'),
        by: owner,
        pet: rex,
        service: ServiceType.grooming,
        period: grooming,
        orders: const [],
        now: now,
      );
      expect(result.valueOrNull?.status, const Pending());
      expect(result.valueOrNull?.ownerId, owner.id);
    });

    test('placeOrder refuses an overlapping order for the same pet', () {
      final result = placeOrder(
        id: const OrderId('o-new'),
        by: owner,
        pet: rex,
        service: ServiceType.vetCheckup,
        period: period(belgrade(2026, 10, 20, 11, 0), const Duration(minutes: 30)),
        orders: [orderAt(ten)],
        now: now,
      );
      expect(result, const Failure<ServiceOrder>(PetAlreadyBooked()));
    });

    test('placeOrder refuses someone else\'s pet and staff members', () {
      for (final user in [otherOwner, manager]) {
        final result = placeOrder(
          id: const OrderId('o-new'),
          by: user,
          pet: rex,
          service: ServiceType.grooming,
          period: grooming,
          orders: const [],
          now: now,
        );
        expect(result, const Failure<ServiceOrder>(NotAllowed()));
      }
    });
  });

  group('R7 · kennel capacity', () {
    const kennels = [
      Kennel(id: KennelId('k-1'), label: 'B1', size: PetSize.small),
      Kennel(id: KennelId('k-2'), label: 'B2', size: PetSize.medium),
      Kennel(id: KennelId('k-3'), label: 'B3', size: PetSize.large),
    ];
    final stay = period(ten, const Duration(days: 3));

    ServiceOrder boarding(String id, String kennelId, DateTime start, {OrderStatus? status}) => orderAt(
      start,
      id: id,
      service: ServiceType.boarding,
      length: const Duration(days: 3),
      status: status ?? confirmed,
      ownerId: otherOwner.id,
      petId: PetId('p-$id'),
      kennelId: KennelId(kennelId),
    );

    test('a kennel fits pets up to its own size', () {
      List<String> free(PetSize size) => [
        for (final k in freeKennelsFor(kennels: kennels, orders: const [], period: stay, petSize: size)) k.label,
      ];
      expect(free(PetSize.small), ['B1', 'B2', 'B3']);
      expect(free(PetSize.large), ['B3']);
    });

    test('another owner\'s active stay takes the kennel, a cancelled or touching one does not', () {
      expect(
        freeKennelsFor(kennels: kennels, orders: [boarding('a', 'k-3', ten)], period: stay, petSize: PetSize.large),
        isEmpty,
      );
      final orders = [
        boarding('b', 'k-3', ten, status: cancelled),
        boarding('c', 'k-3', ten.subtract(const Duration(days: 3))),
      ];
      expect(freeKennelsFor(kennels: kennels, orders: orders, period: stay, petSize: PetSize.large), [kennels[2]]);
    });

    test('assignKennel picks the smallest kennel that fits', () {
      expect(
        assignKennel(kennels: kennels, orders: const [], period: stay, petSize: PetSize.small).valueOrNull?.label,
        'B1',
      );
    });

    test('assignKennel fails when every fitting kennel is taken', () {
      expect(
        assignKennel(kennels: kennels, orders: [boarding('a', 'k-3', ten)], period: stay, petSize: PetSize.large),
        const Failure<Kennel>(NoKennelAvailable()),
      );
    });
  });

  group('R8 · staff schedule', () {
    const otherCaretaker = User(id: UserId('u-caretaker-2'), name: 'Ivana', role: Role.caretaker);
    const staff = [caretaker, otherCaretaker, vet, walker];

    test('only members with the role the service needs are offered', () {
      final free = freeStaffFor(
        staff: staff,
        orders: const [],
        service: ServiceType.grooming,
        period: period(ten, const Duration(hours: 2)),
      );
      expect(free, [caretaker, otherCaretaker]);
    });

    test('a caretaker with an overlapping appointment is busy', () {
      final free = freeStaffFor(
        staff: staff,
        orders: [orderAt(ten, status: confirmed, assigneeId: caretaker.id, ownerId: otherOwner.id)],
        service: ServiceType.grooming,
        period: period(belgrade(2026, 10, 20, 11, 0), const Duration(hours: 2)),
      );
      expect(free, [otherCaretaker]);
    });

    test('a walker needs 30 minutes between two walks', () {
      final walk = orderAt(
        ten,
        service: ServiceType.walk,
        length: const Duration(hours: 1),
        status: confirmed,
        assigneeId: walker.id,
      );
      List<User> freeAt(int hour, int minute) => freeStaffFor(
        staff: staff,
        orders: [walk],
        service: ServiceType.walk,
        period: period(belgrade(2026, 10, 20, hour, minute), const Duration(hours: 1)),
      );
      expect(freeAt(11, 0), isEmpty);
      expect(freeAt(11, 30), [walker]);
    });

    test('assignStaff fails when nobody with the role is free', () {
      expect(
        assignStaff(
          staff: staff,
          orders: [orderAt(ten, status: confirmed, assigneeId: vet.id)],
          service: ServiceType.vetCheckup,
          period: period(ten, const Duration(minutes: 30)),
        ),
        const Failure<User>(StaffNotAvailable()),
      );
    });
  });

  group('confirmOrder reserves what the order needs', () {
    const kennels = [Kennel(id: KennelId('k-3'), label: 'B3', size: PetSize.large)];

    test('a kennel for boarding', () {
      final order = orderAt(ten, service: ServiceType.boarding, length: const Duration(days: 2));
      final result = confirmOrder(
        order,
        by: caretaker,
        now: now,
        pet: rex,
        orders: [order],
        kennels: kennels,
        staff: const [],
      );
      expect(result.valueOrNull?.status, Confirmed(confirmedBy: caretaker.id, at: now));
      expect(result.valueOrNull?.kennelId, const KennelId('k-3'));
    });

    test('a member of staff for a vet checkup', () {
      final order = orderAt(ten, service: ServiceType.vetCheckup, length: const Duration(minutes: 30));
      final result = confirmOrder(
        order,
        by: manager,
        now: now,
        pet: rex,
        orders: [order],
        kennels: kennels,
        staff: [vet],
      );
      expect(result.valueOrNull?.assigneeId, vet.id);
    });

    test('fails when no kennel is free', () {
      final taken = orderAt(
        ten,
        id: 'o-other',
        service: ServiceType.boarding,
        length: const Duration(days: 2),
        status: confirmed,
        petId: const PetId('p-other'),
        kennelId: const KennelId('k-3'),
      );
      final order = orderAt(ten, service: ServiceType.boarding, length: const Duration(days: 2));
      expect(
        confirmOrder(
          order,
          by: caretaker,
          now: now,
          pet: rex,
          orders: [taken, order],
          kennels: kennels,
          staff: const [],
        ),
        const Failure<ServiceOrder>(NoKennelAvailable()),
      );
    });
  });
}
