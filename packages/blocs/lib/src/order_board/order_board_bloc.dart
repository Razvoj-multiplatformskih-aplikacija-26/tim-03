import 'package:bloc/bloc.dart';
import 'package:domain/domain.dart';
import 'package:domain/domain.dart' as domain show confirmOrder, rejectOrder;
import 'package:equatable/equatable.dart';
import 'package:use_cases/use_cases.dart';

part 'order_board_event.dart';
part 'order_board_state.dart';

/// The staff's main flow: load every order of the center, pick one, confirm or reject it. The rules stay in the
/// domain; the bloc keeps the selection and says what the screen should draw.
final class OrderBoardBloc extends Bloc<OrderBoardEvent, OrderBoardState> {
  OrderBoardBloc({
    required this.getCenterBoard,
    required this.confirmOrder,
    required this.rejectOrder,
    required this.clock,
    required this.staff,
  }) : super(const OrderBoardLoading()) {
    on<OrderBoardRequested>((event, emit) async {
      emit(const OrderBoardLoading());
      await _load(emit);
    });
    on<OrderBoardOrderSelected>((event, emit) {
      final current = state;
      if (current is OrderBoardLoaded) emit(current.copyWith(selectedId: event.id, clearSelection: event.id == null));
    });
    on<OrderBoardSelectionMoved>(_onSelectionMoved);
    on<OrderConfirmationRequested>((event, emit) => _act(emit, event.id, () => confirmOrder(id: event.id, by: staff)));
    on<OrderRejectionRequested>(
      (event, emit) => _act(emit, event.id, () => rejectOrder(id: event.id, by: staff, reason: event.reason)),
    );
    on<OrderBoardNoticeAcknowledged>((event, emit) {
      final current = state;
      if (current is OrderBoardLoaded && current.notice != null) emit(current.copyWith(clearNotice: true));
    });
  }

  final GetCenterBoard getCenterBoard;
  final ConfirmOrder confirmOrder;
  final RejectOrder rejectOrder;
  final Clock clock;

  /// The one signed-in member of staff; signing in arrives with the server in KT2.
  final User staff;

  void _onSelectionMoved(OrderBoardSelectionMoved event, Emitter<OrderBoardState> emit) {
    final current = state;
    if (current is! OrderBoardLoaded || current.isEmpty) return;
    final rows = current.rows;
    final index = rows.indexWhere((order) => order.id == current.selectedId);
    // With nothing selected, down starts at the first order and up at the last.
    final next = index < 0 ? (event.steps > 0 ? 0 : rows.length - 1) : (index + event.steps).clamp(0, rows.length - 1);
    emit(current.copyWith(selectedId: rows[next].id));
  }

  Future<void> _act(Emitter<OrderBoardState> emit, OrderId id, Future<Result<ServiceOrder>> Function() action) async {
    final current = state;
    if (current is! OrderBoardLoaded || current.isBusy) return;
    emit(current.copyWith(inFlightId: id, clearNotice: true));
    final Result<ServiceOrder> result;
    try {
      result = await action();
    } on RepositoryException catch (cause) {
      _finish(emit, StaffActionFailed(cause));
      return;
    }
    switch (result) {
      case Success(:final value):
        await _load(emit, selectedId: _selectedId, notice: StaffActionSucceeded(value));
      case Failure(:final error):
        _finish(emit, StaffActionRejected(error));
    }
  }

  /// The selection as it is now; staff may have moved it while the action was on its way.
  OrderId? get _selectedId => switch (state) {
    OrderBoardLoaded(:final selectedId) => selectedId,
    OrderBoardLoading() || OrderBoardFailure() => null,
  };

  /// Ends the action in flight on the latest state, so a selection made meanwhile stays.
  void _finish(Emitter<OrderBoardState> emit, OrderBoardNotice notice) {
    final latest = state;
    if (latest is OrderBoardLoaded) emit(latest.copyWith(clearInFlight: true, notice: notice));
  }

  Future<void> _load(Emitter<OrderBoardState> emit, {OrderId? selectedId, OrderBoardNotice? notice}) async {
    final CenterBoard board;
    try {
      board = await getCenterBoard();
    } on RepositoryException catch (cause) {
      emit(OrderBoardFailure(cause));
      return;
    }
    emit(OrderBoardLoaded(board: board, actions: _actionsFor(board), selectedId: selectedId, notice: notice));
  }

  /// The domain's own actions answer, without saving anything, which buttons and shortcuts may work.
  Map<OrderId, Set<StaffAction>> _actionsFor(CenterBoard board) {
    final now = clock.now();
    return {
      for (final order in board.orders)
        order.id: {
          if (_mayConfirm(order, board, now)) StaffAction.confirm,
          if (domain.rejectOrder(order, by: staff, now: now).isSuccess) StaffAction.reject,
        },
    };
  }

  /// A confirmation the domain refuses only for lack of room or people (R7, R8) stays on offer, so pressing it shows
  /// why.
  bool _mayConfirm(ServiceOrder order, CenterBoard board, DateTime now) {
    final pet = board.petOf(order);
    if (pet == null) return false;
    final check = domain.confirmOrder(
      order,
      by: staff,
      now: now,
      pet: pet,
      orders: board.orders,
      kennels: board.kennels,
      staff: board.staff,
    );
    return switch (check) {
      Success() => true,
      Failure(error: NoKennelAvailable() || StaffNotAvailable()) => true,
      Failure() => false,
    };
  }
}
