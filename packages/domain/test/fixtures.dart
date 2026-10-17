import 'package:domain/domain.dart';

/// Monday to Friday 8–20, Saturday 9–15, closed on Sunday.
OpeningHours standardOpeningHours() => OpeningHours({
  DateTime.monday: const DayHours(open: LocalTime(8, 0), close: LocalTime(20, 0)),
  DateTime.tuesday: const DayHours(open: LocalTime(8, 0), close: LocalTime(20, 0)),
  DateTime.wednesday: const DayHours(open: LocalTime(8, 0), close: LocalTime(20, 0)),
  DateTime.thursday: const DayHours(open: LocalTime(8, 0), close: LocalTime(20, 0)),
  DateTime.friday: const DayHours(open: LocalTime(8, 0), close: LocalTime(20, 0)),
  DateTime.saturday: const DayHours(open: LocalTime(9, 0), close: LocalTime(15, 0)),
});

DateTime belgrade(int year, int month, int day, int hour, [int minute = 0]) =>
    standardOpeningHours().localToUtc(year, month, day, LocalTime(hour, minute));

const owner = User(id: UserId('u-owner'), name: 'Ana', role: Role.owner);
const otherOwner = User(id: UserId('u-owner-2'), name: 'Marko', role: Role.owner);
const caretaker = User(id: UserId('u-caretaker'), name: 'Jelena', role: Role.caretaker);
const vet = User(id: UserId('u-vet'), name: 'Dr Petrović', role: Role.veterinarian);
const walker = User(id: UserId('u-walker'), name: 'Nikola', role: Role.walker);
const manager = User(id: UserId('u-manager'), name: 'Milica', role: Role.manager);

const rex = Pet(
  id: PetId('p-rex'),
  ownerId: UserId('u-owner'),
  name: 'Reks',
  species: Species.dog,
  size: PetSize.large,
);
const mica = Pet(
  id: PetId('p-mica'),
  ownerId: UserId('u-owner'),
  name: 'Mica',
  species: Species.cat,
  size: PetSize.small,
);

ServiceOrder orderAt(
  DateTime start, {
  String id = 'o-1',
  ServiceType service = ServiceType.grooming,
  Duration length = const Duration(hours: 2),
  OrderStatus status = const Pending(),
  UserId ownerId = const UserId('u-owner'),
  PetId petId = const PetId('p-rex'),
  KennelId? kennelId,
  UserId? assigneeId,
}) {
  return ServiceOrder(
    id: OrderId(id),
    ownerId: ownerId,
    petId: petId,
    service: service,
    period: ServicePeriod.existing(start: start, end: start.add(length)),
    status: status,
    kennelId: kennelId,
    assigneeId: assigneeId,
    createdAt: start.subtract(const Duration(days: 3)),
  );
}
