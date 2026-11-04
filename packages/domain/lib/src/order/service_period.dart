import 'package:meta/meta.dart';

import '../center/opening_hours.dart';
import '../errors.dart';
import '../result.dart';
import 'service_type.dart';
import 'stay_length.dart';

@immutable
final class ServicePeriod {
  const ServicePeriod._(this.start, this.end);

  ServicePeriod.existing({required DateTime start, required DateTime end}) : this._(start.toUtc(), end.toUtc());

  static const step = Duration(minutes: 30);

  final DateTime start;
  final DateTime end;

  bool overlaps(ServicePeriod other, {Duration gap = Duration.zero}) =>
      start.isBefore(other.end.add(gap)) && other.start.isBefore(end.add(gap));

  static Result<ServicePeriod> parse(
    DateTime start, {
    required ServiceType service,
    required DateTime now,
    required OpeningHours openingHours,
    StayLength nights = StayLength.shortest,
  }) {
    final startUtc = start.toUtc();
    if (!startUtc.isAfter(now.toUtc())) return const Failure(PeriodInPast());
    final onHalfHour =
        startUtc.minute % step.inMinutes == 0 &&
        startUtc.second == 0 &&
        startUtc.millisecond == 0 &&
        startUtc.microsecond == 0;
    if (!onHalfHour) return const Failure(NotOnHalfHour());

    final visitLength = service.visitLength;
    if (visitLength != null) {
      if (!openingHours.covers(startUtc, visitLength)) return const Failure(OutsideOpeningHours());
      return Success(ServicePeriod._(startUtc, startUtc.add(visitLength)));
    }

    final checkOut = openingHours.addLocalDays(startUtc, nights.value);
    if (!openingHours.covers(startUtc, step) || !openingHours.covers(checkOut, step)) {
      return const Failure(OutsideOpeningHours());
    }
    return Success(ServicePeriod._(startUtc, checkOut));
  }

  @override
  bool operator ==(Object other) => other is ServicePeriod && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => 'ServicePeriod(${start.toIso8601String()} – ${end.toIso8601String()})';
}
