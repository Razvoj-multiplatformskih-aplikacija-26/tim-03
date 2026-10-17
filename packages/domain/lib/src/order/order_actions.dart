import '../availability.dart';
import '../center/kennel.dart';
import '../errors.dart';
import '../identifiers.dart';
import '../pet/pet.dart';
import '../result.dart';
import '../user.dart';
import 'access_policy.dart';
import 'order_note.dart';
import 'order_status.dart';
import 'service_order.dart';
import 'service_period.dart';
import 'service_type.dart';

const cancellationNotice = Duration(hours: 24);

DateTime cancellationDeadline(ServiceOrder order) => order.period.start.subtract(cancellationNotice);

bool ownerMayStillCancel(ServiceOrder order, {required DateTime now}) =>
    !now.toUtc().isAfter(cancellationDeadline(order));

Result<ServiceOrder> placeOrder({
  required OrderId id,
  required User by,
  required Pet pet,
  required ServiceType service,
  required ServicePeriod period,
  required List<ServiceOrder> orders,
  required DateTime now,
  OrderNote? note,
}) {
  if (!AccessPolicy.canPlaceOrder(by, pet)) return const Failure(NotAllowed());
  if (!petIsFree(petId: pet.id, orders: orders, period: period)) return const Failure(PetAlreadyBooked());
  return Success(
    ServiceOrder(
      id: id,
      ownerId: by.id,
      petId: pet.id,
      service: service,
      period: period,
      createdAt: now.toUtc(),
      note: note,
    ),
  );
}

/// Confirms the order and reserves what it needs: a kennel for boarding, a member of staff for everything else.
Result<ServiceOrder> confirmOrder(
  ServiceOrder order, {
  required User by,
  required DateTime now,
  required Pet pet,
  required List<ServiceOrder> orders,
  required List<Kennel> kennels,
  required List<User> staff,
}) {
  if (!AccessPolicy.canConfirm(by)) return const Failure(NotAllowed());
  final next = Confirmed(confirmedBy: by.id, at: now.toUtc());
  if (!canTransition(order.status, next)) return Failure(InvalidTransition(from: order.status, to: next));

  if (order.service.needsKennel) {
    return switch (assignKennel(kennels: kennels, orders: orders, period: order.period, petSize: pet.size)) {
      Success(value: final kennel) => Success(order.copyWith(status: next, kennelId: kennel.id)),
      Failure(:final error) => Failure(error),
    };
  }
  return switch (assignStaff(staff: staff, orders: orders, service: order.service, period: order.period)) {
    Success(value: final member) => Success(order.copyWith(status: next, assigneeId: member.id)),
    Failure(:final error) => Failure(error),
  };
}

Result<ServiceOrder> rejectOrder(ServiceOrder order, {required User by, required DateTime now, String reason = ''}) {
  if (!AccessPolicy.canReject(by)) return const Failure(NotAllowed());
  return _transition(order, Rejected(reason: reason, rejectedBy: by.id, at: now.toUtc()));
}

Result<ServiceOrder> cancelOrder(ServiceOrder order, {required User by, required DateTime now, String reason = ''}) {
  if (!AccessPolicy.canCancel(by, order)) return const Failure(NotAllowed());
  final next = Cancelled(reason: reason, cancelledBy: by.id, at: now.toUtc());
  if (!canTransition(order.status, next)) return Failure(InvalidTransition(from: order.status, to: next));
  if (by.role == Role.owner && !ownerMayStillCancel(order, now: now)) return const Failure(CancellationTooLate());
  return Success(order.copyWith(status: next));
}

/// The pet arrives in the center, or the walker picks it up.
Result<ServiceOrder> startOrder(ServiceOrder order, {required User by, required DateTime now}) {
  if (!AccessPolicy.canHandlePet(by)) return const Failure(NotAllowed());
  return _transition(order, InProgress(receivedBy: by.id, at: now.toUtc()));
}

Result<ServiceOrder> markReadyForPickup(ServiceOrder order, {required User by, required DateTime now}) {
  if (!AccessPolicy.canHandlePet(by)) return const Failure(NotAllowed());
  return _transition(order, ReadyForPickup(at: now.toUtc()));
}

Result<ServiceOrder> completeOrder(ServiceOrder order, {required User by, required DateTime now}) {
  if (!AccessPolicy.canHandlePet(by)) return const Failure(NotAllowed());
  return _transition(order, Completed(at: now.toUtc()));
}

Result<ServiceOrder> _transition(ServiceOrder order, OrderStatus next) {
  if (!canTransition(order.status, next)) return Failure(InvalidTransition(from: order.status, to: next));
  return Success(order.copyWith(status: next));
}
