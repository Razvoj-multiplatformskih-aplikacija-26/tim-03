part of 'order_form_bloc.dart';

sealed class OrderFormState extends Equatable {
  const OrderFormState();

  @override
  List<Object?> get props => const [];

  @override
  String toString() => '$runtimeType';
}

final class OrderFormLoading extends OrderFormState {
  const OrderFormLoading();
}

final class OrderFormUnavailable extends OrderFormState {
  const OrderFormUnavailable(this.cause);

  final Object cause;

  @override
  List<Object?> get props => [cause];
}

/// The owner's pets and the center's opening hours are loaded, so the form can be filled in and sent.
sealed class OrderFormReady extends OrderFormState {
  const OrderFormReady({required this.pets, required this.openingHours});

  final List<Pet> pets;
  final OpeningHours openingHours;

  @override
  List<Object?> get props => [pets, openingHours];
}

final class OrderFormEditing extends OrderFormReady {
  const OrderFormEditing({required super.pets, required super.openingHours});
}

final class OrderFormSubmitting extends OrderFormReady {
  const OrderFormSubmitting({required super.pets, required super.openingHours});
}

final class OrderFormSucceeded extends OrderFormReady {
  const OrderFormSucceeded(this.order, {required super.pets, required super.openingHours});

  final ServiceOrder order;

  @override
  List<Object?> get props => [...super.props, order];
}

final class OrderFormRejected extends OrderFormReady {
  const OrderFormRejected(this.error, {required super.pets, required super.openingHours});

  final DomainError error;

  @override
  List<Object?> get props => [...super.props, error];
}

final class OrderFormFailed extends OrderFormReady {
  const OrderFormFailed(this.cause, {required super.pets, required super.openingHours});

  final Object cause;

  @override
  List<Object?> get props => [...super.props, cause];
}
