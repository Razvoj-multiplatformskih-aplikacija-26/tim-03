import 'package:meta/meta.dart';

import '../identifiers.dart';

sealed class OrderStatus {
  const OrderStatus();

  /// An active order still holds its pet, kennel and member of staff for its period.
  bool get isActive => switch (this) {
    Pending() || Confirmed() || InProgress() || ReadyForPickup() => true,
    Completed() || Rejected() || Cancelled() => false,
  };
}

final class Pending extends OrderStatus {
  const Pending();

  @override
  String toString() => 'Pending';
}

@immutable
final class Confirmed extends OrderStatus {
  const Confirmed({required this.confirmedBy, required this.at});

  final UserId confirmedBy;
  final DateTime at;

  @override
  bool operator ==(Object other) => other is Confirmed && other.confirmedBy == confirmedBy && other.at == at;

  @override
  int get hashCode => Object.hash(confirmedBy, at);

  @override
  String toString() => 'Confirmed(by $confirmedBy at $at)';
}

/// The pet is in the center, or with the walker.
@immutable
final class InProgress extends OrderStatus {
  const InProgress({required this.receivedBy, required this.at});

  final UserId receivedBy;
  final DateTime at;

  @override
  bool operator ==(Object other) => other is InProgress && other.receivedBy == receivedBy && other.at == at;

  @override
  int get hashCode => Object.hash(receivedBy, at);

  @override
  String toString() => 'InProgress(by $receivedBy at $at)';
}

/// The pet waits for its owner in the center, or the walker has brought it back home.
@immutable
final class ReadyForPickup extends OrderStatus {
  const ReadyForPickup({required this.at});

  final DateTime at;

  @override
  bool operator ==(Object other) => other is ReadyForPickup && other.at == at;

  @override
  int get hashCode => at.hashCode;

  @override
  String toString() => 'ReadyForPickup(at $at)';
}

@immutable
final class Completed extends OrderStatus {
  const Completed({required this.at});

  final DateTime at;

  @override
  bool operator ==(Object other) => other is Completed && other.at == at;

  @override
  int get hashCode => at.hashCode;

  @override
  String toString() => 'Completed(at $at)';
}

@immutable
final class Rejected extends OrderStatus {
  const Rejected({required this.reason, required this.rejectedBy, required this.at});

  final String reason;
  final UserId rejectedBy;
  final DateTime at;

  @override
  bool operator ==(Object other) =>
      other is Rejected && other.reason == reason && other.rejectedBy == rejectedBy && other.at == at;

  @override
  int get hashCode => Object.hash(reason, rejectedBy, at);

  @override
  String toString() => 'Rejected("$reason" by $rejectedBy at $at)';
}

@immutable
final class Cancelled extends OrderStatus {
  const Cancelled({required this.reason, required this.cancelledBy, required this.at});

  final String reason;
  final UserId cancelledBy;
  final DateTime at;

  @override
  bool operator ==(Object other) =>
      other is Cancelled && other.reason == reason && other.cancelledBy == cancelledBy && other.at == at;

  @override
  int get hashCode => Object.hash(reason, cancelledBy, at);

  @override
  String toString() => 'Cancelled("$reason" by $cancelledBy at $at)';
}

/// The only place that says which status changes are allowed. Everything not listed is forbidden.
bool canTransition(OrderStatus from, OrderStatus to) => switch ((from, to)) {
  (Pending(), Confirmed()) => true,
  (Pending(), Rejected()) => true,
  (Pending(), Cancelled()) => true,
  (Confirmed(), Cancelled()) => true,
  (Confirmed(), InProgress()) => true,
  (InProgress(), ReadyForPickup()) => true,
  (ReadyForPickup(), Completed()) => true,
  _ => false,
};
