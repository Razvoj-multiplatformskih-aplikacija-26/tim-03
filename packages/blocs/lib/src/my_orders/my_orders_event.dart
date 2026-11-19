part of 'my_orders_bloc.dart';

sealed class MyOrdersEvent {
  const MyOrdersEvent();
}

/// The signed-in owner from the session; null after signing out.
final class MyOrdersOwnerChanged extends MyOrdersEvent {
  const MyOrdersOwnerChanged(this.owner);

  final User? owner;
}

final class MyOrdersRequested extends MyOrdersEvent {
  const MyOrdersRequested();
}

final class MyOrdersRefreshed extends MyOrdersEvent {
  const MyOrdersRefreshed();
}

final class MyOrdersPetFilterChanged extends MyOrdersEvent {
  const MyOrdersPetFilterChanged(this.petId);

  final PetId? petId;
}

final class OrderCancellationRequested extends MyOrdersEvent {
  const OrderCancellationRequested(this.id, {this.reason = ''});

  final OrderId id;
  final String reason;
}

final class MyOrdersNoticeAcknowledged extends MyOrdersEvent {
  const MyOrdersNoticeAcknowledged();
}
