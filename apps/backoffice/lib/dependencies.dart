import 'package:domain/domain.dart';
import 'package:use_cases/use_cases.dart';

import 'data/fake_center.dart';
import 'data/seed.dart';

final class BackofficeDependencies {
  BackofficeDependencies({
    required this.clock,
    required this.staff,
    required OrderRepository orders,
    required BoardRepository boards,
  }) : getCenterBoard = GetCenterBoard(boards: boards),
       confirmOrder = ConfirmOrder(orders: orders, boards: boards, clock: clock),
       rejectOrder = RejectOrder(orders: orders, clock: clock);

  factory BackofficeDependencies.fake({Clock clock = const SystemClock(), Duration? latency}) {
    final center = latency == null ? FakeCenter(clock: clock) : FakeCenter(clock: clock, latency: latency);
    return BackofficeDependencies(clock: clock, staff: currentStaff, orders: center, boards: center);
  }

  final Clock clock;

  final User staff;

  final GetCenterBoard getCenterBoard;
  final ConfirmOrder confirmOrder;
  final RejectOrder rejectOrder;
}
