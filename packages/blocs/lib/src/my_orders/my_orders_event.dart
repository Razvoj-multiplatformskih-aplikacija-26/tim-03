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

/// Reloads without a spinner in place of the list; [handled] completes when the new data is shown, so
/// pull to refresh knows when to stop.
final class MyOrdersRefreshed extends MyOrdersEvent {
  MyOrdersRefreshed();

  final _handled = Completer<void>();

  Future<void> get handled => _handled.future;
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
