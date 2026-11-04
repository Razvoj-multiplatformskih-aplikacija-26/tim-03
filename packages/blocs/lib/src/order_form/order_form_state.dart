part of 'order_form_bloc.dart';

sealed class OrderFormState extends Equatable {
  const OrderFormState();

  @override
  List<Object?> get props => const [];

  @override
  String toString() => '$runtimeType';
}

final class OrderFormEditing extends OrderFormState {
  const OrderFormEditing();
}

final class OrderFormSubmitting extends OrderFormState {
  const OrderFormSubmitting();
}

final class OrderFormSucceeded extends OrderFormState {
  const OrderFormSucceeded(this.order);

  final ServiceOrder order;

  @override
  List<Object?> get props => [order];
}

final class OrderFormRejected extends OrderFormState {
  const OrderFormRejected(this.error);

  final DomainError error;

  @override
  List<Object?> get props => [error];
}

final class OrderFormFailed extends OrderFormState {
  const OrderFormFailed(this.cause);

  final Object cause;

  @override
  List<Object?> get props => [cause];
}
