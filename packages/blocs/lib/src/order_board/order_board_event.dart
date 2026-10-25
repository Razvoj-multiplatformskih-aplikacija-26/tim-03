part of 'order_board_bloc.dart';

sealed class OrderBoardEvent {
  const OrderBoardEvent();
}

/// The first load, and "Pokušaj ponovo": the screen shows loading while it waits.
final class OrderBoardRequested extends OrderBoardEvent {
  const OrderBoardRequested();
}

/// A click on an order; null closes the side panel.
final class OrderBoardOrderSelected extends OrderBoardEvent {
  const OrderBoardOrderSelected(this.id);

  final OrderId? id;
}

/// The arrow keys: one order down is 1, one order up is -1.
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

/// The screen has shown the notice, so it is not shown again.
final class OrderBoardNoticeAcknowledged extends OrderBoardEvent {
  const OrderBoardNoticeAcknowledged();
}
