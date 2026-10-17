import 'center/kennel.dart';
import 'errors.dart';
import 'identifiers.dart';
import 'order/service_order.dart';
import 'order/service_period.dart';
import 'order/service_type.dart';
import 'pet/pet.dart';
import 'result.dart';
import 'user.dart';

/// A walker needs this much time to get from one owner's address to the next.
const walkTravelTime = Duration(minutes: 30);

bool petIsFree({required PetId petId, required List<ServiceOrder> orders, required ServicePeriod period}) =>
    !orders.any((o) => o.isActive && o.petId == petId && o.period.overlaps(period));

List<Kennel> freeKennelsFor({
  required List<Kennel> kennels,
  required List<ServiceOrder> orders,
  required ServicePeriod period,
  required PetSize petSize,
}) {
  bool isTaken(Kennel kennel) => orders.any((o) => o.isActive && o.kennelId == kennel.id && o.period.overlaps(period));
  return [
    for (final kennel in kennels)
      if (kennel.fits(petSize) && !isTaken(kennel)) kennel,
  ];
}

/// The smallest free kennel that fits, so larger kennels stay free for larger pets.
Result<Kennel> assignKennel({
  required List<Kennel> kennels,
  required List<ServiceOrder> orders,
  required ServicePeriod period,
  required PetSize petSize,
}) {
  final free = freeKennelsFor(kennels: kennels, orders: orders, period: period, petSize: petSize);
  if (free.isEmpty) return const Failure(NoKennelAvailable());
  free.sort((a, b) {
    final bySize = a.size.index.compareTo(b.size.index);
    return bySize != 0 ? bySize : a.label.compareTo(b.label);
  });
  return Success(free.first);
}

List<User> freeStaffFor({
  required List<User> staff,
  required List<ServiceOrder> orders,
  required ServiceType service,
  required ServicePeriod period,
}) {
  final gap = service == ServiceType.walk ? walkTravelTime : Duration.zero;
  bool isBusy(User member) =>
      orders.any((o) => o.isActive && o.assigneeId == member.id && o.period.overlaps(period, gap: gap));
  return [
    for (final member in staff)
      if (member.role == service.performer && !isBusy(member)) member,
  ];
}

Result<User> assignStaff({
  required List<User> staff,
  required List<ServiceOrder> orders,
  required ServiceType service,
  required ServicePeriod period,
}) {
  final free = freeStaffFor(staff: staff, orders: orders, service: service, period: period);
  if (free.isEmpty) return const Failure(StaffNotAvailable());
  return Success(free.first);
}
