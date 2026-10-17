import 'package:domain/domain.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

void main() {
  initializeDomainTimeZones();

  final start = belgrade(2026, 10, 20, 10, 0);
  final confirmed = Confirmed(confirmedBy: caretaker.id, at: start.subtract(const Duration(days: 2)));

  group('R5 · status transitions', () {
    test('allows exactly seven transitions out of forty-nine', () {
      final statuses = <OrderStatus>[
        const Pending(),
        confirmed,
        InProgress(receivedBy: caretaker.id, at: start),
        ReadyForPickup(at: start),
        Completed(at: start),
        Rejected(reason: 'test', rejectedBy: manager.id, at: start),
        Cancelled(reason: 'test', cancelledBy: owner.id, at: start),
      ];
      final allowed = <(Type, Type)>[];
      for (final from in statuses) {
        for (final to in statuses) {
          if (canTransition(from, to)) allowed.add((from.runtimeType, to.runtimeType));
        }
      }
      expect(allowed, [
        (Pending, Confirmed),
        (Pending, Rejected),
        (Pending, Cancelled),
        (Confirmed, InProgress),
        (Confirmed, Cancelled),
        (InProgress, ReadyForPickup),
        (ReadyForPickup, Completed),
      ]);
    });

    test('takes an order from confirmed to completed', () {
      final order = orderAt(start, status: confirmed);
      final started = startOrder(order, by: caretaker, now: start).valueOrNull!;
      final ready = markReadyForPickup(started, by: caretaker, now: start.add(const Duration(hours: 2))).valueOrNull!;
      final done = completeOrder(ready, by: caretaker, now: start.add(const Duration(hours: 3))).valueOrNull!;
      expect(started.status, isA<InProgress>());
      expect(ready.status, isA<ReadyForPickup>());
      expect(done.status, isA<Completed>());
    });

    test('refuses to complete an order whose pet has not arrived', () {
      expect(
        completeOrder(
          orderAt(start, status: confirmed),
          by: caretaker,
          now: start,
        ),
        Failure<ServiceOrder>(
          InvalidTransition(
            from: confirmed,
            to: Completed(at: start),
          ),
        ),
      );
    });
  });

  group('R4 · cancelOrder', () {
    test('lets the owner cancel exactly 24 hours before the start', () {
      final result = cancelOrder(orderAt(start), by: owner, now: start.subtract(const Duration(hours: 24)));
      expect(result.valueOrNull?.status, isA<Cancelled>());
    });

    test('refuses the owner one minute after the deadline', () {
      final now = start.subtract(const Duration(hours: 23, minutes: 59));
      expect(cancelOrder(orderAt(start), by: owner, now: now), const Failure<ServiceOrder>(CancellationTooLate()));
    });

    test('lets the manager cancel a confirmed order one hour before the start', () {
      final result = cancelOrder(
        orderAt(start, status: confirmed),
        by: manager,
        now: start.subtract(const Duration(hours: 1)),
        reason: 'bolest negovatelja',
      );
      expect(result.valueOrNull?.status, isA<Cancelled>());
    });

    test('does not cancel an order whose pet is already in the center', () {
      final order = orderAt(
        start,
        status: InProgress(receivedBy: caretaker.id, at: start),
      );
      expect(cancelOrder(order, by: manager, now: start).errorOrNull, isA<InvalidTransition>());
    });
  });

  group('Roles · AccessPolicy', () {
    final yesterday = start.subtract(const Duration(days: 1));

    test('another owner cannot cancel the order', () {
      expect(
        cancelOrder(orderAt(start), by: otherOwner, now: yesterday.subtract(const Duration(days: 1))),
        const Failure<ServiceOrder>(NotAllowed()),
      );
    });

    test('a caretaker can confirm but cannot reject or cancel', () {
      expect(rejectOrder(orderAt(start), by: caretaker, now: yesterday), const Failure<ServiceOrder>(NotAllowed()));
      expect(cancelOrder(orderAt(start), by: caretaker, now: yesterday), const Failure<ServiceOrder>(NotAllowed()));
    });

    test('the manager rejects a pending order', () {
      final result = rejectOrder(orderAt(start), by: manager, now: yesterday, reason: 'nema mesta');
      expect(result.valueOrNull?.status, Rejected(reason: 'nema mesta', rejectedBy: manager.id, at: yesterday));
    });

    test('owners and walkers cannot confirm', () {
      for (final user in [owner, walker]) {
        expect(
          confirmOrder(
            orderAt(start),
            by: user,
            now: yesterday,
            pet: rex,
            orders: const [],
            kennels: const [],
            staff: const [],
          ),
          const Failure<ServiceOrder>(NotAllowed()),
        );
      }
    });

    test('an owner cannot receive a pet', () {
      expect(
        startOrder(
          orderAt(start, status: confirmed),
          by: owner,
          now: start,
        ),
        const Failure<ServiceOrder>(NotAllowed()),
      );
    });
  });
}
