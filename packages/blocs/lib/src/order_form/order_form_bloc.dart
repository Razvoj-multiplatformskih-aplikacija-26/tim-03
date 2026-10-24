import 'package:bloc/bloc.dart';
import 'package:domain/domain.dart';
import 'package:equatable/equatable.dart';
import 'package:use_cases/use_cases.dart';

part 'order_form_event.dart';
part 'order_form_state.dart';

/// Sends a new order. The form checks every field with the domain while the owner types; this bloc only sends what
/// passed and says how it went.
final class OrderFormBloc extends Bloc<OrderFormEvent, OrderFormState> {
  OrderFormBloc({required this.placeOrder, required this.owner}) : super(const OrderFormEditing()) {
    on<OrderFormSubmitted>(_onSubmitted);
  }

  final PlaceOrder placeOrder;
  final User owner;

  Future<void> _onSubmitted(OrderFormSubmitted event, Emitter<OrderFormState> emit) async {
    if (state is OrderFormSubmitting || state is OrderFormSucceeded) return;
    emit(const OrderFormSubmitting());
    final request = OrderRequest(
      owner: owner,
      pet: event.pet,
      service: event.service,
      period: event.period,
      note: event.note,
    );
    try {
      emit(switch (await placeOrder(request)) {
        Success(:final value) => OrderFormSucceeded(value),
        Failure(:final error) => OrderFormRejected(error),
      });
    } on RepositoryException catch (cause) {
      emit(OrderFormFailed(cause));
    }
  }
}
