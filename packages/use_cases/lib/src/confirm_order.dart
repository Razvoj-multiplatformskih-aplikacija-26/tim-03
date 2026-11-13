import 'package:domain/domain.dart';

import 'change_status.dart';
import 'clock.dart';
import 'ports/board_repository.dart';
import 'ports/order_repository.dart';

final class ConfirmOrder {
  const ConfirmOrder({required this.orders, required this.boards, required this.clock});

  final OrderRepository orders;
  final BoardRepository boards;
  final Clock clock;

  /// The board is read again on every attempt, so the kennel and the staff member are chosen from fresh data.
  Future<Result<ServiceOrder>> call({required OrderId id, required User by}) => changeStatus(
    orders,
    id,
    by: by,
    change: (order) async {
      final board = await boards.board();
      final pet = board.petOf(order);
      if (pet == null) return const Failure(NotFound());
      return confirmOrder(
        order,
        by: by,
        now: clock.now(),
        pet: pet,
        orders: board.orders,
        kennels: board.kennels,
        staff: board.staff,
      );
    },
  );
}
