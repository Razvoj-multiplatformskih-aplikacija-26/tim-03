import 'package:domain/domain.dart';

const _caretaker = User(id: UserId('u-caretaker'), name: 'Marija Ilić', role: Role.caretaker);
const _caretaker2 = User(id: UserId('u-caretaker-2'), name: 'Jovana Lukić', role: Role.caretaker);
const _vet = User(id: UserId('u-vet'), name: 'dr Stefan Kovač', role: Role.veterinarian);
const _walker = User(id: UserId('u-walker'), name: 'Nikola Jović', role: Role.walker);

/// The one signed-in member of staff. Only a manager may both confirm and reject, so every action can be shown.
const currentStaff = User(id: UserId('u-manager'), name: 'Ivana Simić', role: Role.manager);

const fakeStaff = [_caretaker, _caretaker2, _vet, _walker, currentStaff];

const _jelena = User(id: UserId('u-jelena'), name: 'Jelena Marković', role: Role.owner);
const _petar = User(id: UserId('u-petar'), name: 'Petar Nikolić', role: Role.owner);
const _ana = User(id: UserId('u-ana'), name: 'Ana Popović', role: Role.owner);
const _milos = User(id: UserId('u-milos'), name: 'Miloš Stojanović', role: Role.owner);
const _sara = User(id: UserId('u-sara'), name: 'Sara Đorđević', role: Role.owner);
const _ivan = User(id: UserId('u-ivan'), name: 'Ivan Pavlović', role: Role.owner);

const fakeOwners = [_jelena, _petar, _ana, _milos, _sara, _ivan];

/// Two kennels of each size, so the large ones can run out (R7).
const fakeKennels = [
  Kennel(id: KennelId('k-a1'), label: 'A1', size: PetSize.small),
  Kennel(id: KennelId('k-a2'), label: 'A2', size: PetSize.small),
  Kennel(id: KennelId('k-b1'), label: 'B1', size: PetSize.medium),
  Kennel(id: KennelId('k-b2'), label: 'B2', size: PetSize.medium),
  Kennel(id: KennelId('k-c1'), label: 'C1', size: PetSize.large),
  Kennel(id: KennelId('k-c2'), label: 'C2', size: PetSize.large),
];

const _reks = Pet(
  id: PetId('p-reks'),
  ownerId: UserId('u-jelena'),
  name: 'Reks',
  species: Species.dog,
  size: PetSize.large,
);
const _mica = Pet(
  id: PetId('p-mica'),
  ownerId: UserId('u-jelena'),
  name: 'Mica',
  species: Species.cat,
  size: PetSize.small,
);
const _bobi = Pet(
  id: PetId('p-bobi'),
  ownerId: UserId('u-jelena'),
  name: 'Bobi',
  species: Species.dog,
  size: PetSize.medium,
);
const _luna = Pet(
  id: PetId('p-luna'),
  ownerId: UserId('u-petar'),
  name: 'Luna',
  species: Species.dog,
  size: PetSize.medium,
);
const _maza = Pet(
  id: PetId('p-maza'),
  ownerId: UserId('u-ana'),
  name: 'Maza',
  species: Species.cat,
  size: PetSize.small,
);
const _tom = Pet(id: PetId('p-tom'), ownerId: UserId('u-ana'), name: 'Tom', species: Species.cat, size: PetSize.small);
const _dzeki = Pet(
  id: PetId('p-dzeki'),
  ownerId: UserId('u-milos'),
  name: 'Džeki',
  species: Species.dog,
  size: PetSize.large,
);
const _kiki = Pet(
  id: PetId('p-kiki'),
  ownerId: UserId('u-sara'),
  name: 'Kiki',
  species: Species.cat,
  size: PetSize.small,
);
const _floki = Pet(
  id: PetId('p-floki'),
  ownerId: UserId('u-sara'),
  name: 'Floki',
  species: Species.dog,
  size: PetSize.small,
);
const _max = Pet(id: PetId('p-max'), ownerId: UserId('u-ivan'), name: 'Max', species: Species.dog, size: PetSize.large);

