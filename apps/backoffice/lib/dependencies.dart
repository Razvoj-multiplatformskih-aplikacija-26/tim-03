import 'package:domain/domain.dart';
import 'package:use_cases/use_cases.dart';

import 'data/fake_center.dart';
import 'data/seed.dart';

/// Everything the bloc gets from outside, made in one place at start-up. The screens never learn which
/// implementation of the ports they got, so swapping it changes only this file.
final class BackofficeDependencies {
  BackofficeDependencies({
    required this.clock,
    required this.staff,
    required OrderRepository orders,
    required BoardRepository boards,
  }) : getCenterBoard = GetCenterBoard(boards: boards),
       confirmOrder = ConfirmOrder(orders: orders, boards: boards, clock: clock),
       rejectOrder = RejectOrder(orders: orders, clock: clock);

  /// Every order of the center in memory, with a delay. From KT2 a second constructor brings the HTTP adapter.
  factory BackofficeDependencies.fake({Clock clock = const SystemClock(), Duration? latency}) {
    final center = latency == null ? FakeCenter(clock: clock) : FakeCenter(clock: clock, latency: latency);
    return BackofficeDependencies(clock: clock, staff: currentStaff, orders: center, boards: center);
  }

  final Clock clock;

  /// The one signed-in member of staff; signing in arrives with the server in KT2.
  final User staff;

  final GetCenterBoard getCenterBoard;
  final ConfirmOrder confirmOrder;
  final RejectOrder rejectOrder;
}
