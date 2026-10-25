import 'package:domain/domain.dart';

import 'clock.dart';
import 'ports/board_repository.dart';
import 'ports/order_repository.dart';

final class ConfirmOrder {
  const ConfirmOrder({required this.orders, required this.boards, required this.clock});

  final OrderRepository orders;
  final BoardRepository boards;
  final Clock clock;

  /// Lets the domain decide over every order of the center (roles, R5, then R7 or R8) and saves the confirmed order
  /// with the kennel or the member of staff it got. From KT2 the server makes the final decision.
  Future<Result<ServiceOrder>> call({required OrderId id, required User by}) async {
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
      Success(:final value) => Success(await orders.save(value)),
    };
  }
}
