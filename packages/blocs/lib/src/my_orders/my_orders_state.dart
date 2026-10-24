part of 'my_orders_bloc.dart';

sealed class MyOrdersState extends Equatable {
  const MyOrdersState();

  @override
  List<Object?> get props => const [];

  @override
  String toString() => '$runtimeType';
}

final class MyOrdersLoading extends MyOrdersState {
  const MyOrdersLoading();
}

/// The orders could not be loaded; the screen offers "Pokušaj ponovo".
final class MyOrdersFailure extends MyOrdersState {
  const MyOrdersFailure(this.cause);

  final Object cause;

  @override
  List<Object?> get props => [cause];

  @override
  String toString() => 'MyOrdersFailure($cause)';
}

/// The owner has no orders at all.
final class MyOrdersEmpty extends MyOrdersState {
  const MyOrdersEmpty();
}

final class MyOrdersLoaded extends MyOrdersState {
  const MyOrdersLoaded({
    required this.orders,
    required this.now,
    required this.cancellable,
    required this.tooLateToCancel,
    this.petFilter,
    this.cancellingId,
    this.notice,
  });

  /// Every order of the owner, whatever the filter, earliest start first.
  final List<ServiceOrder> orders;

  /// When the orders were loaded; the screen measures "today" and "this week" from it.
  final DateTime now;

  /// Orders the domain lets the owner cancel now.
  final Set<OrderId> cancellable;

  /// Orders the owner could cancel if the deadline had not passed (R4).
  final Set<OrderId> tooLateToCancel;

  /// Only this pet's orders are shown; null shows every pet.
  final PetId? petFilter;

  /// The order whose cancellation is in flight.
  final OrderId? cancellingId;

  /// Something the screen shows once, then acknowledges.
  final MyOrdersNotice? notice;

  @override
  List<Object?> get props => [orders, now, cancellable, tooLateToCancel, petFilter, cancellingId, notice];

  @override
  String toString() => [
    'MyOrdersLoaded(${orders.length} orders',
    if (petFilter case final petId?) ', pet ${petId.value}',
    if (cancellingId case final id?) ', cancelling ${id.value}',
    if (notice case final notice?) ', ${notice.runtimeType}',
    ')',
  ].join();

  Iterable<ServiceOrder> get _shown {
    final petFilter = this.petFilter;
    return petFilter == null ? orders : orders.where((order) => order.petId == petFilter);
  }

  /// Active orders of the shown pets, earliest start first.
  List<ServiceOrder> get current => [
    for (final order in _shown)
      if (order.isActive) order,
  ];

  /// Finished orders of the shown pets, the latest news first.
  List<ServiceOrder> get history => [
    for (final order in _shown)
      if (!order.isActive) order,
  ]..sort((a, b) => _closedAt(b).compareTo(_closedAt(a)));

  ServiceOrder? byId(OrderId id) => orders.where((order) => order.id == id).firstOrNull;

  bool canCancel(ServiceOrder order) => cancellable.contains(order.id);

  bool isTooLateToCancel(ServiceOrder order) => tooLateToCancel.contains(order.id);

  bool get isBusy => cancellingId != null;

  bool isCancelling(ServiceOrder order) => cancellingId == order.id;

  MyOrdersLoaded withPetFilter(PetId? petFilter) => MyOrdersLoaded(
    orders: orders,
    now: now,
    cancellable: cancellable,
    tooLateToCancel: tooLateToCancel,
    petFilter: petFilter,
    cancellingId: cancellingId,
  );

  MyOrdersLoaded withCancelling(OrderId id) => MyOrdersLoaded(
    orders: orders,
    now: now,
    cancellable: cancellable,
    tooLateToCancel: tooLateToCancel,
    petFilter: petFilter,
    cancellingId: id,
  );

  MyOrdersLoaded withNotice(MyOrdersNotice? notice) => MyOrdersLoaded(
    orders: orders,
    now: now,
    cancellable: cancellable,
    tooLateToCancel: tooLateToCancel,
    petFilter: petFilter,
    notice: notice,
  );
}

/// When an order that is over was completed, rejected or cancelled.
DateTime _closedAt(ServiceOrder order) => switch (order.status) {
  Completed(:final at) || Rejected(:final at) || Cancelled(:final at) => at,
  Pending() || Confirmed() || InProgress() || ReadyForPickup() => order.period.end,
};

sealed class MyOrdersNotice extends Equatable {
  const MyOrdersNotice();

  @override
  List<Object?> get props => const [];
}

final class OrderCancelled extends MyOrdersNotice {
  const OrderCancelled(this.order);

  final ServiceOrder order;

  @override
  List<Object?> get props => [order];
}

/// The domain said no, for example because the deadline has passed.
final class CancellationRejected extends MyOrdersNotice {
  const CancellationRejected(this.error);

  final DomainError error;

  @override
  List<Object?> get props => [error];
}

/// The repository could not be reached.
final class CancellationFailed extends MyOrdersNotice {
  const CancellationFailed(this.cause);

  final Object cause;

  @override
  List<Object?> get props => [cause];
}
