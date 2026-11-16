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
