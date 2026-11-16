import 'json.dart';

final class OrderStatusDto {
  const OrderStatusDto({required this.kind, this.by, this.at, this.reason});

  static const pending = 'pending';
  static const confirmed = 'confirmed';
  static const inProgress = 'in-progress';
  static const readyForPickup = 'ready-for-pickup';
  static const completed = 'completed';
  static const rejected = 'rejected';
  static const cancelled = 'cancelled';

  final String kind;
  final String? by;
  final DateTime? at;
  final String? reason;

  Map<String, Object?> toJson() => {
    'kind': kind,
    'by': ?by,
    if (at case final at?) 'at': instantToJson(at),
    'reason': ?reason,
  };

  factory OrderStatusDto.fromJson(Map<String, Object?> json) => OrderStatusDto(
    kind: jsonString(json, 'kind'),
    by: jsonOptionalString(json, 'by'),
    at: jsonOptionalInstant(json, 'at'),
    reason: jsonOptionalString(json, 'reason'),
  );
}

final class PeriodDto {
  const PeriodDto({required this.start, required this.end});

  final DateTime start;
  final DateTime end;

  Map<String, Object?> toJson() => {'start': instantToJson(start), 'end': instantToJson(end)};

  factory PeriodDto.fromJson(Map<String, Object?> json) =>
      PeriodDto(start: jsonInstant(json, 'start'), end: jsonInstant(json, 'end'));
}

final class OrderDto {
  const OrderDto({
    required this.id,
    required this.ownerId,
    required this.petId,
    required this.service,
    required this.period,
    required this.status,
    required this.createdAt,
    this.note,
    this.kennelId,
    this.assigneeId,
  });

  final String id;
  final String ownerId;
  final String petId;
  final String service;
  final PeriodDto period;
  final OrderStatusDto status;
  final DateTime createdAt;
  final String? note;
  final String? kennelId;
  final String? assigneeId;

  Map<String, Object?> toJson() => {
    'id': id,
    'ownerId': ownerId,
    'petId': petId,
    'service': service,
    'period': period.toJson(),
    'status': status.toJson(),
    'createdAt': instantToJson(createdAt),
    'note': ?note,
    'kennelId': ?kennelId,
    'assigneeId': ?assigneeId,
  };

  factory OrderDto.fromJson(Map<String, Object?> json) => OrderDto(
    id: jsonString(json, 'id'),
    ownerId: jsonString(json, 'ownerId'),
    petId: jsonString(json, 'petId'),
    service: jsonString(json, 'service'),
    period: PeriodDto.fromJson(jsonObject(json['period'])),
    status: OrderStatusDto.fromJson(jsonObject(json['status'])),
    createdAt: jsonInstant(json, 'createdAt'),
    note: jsonOptionalString(json, 'note'),
    kennelId: jsonOptionalString(json, 'kennelId'),
    assigneeId: jsonOptionalString(json, 'assigneeId'),
  );
}

final class NewOrderDto {
  const NewOrderDto({required this.petId, required this.service, required this.start, this.nights, this.note});

  final String petId;
  final String service;
  final DateTime start;
  final int? nights;
  final String? note;

  Map<String, Object?> toJson() => {
    'petId': petId,
    'service': service,
    'start': instantToJson(start),
    'nights': ?nights,
    'note': ?note,
  };

  factory NewOrderDto.fromJson(Map<String, Object?> json) => NewOrderDto(
    petId: jsonString(json, 'petId'),
    service: jsonString(json, 'service'),
    start: jsonInstant(json, 'start'),
    nights: jsonOptionalInt(json, 'nights'),
    note: jsonOptionalString(json, 'note'),
  );
}

final class ReasonDto {
  const ReasonDto({required this.reason});

  final String reason;

  Map<String, Object?> toJson() => {'reason': reason};

  factory ReasonDto.fromJson(Map<String, Object?> json) => ReasonDto(reason: jsonString(json, 'reason'));
}
