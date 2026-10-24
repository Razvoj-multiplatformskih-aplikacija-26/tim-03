import 'package:domain/domain.dart';
import 'package:meta/meta.dart';

/// Everything an owner asks for in a new order. The repository gives the order its id.
@immutable
final class OrderRequest {
  const OrderRequest({required this.owner, required this.pet, required this.service, required this.period, this.note});

  final User owner;
  final Pet pet;
  final ServiceType service;
  final ServicePeriod period;
  final OrderNote? note;

  @override
  bool operator ==(Object other) =>
      other is OrderRequest &&
      other.owner == owner &&
      other.pet == pet &&
      other.service == service &&
      other.period == period &&
      other.note == note;

  @override
  int get hashCode => Object.hash(owner, pet, service, period, note);

  @override
  String toString() => 'OrderRequest(${pet.name}, ${service.name}, $period)';
}
