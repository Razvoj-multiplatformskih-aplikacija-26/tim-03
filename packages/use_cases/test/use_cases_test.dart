import 'package:domain/domain.dart';
import 'package:test/test.dart';
import 'package:use_cases/use_cases.dart';

import 'in_memory_orders.dart';

void main() {
  final threeDaysBefore = FixedClock(tuesdayTen.subtract(const Duration(days: 3)));

  group('GetMyOrders', () {
    test('returns only the owner\'s orders, earliest first', () async {
      final repository = InMemoryOrders(
        clock: threeDaysBefore,
        orders: [
          orderAt(tuesdayTen.add(const Duration(days: 2)), id: 'o-late'),
          orderAt(tuesdayTen, id: 'o-other', ownerId: otherOwner.id),
          orderAt(tuesdayTen, id: 'o-early'),
        ],
      );
      final mine = await GetMyOrders(orders: repository)(owner);
      expect([for (final order in mine) order.id.value], ['o-early', 'o-late']);
    });
  });

  group('R4 · CancelOrder', () {
    test('decides the deadline with the injected clock and saves the cancelled order', () async {
      final repository = InMemoryOrders(clock: threeDaysBefore, orders: [orderAt(tuesdayTen)]);
      final exactly24h = FixedClock(tuesdayTen.subtract(cancellationNotice));
      final result = await CancelOrder(orders: repository, clock: exactly24h)(id: const OrderId('o-1'), by: owner);
      expect(result.valueOrNull?.status, isA<Cancelled>());
      expect(repository.orders.single.status, isA<Cancelled>());
    });

    test('refuses one minute after the deadline and leaves the order as it was', () async {
      final repository = InMemoryOrders(clock: threeDaysBefore, orders: [orderAt(tuesdayTen)]);
      final late = FixedClock(tuesdayTen.subtract(const Duration(hours: 23, minutes: 59)));
      final result = await CancelOrder(orders: repository, clock: late)(id: const OrderId('o-1'), by: owner);
      expect(result, const Failure<ServiceOrder>(CancellationTooLate()));
      expect(repository.orders.single.status, const Pending());
    });

    test('answers NotFound for an unknown order', () async {
      final repository = InMemoryOrders(clock: threeDaysBefore);
      final result = await CancelOrder(orders: repository, clock: threeDaysBefore)(
        id: const OrderId('o-missing'),
        by: owner,
      );
      expect(result, const Failure<ServiceOrder>(NotFound()));
    });

    test('passes a repository failure on to the caller', () async {
      final repository = InMemoryOrders(clock: threeDaysBefore, orders: [orderAt(tuesdayTen)])..failing = true;
      final cancel = CancelOrder(orders: repository, clock: threeDaysBefore);
      expect(cancel(id: const OrderId('o-1'), by: owner), throwsA(isA<RepositoryException>()));
    });
  });

  group('PlaceOrder', () {
    OrderRequest request({User by = owner, DateTime? start}) =>
        OrderRequest(owner: by, pet: rex, service: ServiceType.grooming, period: grooming(start ?? tuesdayTen));

    test('stores a pending order with an id from the repository', () async {
      final repository = InMemoryOrders(clock: threeDaysBefore);
      final order = (await PlaceOrder(orders: repository)(request())).valueOrNull!;
      expect(order.id, const OrderId('o-new-1'));
      expect(order.status, const Pending());
      expect(repository.orders, [order]);
    });

    test('refuses someone else\'s pet before asking the repository', () async {
      final repository = InMemoryOrders(clock: threeDaysBefore)..failing = true;
      expect(await PlaceOrder(orders: repository)(request(by: otherOwner)), const Failure<ServiceOrder>(NotAllowed()));
    });

    test('R6 · the repository refuses an overlapping order for the same pet', () async {
      final repository = InMemoryOrders(clock: threeDaysBefore, orders: [orderAt(tuesdayTen)]);
      final overlapping = request(start: tuesdayTen.add(const Duration(hours: 1)));
      expect(await PlaceOrder(orders: repository)(overlapping), const Failure<ServiceOrder>(PetAlreadyBooked()));
      expect(repository.orders, hasLength(1));
    });
  });
}
