import 'package:meta/meta.dart';

import 'order/order_status.dart';

sealed class DomainError {
  const DomainError();
}

@immutable
final class NoteTooLong extends DomainError {
  const NoteTooLong(this.length, {required this.max});

  final int length;
  final int max;

  @override
  bool operator ==(Object other) => other is NoteTooLong && other.length == length && other.max == max;

  @override
  int get hashCode => Object.hash(NoteTooLong, length, max);

  @override
  String toString() => 'NoteTooLong($length, max: $max)';
}

@immutable
final class InvalidStayLength extends DomainError {
  const InvalidStayLength(this.nights, {required this.min, required this.max});

  final int nights;
  final int min;
  final int max;

  @override
  bool operator ==(Object other) =>
      other is InvalidStayLength && other.nights == nights && other.min == min && other.max == max;

  @override
  int get hashCode => Object.hash(InvalidStayLength, nights, min, max);

  @override
  String toString() => 'InvalidStayLength($nights, min: $min, max: $max)';
}

final class PeriodInPast extends DomainError {
  const PeriodInPast();
}

final class NotOnHalfHour extends DomainError {
  const NotOnHalfHour();
}

final class OutsideOpeningHours extends DomainError {
  const OutsideOpeningHours();
}

@immutable
final class CancellationTooLate extends DomainError {
  const CancellationTooLate({required this.notice});

  final Duration notice;

  @override
  bool operator ==(Object other) => other is CancellationTooLate && other.notice == notice;

  @override
  int get hashCode => Object.hash(CancellationTooLate, notice);

  @override
  String toString() => 'CancellationTooLate(notice: $notice)';
}

@immutable
final class InvalidTransition extends DomainError {
  const InvalidTransition({required this.from, required this.to});

  final OrderStatus from;
  final OrderStatus to;

  @override
  bool operator ==(Object other) =>
      other is InvalidTransition &&
      other.from.runtimeType == from.runtimeType &&
      other.to.runtimeType == to.runtimeType;

  @override
  int get hashCode => Object.hash(InvalidTransition, from.runtimeType, to.runtimeType);

  @override
  String toString() => 'InvalidTransition(${from.runtimeType} -> ${to.runtimeType})';
}

final class PetAlreadyBooked extends DomainError {
  const PetAlreadyBooked();
}

final class NoKennelAvailable extends DomainError {
  const NoKennelAvailable();
}

final class StaffNotAvailable extends DomainError {
  const StaffNotAvailable();
}

final class NotAllowed extends DomainError {
  const NotAllowed();
}

final class NotFound extends DomainError {
  const NotFound();
}