const fakePets = [_reks, _mica, _bobi, _luna, _maza, _tom, _dzeki, _kiki, _floki, _max];

/// Monday to Friday 8–20, Saturday 9–15, closed on Sunday.
final centerOpeningHours = OpeningHours({
  DateTime.monday: const DayHours(open: LocalTime(8, 0), close: LocalTime(20, 0)),
  DateTime.tuesday: const DayHours(open: LocalTime(8, 0), close: LocalTime(20, 0)),
  DateTime.wednesday: const DayHours(open: LocalTime(8, 0), close: LocalTime(20, 0)),
  DateTime.thursday: const DayHours(open: LocalTime(8, 0), close: LocalTime(20, 0)),
  DateTime.friday: const DayHours(open: LocalTime(8, 0), close: LocalTime(20, 0)),
  DateTime.saturday: const DayHours(open: LocalTime(9, 0), close: LocalTime(15, 0)),
});

/// Every order of the center around [now], in all seven states. Two of the pending ones cannot be confirmed: no large
/// kennel is free for Reks (R7), and the only walker is out with Max when Džeki's walk would start (R8).
List<ServiceOrder> seedOrders(DateTime now) {
  final hours = centerOpeningHours;
  final today = centerDay(now);

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

  Confirmed confirmed() => Confirmed(confirmedBy: currentStaff.id, at: ago(const Duration(days: 1)));

  final bobiStay = stay(at(-2, 10), 4);
  final kikiStay = stay(at(-3, 10), 4);
  final reksGrooming = visit(ServiceType.grooming, at(0, 9));
  final dzekiGrooming = visit(ServiceType.grooming, at(0, 12));
  final bobiVet = visit(ServiceType.vetCheckup, at(-14, 10, 30));
  final micaStay = stay(at(-30, 10), 3);
  final maxGrooming = visit(ServiceType.grooming, at(-7, 11));
  final lunaWalk = visit(ServiceType.walk, at(-3, 9));
  final tomVet = visit(ServiceType.vetCheckup, at(-10, 9));

  DateTime readyAt(ServicePeriod period) => period.end.isBefore(now) ? period.end : ago(Duration.zero);

  return [
    // Waiting for staff.
    order(
      'o-101',
      _reks,
      ServiceType.boarding,
      stay(at(5, 10), 4),
      note: 'Hrana je u rancu, dva obroka dnevno. Ne voli druge pse.',
    ),
    order('o-102', _luna, ServiceType.grooming, visit(ServiceType.grooming, at(1, 11))),
    order('o-103', _dzeki, ServiceType.walk, visit(ServiceType.walk, at(2, 10, 30)), note: 'Vuče na povocu.'),
    order('o-104', _mica, ServiceType.vetCheckup, visit(ServiceType.vetCheckup, at(3, 9)), note: 'Ne jede od juče.'),
    order('o-105', _kiki, ServiceType.boarding, stay(at(7, 10), 3)),
    order('o-106', _floki, ServiceType.grooming, visit(ServiceType.grooming, at(4, 12))),
    order(
      'o-107',
      _tom,
      ServiceType.vetCheckup,
      visit(ServiceType.vetCheckup, at(6, 12)),
      note: 'Godišnja vakcinacija.',
    ),
    order('o-108', _bobi, ServiceType.walk, visit(ServiceType.walk, at(8, 9))),
    // Confirmed, with the walker, the large kennels and the vet already taken.
    order(
      'o-109',
      _max,
      ServiceType.walk,
      visit(ServiceType.walk, at(2, 10)),
      assigneeId: _walker.id,
      status: confirmed(),
    ),
    order(
      'o-110',
      _dzeki,
      ServiceType.boarding,
      stay(at(4, 10), 7),
      kennelId: const KennelId('k-c1'),
      status: confirmed(),
    ),
    order(
      'o-111',
      _max,
      ServiceType.boarding,
      stay(at(4, 10), 6),
      kennelId: const KennelId('k-c2'),
      status: confirmed(),
    ),
    order(
      'o-112',
      _luna,
      ServiceType.vetCheckup,
      visit(ServiceType.vetCheckup, at(9, 10, 30)),
      assigneeId: _vet.id,
      status: confirmed(),
    ),
    order(
      'o-113',
      _maza,
      ServiceType.grooming,
      visit(ServiceType.grooming, at(1, 9)),
      assigneeId: _caretaker2.id,
      status: confirmed(),
    ),
    // In the center right now.
    order(
      'o-114',
      _bobi,
      ServiceType.boarding,
      bobiStay,
      kennelId: const KennelId('k-b1'),
      status: InProgress(receivedBy: _caretaker.id, at: bobiStay.start),
    ),
    order(
      'o-115',
      _kiki,
      ServiceType.boarding,
      kikiStay,
      kennelId: const KennelId('k-a1'),
      status: InProgress(receivedBy: _caretaker2.id, at: kikiStay.start),
    ),
    order(
      'o-116',
      _reks,
      ServiceType.grooming,
      reksGrooming,
      assigneeId: _caretaker.id,
      status: ReadyForPickup(at: readyAt(reksGrooming)),
    ),
    order(
      'o-117',
      _dzeki,
      ServiceType.grooming,
      dzekiGrooming,
      assigneeId: _caretaker2.id,
      status: ReadyForPickup(at: readyAt(dzekiGrooming)),
    ),
    // Over.
    order(
      'o-118',
      _bobi,
      ServiceType.vetCheckup,
      bobiVet,
      assigneeId: _vet.id,
      status: Completed(at: bobiVet.end),
    ),
    order(
      'o-119',
      _mica,
      ServiceType.boarding,
      micaStay,
      kennelId: const KennelId('k-a2'),
      status: Completed(at: micaStay.end),
    ),
    order(
      'o-120',
      _max,
      ServiceType.grooming,
      maxGrooming,
      assigneeId: _caretaker.id,
      status: Completed(at: maxGrooming.end),
    ),
    order(
      'o-121',
      _luna,
      ServiceType.walk,
      lunaWalk,
      assigneeId: _walker.id,
      status: Completed(at: lunaWalk.end),
    ),
    order(
      'o-122',
      _tom,
      ServiceType.vetCheckup,
      tomVet,
      assigneeId: _vet.id,
      status: Completed(at: tomVet.end),
    ),
    order(
      'o-123',
      _reks,
      ServiceType.boarding,
      stay(at(20, 10), 7),
      status: Rejected(
        reason: 'Svi veliki boksovi su zauzeti u tom periodu.',
        rejectedBy: currentStaff.id,
        at: ago(const Duration(days: 2)),
      ),
    ),
    order(
      'o-124',
      _kiki,
      ServiceType.grooming,
      visit(ServiceType.grooming, at(-6, 10)),
      status: Rejected(reason: 'Termin je popunjen.', rejectedBy: currentStaff.id, at: ago(const Duration(days: 9))),
    ),
    order(
      'o-125',
      _bobi,
      ServiceType.walk,
      visit(ServiceType.walk, at(-5, 10)),
      status: Cancelled(reason: 'Ljubimac je bolestan.', cancelledBy: _jelena.id, at: ago(const Duration(days: 7))),
    ),
    order(
      'o-126',
      _reks,
      ServiceType.grooming,
      visit(ServiceType.grooming, at(-9, 12)),
      assigneeId: _caretaker.id,
      status: Cancelled(
        reason: 'Negovateljica je sprečena.',
        cancelledBy: currentStaff.id,
        at: ago(const Duration(days: 10)),
      ),
    ),
    order(
      'o-127',
      _floki,
      ServiceType.boarding,
      stay(at(12, 10), 2),
      status: Cancelled(reason: 'Promena planova.', cancelledBy: _sara.id, at: ago(const Duration(days: 1))),
    ),
  ];
}
