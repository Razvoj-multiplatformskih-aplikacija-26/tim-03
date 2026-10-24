import 'package:bloc/bloc.dart';
import 'package:domain/domain.dart';
import 'package:domain/domain.dart' as domain show cancelOrder;
import 'package:equatable/equatable.dart';
import 'package:use_cases/use_cases.dart';

part 'my_orders_event.dart';
part 'my_orders_state.dart';

/// The owner's main flow: load the orders, filter them by pet, cancel one. The rules stay in the domain; the bloc
/// only puts the steps in order and says what the screen should draw.
final class MyOrdersBloc extends Bloc<MyOrdersEvent, MyOrdersState> {
  MyOrdersBloc({required this.getMyOrders, required this.cancelOrder, required this.clock, required this.owner})
    : super(const MyOrdersLoading()) {
    on<MyOrdersRequested>((event, emit) async {
      emit(const MyOrdersLoading());
      await _reload(emit);
    });
    on<MyOrdersRefreshed>((event, emit) => _reload(emit, petFilter: _petFilter));
    on<MyOrdersPetFilterChanged>((event, emit) {
      final current = state;
      if (current is MyOrdersLoaded) emit(current.withPetFilter(event.petId));
    });
    on<OrderCancellationRequested>(_onCancellationRequested);
    on<MyOrdersNoticeAcknowledged>((event, emit) {
      final current = state;
      if (current is MyOrdersLoaded && current.notice != null) emit(current.withNotice(null));
    });
  }

  final GetMyOrders getMyOrders;
  final CancelOrder cancelOrder;
  final Clock clock;
  final User owner;

  PetId? get _petFilter => switch (state) {
    MyOrdersLoaded(:final petFilter) => petFilter,
    MyOrdersLoading() || MyOrdersFailure() || MyOrdersEmpty() => null,
  };

  Future<void> _onCancellationRequested(OrderCancellationRequested event, Emitter<MyOrdersState> emit) async {
    final current = state;
    if (current is! MyOrdersLoaded || current.isBusy) return;
    emit(current.withCancelling(event.id));
    final Result<ServiceOrder> result;
    try {
      result = await cancelOrder(id: event.id, by: owner, reason: event.reason);
    } on RepositoryException catch (cause) {
      emit(current.withNotice(CancellationFailed(cause)));
      return;
    }
    switch (result) {
      case Success(:final value):
        await _reload(emit, petFilter: current.petFilter, notice: OrderCancelled(value));
      case Failure(:final error):
        emit(current.withNotice(CancellationRejected(error)));
    }
  }

  Future<void> _reload(Emitter<MyOrdersState> emit, {PetId? petFilter, MyOrdersNotice? notice}) async {
    final List<ServiceOrder> orders;
    try {
      orders = await getMyOrders(owner);
    } on RepositoryException catch (cause) {
      emit(MyOrdersFailure(cause));
      return;
    }
    if (orders.isEmpty) {
      emit(const MyOrdersEmpty());
      return;
    }
    final now = clock.now();
    final cancellable = <OrderId>{};
    final tooLateToCancel = <OrderId>{};
    for (final order in orders) {
      // The domain's own cancelOrder answers, without saving anything, whether the button may be shown.
      final check = domain.cancelOrder(order, by: owner, now: now);
      if (check.isSuccess) cancellable.add(order.id);
      if (check.errorOrNull is CancellationTooLate) tooLateToCancel.add(order.id);
    }
    emit(
      MyOrdersLoaded(
        orders: orders,
        now: now,
        cancellable: cancellable,
        tooLateToCancel: tooLateToCancel,
        petFilter: petFilter,
        notice: notice,
      ),
    );
  }
}
