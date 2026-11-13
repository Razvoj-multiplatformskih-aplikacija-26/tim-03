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

final class MyOrdersFailure extends MyOrdersState {
  const MyOrdersFailure(this.cause);

  final Object cause;

  @override
  List<Object?> get props => [cause];

  @override
  String toString() => 'MyOrdersFailure($cause)';
}

final class MyOrdersEmpty extends MyOrdersState {
  const MyOrdersEmpty(this.pets);

  final List<Pet> pets;

  @override
  List<Object?> get props => [pets];
}

final class MyOrdersLoaded extends MyOrdersState {
  const MyOrdersLoaded({
    required this.orders,
    required this.pets,
    required this.now,
    required this.cancellable,
    required this.tooLateToCancel,
    this.petFilter,
    this.cancellingId,
    this.notice,
  });

  final List<ServiceOrder> orders;

  final List<Pet> pets;

  final DateTime now;

  final Set<OrderId> cancellable;

  final Set<OrderId> tooLateToCancel;

  final PetId? petFilter;

  final OrderId? cancellingId;

  final MyOrdersNotice? notice;

  @override
  List<Object?> get props => [orders, pets, now, cancellable, tooLateToCancel, petFilter, cancellingId, notice];

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

  List<ServiceOrder> get current => [
    for (final order in _shown)
      if (order.isActive) order,
  ];

  List<ServiceOrder> get history => [
    for (final order in _shown)
      if (!order.isActive) order,
  ]..sort((a, b) => _closedAt(b).compareTo(_closedAt(a)));

  ServiceOrder? byId(OrderId id) => orders.where((order) => order.id == id).firstOrNull;

  Pet? petById(PetId id) => pets.where((pet) => pet.id == id).firstOrNull;

  Pet? petOf(ServiceOrder order) => petById(order.petId);

  bool canCancel(ServiceOrder order) => cancellable.contains(order.id);

  bool isTooLateToCancel(ServiceOrder order) => tooLateToCancel.contains(order.id);

  bool get isBusy => cancellingId != null;

  bool isCancelling(ServiceOrder order) => cancellingId == order.id;

  MyOrdersLoaded withPetFilter(PetId? petFilter) => MyOrdersLoaded(
    orders: orders,
    pets: pets,
    now: now,
    cancellable: cancellable,
    tooLateToCancel: tooLateToCancel,
    petFilter: petFilter,
    cancellingId: cancellingId,
  );

  MyOrdersLoaded withCancelling(OrderId id) => MyOrdersLoaded(
    orders: orders,
    pets: pets,
    now: now,
    cancellable: cancellable,
    tooLateToCancel: tooLateToCancel,
    petFilter: petFilter,
    cancellingId: id,
  );

  MyOrdersLoaded withNotice(MyOrdersNotice? notice) => MyOrdersLoaded(
    orders: orders,
    pets: pets,
    now: now,
    cancellable: cancellable,
    tooLateToCancel: tooLateToCancel,
    petFilter: petFilter,
    notice: notice,
  );
}

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

final class CancellationRejected extends MyOrdersNotice {
  const CancellationRejected(this.error);

  final DomainError error;

  @override
  List<Object?> get props => [error];
}

final class CancellationFailed extends MyOrdersNotice {
  const CancellationFailed(this.cause);

  final Object cause;

  @override
  List<Object?> get props => [cause];
}
