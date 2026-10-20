import 'package:domain/domain.dart';

String pluralize(int count, {required String one, required String few, required String many}) {
  final lastDigit = count % 10;
  final lastTwoDigits = count % 100;
  if (lastDigit == 1 && lastTwoDigits != 11) return one;
  if (lastDigit >= 2 && lastDigit <= 4 && (lastTwoDigits < 12 || lastTwoDigits > 14)) return few;
  return many;
}

String nightsLabel(int count) => '$count ${pluralize(count, one: 'noć', few: 'noći', many: 'noći')}';

String hoursLabel(int count) => '$count ${pluralize(count, one: 'sat', few: 'sata', many: 'sati')}';

String minutesLabel(int count) => '$count ${pluralize(count, one: 'minut', few: 'minuta', many: 'minuta')}';

String durationLabel(Duration duration) =>
    duration.inMinutes % 60 == 0 ? hoursLabel(duration.inHours) : minutesLabel(duration.inMinutes);

String activeOrdersLabel(int count) =>
    '$count ${pluralize(count, one: 'aktivan nalog', few: 'aktivna naloga', many: 'aktivnih naloga')}';

const _weekdays = ['ponedeljak', 'utorak', 'sreda', 'četvrtak', 'petak', 'subota', 'nedelja'];
const _months = [
  'januar',
  'februar',
  'mart',
  'april',
  'maj',
  'jun',
  'jul',
  'avgust',
  'septembar',
  'oktobar',
  'novembar',
  'decembar',
];

String _longDate(DateTime date) => '${_weekdays[date.weekday - 1]}, ${date.day}. ${_months[date.month - 1]}';

String _shortDate(DateTime date) => '${date.day}. ${date.month}.';

String _time(DateTime date) => '${_twoDigits(date.hour)}:${_twoDigits(date.minute)}';

String _twoDigits(int value) => value.toString().padLeft(2, '0');

/// A calendar day that is already in the center's time zone, such as a day picked in the form.
String formatLocalDate(DateTime localDate) => _longDate(localDate);

String formatTime(DateTime instant) => _time(centerTime(instant));

String formatDate(DateTime instant) => _longDate(centerTime(instant));

String formatShortDate(DateTime instant) => _shortDate(centerTime(instant));

String formatDateAndTime(DateTime instant) => '${formatDate(instant)} u ${formatTime(instant)}';

String capitalize(String text) => text.isEmpty ? text : text[0].toUpperCase() + text.substring(1);

/// Whole nights between handing a pet over and picking it up, counted in the center's calendar.
int nightsOf(ServicePeriod period) {
  final start = centerTime(period.start);
  final end = centerTime(period.end);
  return DateTime.utc(end.year, end.month, end.day).difference(DateTime.utc(start.year, start.month, start.day)).inDays;
}

/// When the order takes place, in one line.
String periodLabel(ServiceOrder order) {
  final period = order.period;
  return switch (order.service) {
    ServiceType.boarding =>
      '${formatShortDate(period.start)} – ${formatShortDate(period.end)} · ${nightsLabel(nightsOf(period))}',
    ServiceType.grooming || ServiceType.vetCheckup || ServiceType.walk =>
      '${capitalize(formatDate(period.start))}, ${formatTime(period.start)}–${formatTime(period.end)}',
  };
}

extension ServiceTypeText on ServiceType {
  String get label => switch (this) {
    ServiceType.boarding => 'Pansion',
    ServiceType.grooming => 'Kupanje i šišanje',
    ServiceType.vetCheckup => 'Veterinarski pregled',
    ServiceType.walk => 'Šetnja',
  };
}

extension RoleText on Role {
  String get label => switch (this) {
    Role.owner => 'Vlasnik',
    Role.caretaker => 'Negovatelj',
    Role.veterinarian => 'Veterinar',
    Role.walker => 'Šetač',
    Role.manager => 'Menadžer',
  };
}

extension PetText on Pet {
  String get description {
    final speciesLabel = switch (species) {
      Species.dog => 'Pas',
      Species.cat => 'Mačka',
    };
    final feminine = species == Species.cat;
    final sizeLabel = switch (size) {
      PetSize.small => feminine ? 'mala' : 'mali',
      PetSize.medium => feminine ? 'srednja' : 'srednji',
      PetSize.large => feminine ? 'velika' : 'veliki',
    };
    return '$speciesLabel, $sizeLabel';
  }
}

/// A walk ends at the owner's door, so its last two states read differently.
String statusLabel(OrderStatus status, ServiceType service) {
  final isWalk = service == ServiceType.walk;
  return switch (status) {
    Pending() => 'Na čekanju',
    Confirmed() => 'Potvrđen',
    InProgress() => isWalk ? 'U šetnji' : 'U toku',
    ReadyForPickup() => isWalk ? 'Vraćen vlasniku' : 'Spreman za preuzimanje',
    Completed() => 'Završen',
    Rejected() => 'Odbijen',
    Cancelled() => 'Otkazan',
  };
}
