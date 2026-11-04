part of 'my_orders_bloc.dart';

sealed class MyOrdersEvent {
  const MyOrdersEvent();
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
