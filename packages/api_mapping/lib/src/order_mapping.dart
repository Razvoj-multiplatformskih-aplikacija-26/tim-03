import 'package:api_contract/api_contract.dart';
import 'package:domain/domain.dart';
import 'package:use_cases/use_cases.dart';

import 'center_mapping.dart';

extension OrderStatusMapping on OrderStatus {
  OrderStatusDto toDto() => switch (this) {
    Pending() => const OrderStatusDto(kind: OrderStatusDto.pending),
    Confirmed(:final confirmedBy, :final at) => OrderStatusDto(
      kind: OrderStatusDto.confirmed,
      by: confirmedBy.value,
      at: at,
    ),
    InProgress(:final receivedBy, :final at) => OrderStatusDto(
      kind: OrderStatusDto.inProgress,
      by: receivedBy.value,
      at: at,
    ),
    ReadyForPickup(:final at) => OrderStatusDto(kind: OrderStatusDto.readyForPickup, at: at),
    Completed(:final at) => OrderStatusDto(kind: OrderStatusDto.completed, at: at),
    Rejected(:final reason, :final rejectedBy, :final at) => OrderStatusDto(
      kind: OrderStatusDto.rejected,
      by: rejectedBy.value,
      at: at,
      reason: reason,
    ),
    Cancelled(:final reason, :final cancelledBy, :final at) => OrderStatusDto(
      kind: OrderStatusDto.cancelled,
      by: cancelledBy.value,
      at: at,
      reason: reason,
    ),
  };
}

extension OrderStatusDtoMapping on OrderStatusDto {
  OrderStatus toDomain() => switch (this) {
    OrderStatusDto(kind: OrderStatusDto.pending) => const Pending(),
    OrderStatusDto(kind: OrderStatusDto.confirmed, :final by?, :final at?) => Confirmed(
      confirmedBy: UserId(by),
      at: at,
    ),
    OrderStatusDto(kind: OrderStatusDto.inProgress, :final by?, :final at?) => InProgress(
      receivedBy: UserId(by),
      at: at,
    ),
    OrderStatusDto(kind: OrderStatusDto.readyForPickup, :final at?) => ReadyForPickup(at: at),
    OrderStatusDto(kind: OrderStatusDto.completed, :final at?) => Completed(at: at),
    OrderStatusDto(kind: OrderStatusDto.rejected, :final by?, :final at?, :final reason) => Rejected(
      reason: reason ?? '',
      rejectedBy: UserId(by),
      at: at,
    ),
    OrderStatusDto(kind: OrderStatusDto.cancelled, :final by?, :final at?, :final reason) => Cancelled(
      reason: reason ?? '',
      cancelledBy: UserId(by),
      at: at,
    ),
    _ => throw FormatException('Unknown order status', kind),
  };
}

extension ServiceOrderMapping on ServiceOrder {
  OrderDto toDto() => OrderDto(
    id: id.value,
    ownerId: ownerId.value,
    petId: petId.value,
    service: service.toDto(),
    period: PeriodDto(start: period.start, end: period.end),
    status: status.toDto(),
    createdAt: createdAt,
    note: note?.text,
    kennelId: kennelId?.value,
    assigneeId: assigneeId?.value,
  );
}

extension OrderDtoMapping on OrderDto {
  ServiceOrder toDomain() => ServiceOrder(
    id: OrderId(id),
    ownerId: UserId(ownerId),
    petId: PetId(petId),
    service: serviceTypeFromDto(service),
    period: ServicePeriod.existing(start: period.start, end: period.end),
    status: status.toDomain(),
    createdAt: createdAt,
    note: note == null ? null : _accepted(OrderNote.parse(note!)),
    kennelId: kennelId == null ? null : KennelId(kennelId!),
    assigneeId: assigneeId == null ? null : UserId(assigneeId!),
  );
}

/// The client sends what the owner chose; the server computes the period and the note again through the domain.
extension OrderRequestMapping on OrderRequest {
  NewOrderDto toDto() => NewOrderDto(
    petId: pet.id.value,
    service: service.toDto(),
    start: period.start,
    nights: service == ServiceType.boarding ? _nights(period) : null,
    note: note?.text,
  );
}

/// Nights between drop-off and pick-up, counted in center days so a daylight saving change does not shorten a stay.
int _nights(ServicePeriod period) {
  final start = centerTime(period.start);
  final end = centerTime(period.end);
  return DateTime.utc(end.year, end.month, end.day).difference(DateTime.utc(start.year, start.month, start.day)).inDays;
}

T _accepted<T>(Result<T> result) => switch (result) {
  Success(:final value) => value,
  Failure(:final error) => throw FormatException('The contract carried a value the domain rejects', error),
};
