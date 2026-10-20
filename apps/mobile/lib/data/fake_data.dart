import 'package:domain/domain.dart';
import 'package:flutter/foundation.dart';

/// The one signed-in user of the app. Signing in arrives with the server in KT2.
const currentOwner = User(id: UserId('u-owner'), name: 'Jelena Marković', role: Role.owner);

const _caretaker = User(id: UserId('u-caretaker'), name: 'Marija Ilić', role: Role.caretaker);
const _vet = User(id: UserId('u-vet'), name: 'dr Stefan Kovač', role: Role.veterinarian);
const _walker = User(id: UserId('u-walker'), name: 'Nikola Jović', role: Role.walker);
const _manager = User(id: UserId('u-manager'), name: 'Ivana Simić', role: Role.manager);

const fakeStaff = [_caretaker, _vet, _walker, _manager];

const fakeKennels = [
  Kennel(id: KennelId('k-a1'), label: 'A1', size: PetSize.small),
  Kennel(id: KennelId('k-b1'), label: 'B1', size: PetSize.medium),
  Kennel(id: KennelId('k-c1'), label: 'C1', size: PetSize.large),
];

const fakePets = [
  Pet(id: PetId('p-rex'), ownerId: UserId('u-owner'), name: 'Reks', species: Species.dog, size: PetSize.large),
  Pet(id: PetId('p-mica'), ownerId: UserId('u-owner'), name: 'Mica', species: Species.cat, size: PetSize.small),
  Pet(id: PetId('p-bobi'), ownerId: UserId('u-owner'), name: 'Bobi', species: Species.dog, size: PetSize.medium),
];

/// Monday to Friday 8–20, Saturday 9–15, closed on Sunday.
final centerOpeningHours = OpeningHours({
  DateTime.monday: const DayHours(open: LocalTime(8, 0), close: LocalTime(20, 0)),
  DateTime.tuesday: const DayHours(open: LocalTime(8, 0), close: LocalTime(20, 0)),
  DateTime.wednesday: const DayHours(open: LocalTime(8, 0), close: LocalTime(20, 0)),
  DateTime.thursday: const DayHours(open: LocalTime(8, 0), close: LocalTime(20, 0)),
  DateTime.friday: const DayHours(open: LocalTime(8, 0), close: LocalTime(20, 0)),
  DateTime.saturday: const DayHours(open: LocalTime(9, 0), close: LocalTime(15, 0)),
});

Pet? petById(PetId id) => fakePets.where((pet) => pet.id == id).firstOrNull;

User? staffById(UserId id) => fakeStaff.where((user) => user.id == id).firstOrNull;

Kennel? kennelById(KennelId id) => fakeKennels.where((kennel) => kennel.id == id).firstOrNull;

/// Orders kept in memory for the demo. In Faza 4 a repository behind a port takes its place.
class FakeOrders extends ChangeNotifier {
  FakeOrders(List<ServiceOrder> orders) : _orders = [...orders];

  final List<ServiceOrder> _orders;

  List<ServiceOrder> get all => List.unmodifiable(_orders);

  ServiceOrder? byId(OrderId id) => _orders.where((order) => order.id == id).firstOrNull;

  void add(ServiceOrder order) {
    _orders.add(order);
    notifyListeners();
  }

  void replace(ServiceOrder order) {
    _orders[_orders.indexWhere((existing) => existing.id == order.id)] = order;
    notifyListeners();
  }
}

final fakeOrders = FakeOrders(seedOrders(DateTime.now()));

