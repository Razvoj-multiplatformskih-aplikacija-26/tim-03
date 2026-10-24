part of 'order_form_bloc.dart';

sealed class OrderFormState extends Equatable {
  const OrderFormState();

  @override
  List<Object?> get props => const [];

  @override
  String toString() => '$runtimeType';
}

/// The owner is filling in the form; it is also where the form returns after a refusal.
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

/// The rules said no, for example the pet already has an order then (R6).
final class OrderFormRejected extends OrderFormState {
  const OrderFormRejected(this.error);

  final DomainError error;

  @override
  List<Object?> get props => [error];
}

/// The order did not reach the repository; the owner can send it again.
final class OrderFormFailed extends OrderFormState {
  const OrderFormFailed(this.cause);

  final Object cause;

  @override
  List<Object?> get props => [cause];
}
