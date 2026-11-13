import 'package:domain/domain.dart';

import 'clock.dart';
import 'ports/board_repository.dart';
import 'ports/order_repository.dart';
import 'retry_on_change.dart';

final class ConfirmOrder {
  const ConfirmOrder({required this.orders, required this.boards, required this.clock});

  final OrderRepository orders;
  final BoardRepository boards;
  final Clock clock;

  /// The board is read again on every attempt, so a kennel or a staff member taken in the meantime is chosen again.
  Future<Result<ServiceOrder>> call({required OrderId id, required User by}) => retryOnChange(() async {
    final board = await boards.board();
    final order = board.orderById(id);
    final pet = order == null ? null : board.petOf(order);
    if (order == null || pet == null) return const Failure(NotFound());
    final result = confirmOrder(
      order,
      by: by,
      now: clock.now(),
      pet: pet,
      orders: board.orders,
      kennels: board.kennels,
      staff: board.staff,
    );
    return switch (result) {
      Failure(:final error) => Failure(error),
      Success(:final value) => await orders.save(value, from: order.status),
    };
  });
}
