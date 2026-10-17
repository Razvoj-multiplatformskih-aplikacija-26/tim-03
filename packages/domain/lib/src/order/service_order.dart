import 'package:meta/meta.dart';

import '../identifiers.dart';
import 'order_note.dart';
import 'order_status.dart';
import 'service_period.dart';
import 'service_type.dart';

/// An owner's order for one service for one pet, the main concept of the system.
@immutable
final class ServiceOrder {
  const ServiceOrder({
    required this.id,
    required this.ownerId,
    required this.petId,
    required this.service,
    required this.period,
    required this.createdAt,
    this.note,
    this.kennelId,
    this.assigneeId,
    this.status = const Pending(),
  });

  final OrderId id;
  final UserId ownerId;
  final PetId petId;
  final ServiceType service;
  final ServicePeriod period;
  final OrderNote? note;

  /// Set on confirmation for boarding.
  final KennelId? kennelId;

  /// Set on confirmation for every service except boarding.
  final UserId? assigneeId;
  final OrderStatus status;
  final DateTime createdAt;

  bool get isActive => status.isActive;

  ServiceOrder copyWith({OrderStatus? status, KennelId? kennelId, UserId? assigneeId}) {
    return ServiceOrder(
      id: id,
      ownerId: ownerId,
      petId: petId,
      service: service,
      period: period,
      createdAt: createdAt,
      note: note,
      kennelId: kennelId ?? this.kennelId,
      assigneeId: assigneeId ?? this.assigneeId,
      status: status ?? this.status,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ServiceOrder &&
      other.id == id &&
      other.ownerId == ownerId &&
      other.petId == petId &&
      other.service == service &&
      other.period == period &&
      other.note == note &&
      other.kennelId == kennelId &&
      other.assigneeId == assigneeId &&
      other.status == status &&
      other.createdAt == createdAt;

  @override
  int get hashCode => Object.hash(id, ownerId, petId, service, period, note, kennelId, assigneeId, status, createdAt);

  @override
  String toString() => 'ServiceOrder($id, ${service.name}, ${period.start.toIso8601String()}, $status)';
}
