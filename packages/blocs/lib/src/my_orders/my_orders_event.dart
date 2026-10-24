part of 'my_orders_bloc.dart';

sealed class MyOrdersEvent {
  const MyOrdersEvent();
}

/// The first load, and "Pokušaj ponovo": the screen shows loading while it waits.
final class MyOrdersRequested extends MyOrdersEvent {
  const MyOrdersRequested();
}

/// Loads again while the list stays on screen, for example after a new order.
final class MyOrdersRefreshed extends MyOrdersEvent {
  const MyOrdersRefreshed();
}

/// Null shows the orders of every pet.
final class MyOrdersPetFilterChanged extends MyOrdersEvent {
  const MyOrdersPetFilterChanged(this.petId);

  final PetId? petId;
}

final class OrderCancellationRequested extends MyOrdersEvent {
  const OrderCancellationRequested(this.id, {this.reason = ''});

  final OrderId id;
  final String reason;
}

/// The screen has shown the notice, so it is not shown again.
final class MyOrdersNoticeAcknowledged extends MyOrdersEvent {
  const MyOrdersNoticeAcknowledged();
}