/// Twelve orders around [now], at least one in each of the seven states.
List<ServiceOrder> seedOrders(DateTime now) {
  final hours = centerOpeningHours;
  final today = centerDay(now);
  final [rex, mica, bobi] = fakePets;

  // A day the center is open, [offset] days from today. Closed days move away from today.
  DateTime day(int offset) {
    var date = DateTime(today.year, today.month, today.day + offset);
    while (!hours.isOpenOn(date.weekday)) {
      date = DateTime(date.year, date.month, date.day + (offset <= 0 ? -1 : 1));
    }
    return date;
  }

  DateTime at(int offset, int hour, [int minute = 0]) {
    final date = day(offset);
    return hours.localToUtc(date.year, date.month, date.day, LocalTime(hour, minute));
  }

  ServicePeriod visit(ServiceType service, DateTime start) =>
      ServicePeriod.existing(start: start, end: start.add(service.visitLength!));

  ServicePeriod stay(DateTime start, int nights) {
    var end = hours.addLocalDays(start, nights);
    while (!hours.covers(end, ServicePeriod.step)) {
      end = hours.addLocalDays(end, 1);
    }
    return ServicePeriod.existing(start: start, end: end);
  }

  // The first vet checkup a few hours from now, so one confirmed order is usually too close to cancel.
  DateTime soon() {
    for (var offset = 0; offset < 7; offset++) {
      final date = DateTime(today.year, today.month, today.day + offset);
      final starts = hours.startsOn(date, length: ServiceType.vetCheckup.visitLength!, step: ServicePeriod.step);
      for (final start in starts) {
        if (start.isAfter(now.add(const Duration(hours: 3)))) return start;
      }
    }
    return at(1, 10);
  }

  DateTime ago(Duration duration) => now.subtract(duration).toUtc();

  ServiceOrder order(
    String id,
    Pet pet,
    ServiceType service,
    ServicePeriod period, {
    OrderStatus status = const Pending(),
    String? note,
    KennelId? kennelId,
    UserId? assigneeId,
  }) {
    final weekBefore = period.start.subtract(const Duration(days: 7));
    return ServiceOrder(
      id: OrderId(id),
      ownerId: pet.ownerId,
      petId: pet.id,
      service: service,
      period: period,
      createdAt: weekBefore.isBefore(now) ? weekBefore.toUtc() : ago(const Duration(hours: 5)),
      note: note == null ? null : OrderNote.parse(note).valueOrNull,
      kennelId: kennelId,
      assigneeId: assigneeId,
      status: status,
    );
  }

  final groomingToday = visit(ServiceType.grooming, at(0, 9));
  final bobiStay = stay(at(-2, 10), 4);
  final vetLastMonth = visit(ServiceType.vetCheckup, at(-14, 10, 30));
  final micaStay = stay(at(-30, 10), 3);

  return [
    order(
      'o-1',
      mica,
      ServiceType.grooming,
      visit(ServiceType.grooming, at(3, 10)),
      note: 'Mica se plaši fena, molimo vas za strpljenje.',
    ),
    order(
      'o-2',
      rex,
      ServiceType.boarding,
      stay(at(10, 10), 5),
      note: 'Hrana je u rancu, dva obroka dnevno. Ne voli druge pse.',
    ),
    order(
      'o-3',
      rex,
      ServiceType.walk,
      visit(ServiceType.walk, at(2, 9)),
      assigneeId: _walker.id,
      status: Confirmed(confirmedBy: _manager.id, at: ago(const Duration(hours: 20))),
    ),
    order(
      'o-4',
      bobi,
      ServiceType.vetCheckup,
      visit(ServiceType.vetCheckup, at(6, 11, 30)),
      note: 'Godišnja vakcinacija.',
      assigneeId: _vet.id,
      status: Confirmed(confirmedBy: _vet.id, at: ago(const Duration(days: 1))),
    ),
    order(
      'o-5',
      mica,
      ServiceType.vetCheckup,
      visit(ServiceType.vetCheckup, soon()),
      note: 'Ne jede od juče.',
      assigneeId: _vet.id,
      status: Confirmed(confirmedBy: _vet.id, at: ago(const Duration(hours: 1))),
    ),
    order(
      'o-6',
      bobi,
      ServiceType.boarding,
      bobiStay,
      kennelId: const KennelId('k-b1'),
      status: InProgress(receivedBy: _caretaker.id, at: bobiStay.start),
    ),
    order(
      'o-7',
      rex,
      ServiceType.grooming,
      groomingToday,
      assigneeId: _caretaker.id,
      status: ReadyForPickup(at: groomingToday.end.isBefore(now) ? groomingToday.end : ago(Duration.zero)),
    ),
    order(
      'o-8',
      bobi,
      ServiceType.vetCheckup,
      vetLastMonth,
      assigneeId: _vet.id,
      status: Completed(at: vetLastMonth.end),
    ),
    order(
      'o-9',
      mica,
      ServiceType.boarding,
      micaStay,
      kennelId: const KennelId('k-a1'),
      status: Completed(at: micaStay.end),
    ),
    order(
      'o-10',
      rex,
      ServiceType.boarding,
      stay(at(20, 10), 7),
      status: Rejected(
        reason: 'Svi veliki boksovi su zauzeti u tom periodu.',
        rejectedBy: _manager.id,
        at: ago(const Duration(days: 2)),
      ),
    ),
    order(
      'o-11',
      bobi,
      ServiceType.walk,
      visit(ServiceType.walk, at(-5, 10)),
      status: Cancelled(
        reason: 'Ljubimac je bolestan.',
        cancelledBy: currentOwner.id,
        at: ago(const Duration(days: 7)),
      ),
    ),
    order(
      'o-12',
      rex,
      ServiceType.grooming,
      visit(ServiceType.grooming, at(-9, 12)),
      assigneeId: _caretaker.id,
      status: Cancelled(
        reason: 'Negovateljica je sprečena, molimo vas da zakažete novi termin.',
        cancelledBy: _manager.id,
        at: ago(const Duration(days: 10)),
      ),
    ),
  ];
}
