part of 'order_form_bloc.dart';

sealed class OrderFormEvent {
  const OrderFormEvent();
}

/// The fields are domain types (ServicePeriod, OrderNote), so an invalid value cannot reach the bloc.
final class OrderFormSubmitted extends OrderFormEvent {
  const OrderFormSubmitted({required this.pet, required this.service, required this.period, this.note});

  final Pet pet;
  final ServiceType service;
  final ServicePeriod period;
  final OrderNote? note;
}
