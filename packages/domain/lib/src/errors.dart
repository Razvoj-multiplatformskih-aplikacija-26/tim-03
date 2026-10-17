import 'package:meta/meta.dart';

import 'order/order_status.dart';

sealed class DomainError {
  const DomainError();
}

@immutable
final class NoteTooLong extends DomainError {
  const NoteTooLong(this.length);

  final int length;

  @override
  bool operator ==(Object other) => other is NoteTooLong && other.length == length;

  @override
  int get hashCode => Object.hash(NoteTooLong, length);

  @override
  String toString() => 'NoteTooLong($length)';
}

@immutable
final class InvalidStayLength extends DomainError {
  const InvalidStayLength(this.nights);

  final int nights;

  @override
  bool operator ==(Object other) => other is InvalidStayLength && other.nights == nights;

  @override
  int get hashCode => Object.hash(InvalidStayLength, nights);

  @override
  String toString() => 'InvalidStayLength($nights)';
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

final class CancellationTooLate extends DomainError {
  const CancellationTooLate();
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
