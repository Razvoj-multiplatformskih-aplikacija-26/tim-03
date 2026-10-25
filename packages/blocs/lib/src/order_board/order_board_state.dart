part of 'order_board_bloc.dart';

enum StaffAction { confirm, reject }

sealed class OrderBoardState extends Equatable {
  const OrderBoardState();

  @override
  List<Object?> get props => const [];

  @override
  String toString() => '$runtimeType';
}

final class OrderBoardLoading extends OrderBoardState {
  const OrderBoardLoading();
}

/// The orders could not be loaded; the screen offers "Pokušaj ponovo".
final class OrderBoardFailure extends OrderBoardState {
  const OrderBoardFailure(this.cause);

  final Object cause;

  @override
  List<Object?> get props => [cause];

  @override
  String toString() => 'OrderBoardFailure($cause)';
}

final class OrderBoardLoaded extends OrderBoardState {
  const OrderBoardLoaded({required this.board, this.actions = const {}, this.selectedId, this.inFlightId, this.notice});

  final CenterBoard board;

  /// What the domain lets the signed-in member of staff do with each order.
  final Map<OrderId, Set<StaffAction>> actions;

  /// The order in the side panel. It lives here, not in a widget, so a narrower window keeps it.
  final OrderId? selectedId;

  /// The order whose action is in flight.
  final OrderId? inFlightId;

  /// Something the screen shows once, then acknowledges.
  final OrderBoardNotice? notice;

  @override
  List<Object?> get props => [board, actions, selectedId, inFlightId, notice];

  @override
  String toString() => [
    'OrderBoardLoaded(${board.orders.length} orders',
    if (selectedId case final id?) ', selected ${id.value}',
    if (inFlightId case final id?) ', in flight ${id.value}',
    if (notice case final notice?) ', ${notice.runtimeType}',
    ')',
  ].join();

  /// Every order of the center, earliest start first: the rows of the table and the steps of the arrow keys.
  List<ServiceOrder> get rows => [...board.orders]..sort((a, b) => a.period.start.compareTo(b.period.start));

  ServiceOrder? get selected => switch (selectedId) {
    final id? => board.orderById(id),
    null => null,
  };

  bool get isEmpty => board.orders.isEmpty;

  bool get isBusy => inFlightId != null;

  Set<StaffAction> actionsFor(ServiceOrder order) => actions[order.id] ?? const {};

  /// Every copy ends the action in flight unless it names one.
  OrderBoardLoaded copyWith({
    OrderId? selectedId,
    bool clearSelection = false,
    OrderId? inFlightId,
    OrderBoardNotice? notice,
    bool clearNotice = false,
  }) => OrderBoardLoaded(
    board: board,
    actions: actions,
    selectedId: clearSelection ? null : (selectedId ?? this.selectedId),
    inFlightId: inFlightId,
    notice: clearNotice ? null : (notice ?? this.notice),
  );
}

sealed class OrderBoardNotice extends Equatable {
  const OrderBoardNotice();

  @override
  List<Object?> get props => const [];
}

final class StaffActionSucceeded extends OrderBoardNotice {
  const StaffActionSucceeded(this.order);

  final ServiceOrder order;

  @override
  List<Object?> get props => [order];
}

/// The domain said no, for example because no kennel is free (R7).
final class StaffActionRejected extends OrderBoardNotice {
  const StaffActionRejected(this.error);

  final DomainError error;

  @override
  List<Object?> get props => [error];
}

/// The repository could not be reached.
final class StaffActionFailed extends OrderBoardNotice {
  const StaffActionFailed(this.cause);

  final Object cause;

  @override
  List<Object?> get props => [cause];
}
