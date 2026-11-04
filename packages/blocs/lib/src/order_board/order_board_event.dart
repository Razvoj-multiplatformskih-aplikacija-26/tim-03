part of 'order_board_bloc.dart';

sealed class OrderBoardEvent {
  const OrderBoardEvent();
}

final class OrderBoardRequested extends OrderBoardEvent {
  const OrderBoardRequested();
}

final class OrderBoardOrderSelected extends OrderBoardEvent {
  const OrderBoardOrderSelected(this.id);

  final OrderId? id;
}

final class OrderBoardSelectionMoved extends OrderBoardEvent {
  const OrderBoardSelectionMoved(this.steps);

  final int steps;
}

final class OrderConfirmationRequested extends OrderBoardEvent {
  const OrderConfirmationRequested(this.id);

  final OrderId id;
}

final class OrderRejectionRequested extends OrderBoardEvent {
  const OrderRejectionRequested(this.id, {this.reason = ''});

  final OrderId id;
  final String reason;
}

final class OrderBoardNoticeAcknowledged extends OrderBoardEvent {
  const OrderBoardNoticeAcknowledged();
}
