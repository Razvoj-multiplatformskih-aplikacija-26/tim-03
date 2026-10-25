import 'package:domain/domain.dart';

import 'serbian.dart';

/// The only place that turns a domain error into text. Numbers come from the domain constants, so changing a rule
/// changes the message too.
extension DomainErrorMessage on DomainError {
  String get message => switch (this) {
    NoteTooLong() => 'Napomena može imati najviše ${OrderNote.maxLength} znakova.',
    InvalidStayLength() => 'Boravak traje od ${StayLength.min} do ${StayLength.max} noći.',
    PeriodInPast() => 'Izabrani termin je prošao.',
    NotOnHalfHour() => 'Termin počinje na pun sat ili pola sata.',
    OutsideOpeningHours() => 'Termin je van radnog vremena centra.',
    CancellationTooLate() =>
      'Nalog može da se otkaže najkasnije ${hoursLabel(cancellationNotice.inHours)} pre početka.',
    InvalidTransition() => 'Ova promena naloga nije moguća.',
    PetAlreadyBooked() => 'Ljubimac već ima nalog u tom periodu.',
    NoKennelAvailable() => 'Nema slobodnog boksa za izabrani period.',
    StaffNotAvailable() => 'Nema slobodnog osoblja za izabrani termin.',
    NotAllowed() => 'Nemate pravo na ovu radnju.',
    NotFound() => 'Nalog nije pronađen.',
  };
}
