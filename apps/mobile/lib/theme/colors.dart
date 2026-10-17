import 'package:flutter/material.dart';

abstract final class SapaColorSchemes {
  static const seed = Color(0xFF2A7F74);

  static final light = ColorScheme.fromSeed(seedColor: seed, tertiary: const Color(0xFFB8621B));

  static final dark = ColorScheme.fromSeed(
    seedColor: seed,
    brightness: Brightness.dark,
    tertiary: const Color(0xFFF4A261),
  );
}

/// Background and text color of one status badge.
@immutable
class StatusTone {
  const StatusTone(this.background, this.foreground);

  final Color background;
  final Color foreground;

  static StatusTone lerp(StatusTone a, StatusTone b, double t) =>
      StatusTone(Color.lerp(a.background, b.background, t)!, Color.lerp(a.foreground, b.foreground, t)!);
}

@immutable
class OrderStatusColors extends ThemeExtension<OrderStatusColors> {
  const OrderStatusColors({
    required this.pending,
    required this.confirmed,
    required this.inProgress,
    required this.readyForPickup,
    required this.completed,
    required this.rejected,
    required this.cancelled,
  });

  final StatusTone pending;
  final StatusTone confirmed;
  final StatusTone inProgress;
  final StatusTone readyForPickup;
  final StatusTone completed;
  final StatusTone rejected;
  final StatusTone cancelled;

  static const light = OrderStatusColors(
    pending: StatusTone(Color(0xFFFBE7C6), Color(0xFF7A4E00)),
    confirmed: StatusTone(Color(0xFFD4EDDA), Color(0xFF1E6B3A)),
    inProgress: StatusTone(Color(0xFFD3E5F5), Color(0xFF1F5A8C)),
    readyForPickup: StatusTone(Color(0xFFE6DDF5), Color(0xFF5B3C99)),
    completed: StatusTone(Color(0xFFE3E6E8), Color(0xFF45505A)),
    rejected: StatusTone(Color(0xFFF6D6D3), Color(0xFF9A2A1F)),
    cancelled: StatusTone(Color(0xFFEFE0DC), Color(0xFF7D4A3E)),
  );

  static const dark = OrderStatusColors(
    pending: StatusTone(Color(0xFF4D3A12), Color(0xFFF5CF87)),
    confirmed: StatusTone(Color(0xFF1E4A2D), Color(0xFF9FDDB3)),
    inProgress: StatusTone(Color(0xFF1D3F5E), Color(0xFFA6CDF0)),
    readyForPickup: StatusTone(Color(0xFF3D2D63), Color(0xFFCDB8F2)),
    completed: StatusTone(Color(0xFF353B40), Color(0xFFC5CCD2)),
    rejected: StatusTone(Color(0xFF5A2420), Color(0xFFF2B4AC)),
    cancelled: StatusTone(Color(0xFF4A332D), Color(0xFFE3BFB5)),
  );

  @override
  OrderStatusColors copyWith({
    StatusTone? pending,
    StatusTone? confirmed,
    StatusTone? inProgress,
    StatusTone? readyForPickup,
    StatusTone? completed,
    StatusTone? rejected,
    StatusTone? cancelled,
  }) {
    return OrderStatusColors(
      pending: pending ?? this.pending,
      confirmed: confirmed ?? this.confirmed,
      inProgress: inProgress ?? this.inProgress,
      readyForPickup: readyForPickup ?? this.readyForPickup,
      completed: completed ?? this.completed,
      rejected: rejected ?? this.rejected,
      cancelled: cancelled ?? this.cancelled,
    );
  }

  @override
  OrderStatusColors lerp(OrderStatusColors? other, double t) {
    if (other == null) return this;
    return OrderStatusColors(
      pending: StatusTone.lerp(pending, other.pending, t),
      confirmed: StatusTone.lerp(confirmed, other.confirmed, t),
      inProgress: StatusTone.lerp(inProgress, other.inProgress, t),
      readyForPickup: StatusTone.lerp(readyForPickup, other.readyForPickup, t),
      completed: StatusTone.lerp(completed, other.completed, t),
      rejected: StatusTone.lerp(rejected, other.rejected, t),
      cancelled: StatusTone.lerp(cancelled, other.cancelled, t),
    );
  }
}

extension OrderStatusColorsX on ThemeData {
  OrderStatusColors get statusColors => extension<OrderStatusColors>() ?? OrderStatusColors.light;
}
