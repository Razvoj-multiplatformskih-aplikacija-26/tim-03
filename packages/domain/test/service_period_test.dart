import 'package:domain/domain.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

void main() {
  initializeDomainTimeZones();

  final hours = standardOpeningHours();
  final now = belgrade(2026, 10, 19, 9, 0); // Monday

  Result<ServicePeriod> visit(DateTime start, {ServiceType service = ServiceType.grooming}) =>
      ServicePeriod.parse(start, service: service, now: now, openingHours: hours);

  Result<ServicePeriod> stay(DateTime checkIn, int nights) => ServicePeriod.parse(
    checkIn,
    service: ServiceType.boarding,
    nights: StayLength.parse(nights).valueOrNull!,
    now: now,
    openingHours: hours,
  );

  group('R3 · ServicePeriod for a visit', () {
    test('lasts as long as one visit of the service', () {
      final period = visit(belgrade(2026, 10, 20, 10, 0)).valueOrNull;
      expect(period?.end, belgrade(2026, 10, 20, 12, 0));
      expect(
        visit(belgrade(2026, 10, 20, 10, 0), service: ServiceType.vetCheckup).valueOrNull?.end,
        belgrade(2026, 10, 20, 10, 30),
      );
    });

    test('rejects a start that is not in the future', () {
      expect(visit(now), const Failure<ServicePeriod>(PeriodInPast()));
      expect(visit(now.subtract(const Duration(hours: 1))), const Failure<ServicePeriod>(PeriodInPast()));
    });

    test('accepts the full hour and the half hour and rejects anything else', () {
      expect(visit(belgrade(2026, 10, 20, 10, 30)).isSuccess, isTrue);
      expect(visit(belgrade(2026, 10, 20, 10, 15)), const Failure<ServicePeriod>(NotOnHalfHour()));
    });

    test('accepts a visit from opening time and one that ends exactly at closing time', () {
      expect(visit(belgrade(2026, 10, 20, 8, 0)).isSuccess, isTrue);
      expect(visit(belgrade(2026, 10, 20, 18, 0)).isSuccess, isTrue);
    });

    test('rejects a visit that starts before opening or ends after closing', () {
      expect(visit(belgrade(2026, 10, 20, 7, 30)), const Failure<ServicePeriod>(OutsideOpeningHours()));
      expect(visit(belgrade(2026, 10, 20, 18, 30)), const Failure<ServicePeriod>(OutsideOpeningHours()));
    });

    test('rejects a visit on a day the center is closed', () {
      expect(visit(belgrade(2026, 10, 25, 10, 0)), const Failure<ServicePeriod>(OutsideOpeningHours()));
    });
  });

  group('R3 · ServicePeriod for boarding', () {
    test('ends after the given number of nights at the same local time', () {
      final period = stay(belgrade(2026, 10, 20, 10, 0), 3).valueOrNull;
      expect(period?.end, belgrade(2026, 10, 23, 10, 0));
    });

    test('keeps the local check-out time across the end of daylight saving time', () {
      final period = stay(belgrade(2026, 10, 23, 10, 0), 4).valueOrNull!;
      expect(period.end, belgrade(2026, 10, 27, 10, 0));
      expect(period.end.difference(period.start), const Duration(days: 4, hours: 1));
    });

    test('rejects a check-out on a day the center is closed', () {
      expect(stay(belgrade(2026, 10, 23, 10, 0), 2), const Failure<ServicePeriod>(OutsideOpeningHours()));
    });

    test('needs half an hour of opening time to hand the pet over', () {
      expect(stay(belgrade(2026, 10, 20, 19, 30), 1).isSuccess, isTrue);
      expect(stay(belgrade(2026, 10, 20, 20, 0), 1), const Failure<ServicePeriod>(OutsideOpeningHours()));
    });
  });

  group('ServicePeriod.overlaps', () {
    final morning = ServicePeriod.existing(start: belgrade(2026, 10, 20, 10), end: belgrade(2026, 10, 20, 11));

    test('periods that only touch do not overlap', () {
      final next = ServicePeriod.existing(start: belgrade(2026, 10, 20, 11), end: belgrade(2026, 10, 20, 12));
      expect(morning.overlaps(next), isFalse);
      expect(next.overlaps(morning), isFalse);
    });

    test('a gap makes touching periods overlap', () {
      final next = ServicePeriod.existing(start: belgrade(2026, 10, 20, 11), end: belgrade(2026, 10, 20, 12));
      expect(morning.overlaps(next, gap: const Duration(minutes: 30)), isTrue);
    });
  });
}
