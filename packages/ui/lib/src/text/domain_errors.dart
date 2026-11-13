import 'package:domain/domain.dart';

import 'serbian.dart';

extension DomainErrorMessage on DomainError {
  String get message => switch (this) {
    NoteTooLong(:final max) => 'Napomena može imati najviše $max znakova.',
    InvalidStayLength(:final min, :final max) => 'Boravak traje od $min do $max noći.',
    PeriodInPast() => 'Izabrani termin je prošao.',
    NotOnHalfHour() => 'Termin počinje na pun sat ili pola sata.',
    OutsideOpeningHours() => 'Termin je van radnog vremena centra.',
    CancellationTooLate(:final notice) => 'Nalog može da se otkaže najkasnije ${durationLabel(notice)} pre početka.',
    InvalidTransition() => 'Ova promena naloga nije moguća.',
    PetAlreadyBooked() => 'Ljubimac već ima nalog u tom periodu.',
    NoKennelAvailable() => 'Nema slobodnog boksa za izabrani period.',
    StaffNotAvailable() => 'Nema slobodnog osoblja za izabrani termin.',
    NotAllowed() => 'Nemate pravo na ovu radnju.',
    NotFound() => 'Nalog nije pronađen.',
  };
}
