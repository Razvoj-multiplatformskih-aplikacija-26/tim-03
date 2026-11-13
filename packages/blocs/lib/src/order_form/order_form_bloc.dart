import 'package:bloc/bloc.dart';
import 'package:domain/domain.dart';
import 'package:equatable/equatable.dart';
import 'package:use_cases/use_cases.dart';

part 'order_form_event.dart';
part 'order_form_state.dart';

final class OrderFormBloc extends Bloc<OrderFormEvent, OrderFormState> {
  OrderFormBloc({required this.placeOrder, required this.getMyPets, required this.getOpeningHours, required this.owner})
    : super(const OrderFormLoading()) {
    on<OrderFormStarted>(_onStarted);
    on<OrderFormSubmitted>(_onSubmitted);
  }

  final PlaceOrder placeOrder;
  final GetMyPets getMyPets;
  final GetOpeningHours getOpeningHours;
  final User owner;

  Future<void> _onStarted(OrderFormStarted event, Emitter<OrderFormState> emit) async {
    emit(const OrderFormLoading());
    try {
      final pets = await getMyPets(owner);
      final openingHours = await getOpeningHours();
      emit(OrderFormEditing(pets: pets, openingHours: openingHours));
    } on RepositoryException catch (cause) {
      emit(OrderFormUnavailable(cause));
    }
  }

  Future<void> _onSubmitted(OrderFormSubmitted event, Emitter<OrderFormState> emit) async {
    final current = state;
    if (current is! OrderFormReady || current is OrderFormSubmitting || current is OrderFormSucceeded) return;
    final OrderFormReady(:pets, :openingHours) = current;
    emit(OrderFormSubmitting(pets: pets, openingHours: openingHours));
    final request = OrderRequest(
      owner: owner,
      pet: event.pet,
      service: event.service,
      period: event.period,
      note: event.note,
    );
    try {
      emit(switch (await placeOrder(request)) {
        Success(:final value) => OrderFormSucceeded(value, pets: pets, openingHours: openingHours),
        Failure(:final error) => OrderFormRejected(error, pets: pets, openingHours: openingHours),
      });
    } on RepositoryException catch (cause) {
      emit(OrderFormFailed(cause, pets: pets, openingHours: openingHours));
    }
  }
}
