import 'package:api_contract/api_contract.dart';
import 'package:domain/domain.dart';

import 'order_mapping.dart';

extension DomainErrorMapping on DomainError {
  ProblemDto toProblem() => switch (this) {
    NoteTooLong(:final length, :final max) => ProblemDto(
      status: 422,
      code: ErrorCodes.noteTooLong,
      title: 'Note too long',
      value: length,
      max: max,
    ),
    InvalidStayLength(:final nights, :final min, :final max) => ProblemDto(
      status: 422,
      code: ErrorCodes.invalidStayLength,
      title: 'Invalid stay length',
      value: nights,
      min: min,
      max: max,
    ),
    PeriodInPast() => const ProblemDto(status: 422, code: ErrorCodes.periodInPast, title: 'Period in the past'),
    NotOnHalfHour() => const ProblemDto(status: 422, code: ErrorCodes.notOnHalfHour, title: 'Not on a half hour'),
    OutsideOpeningHours() => const ProblemDto(
      status: 422,
      code: ErrorCodes.outsideOpeningHours,
      title: 'Outside opening hours',
    ),
    CancellationTooLate(:final notice) => ProblemDto(
      status: 422,
      code: ErrorCodes.cancellationTooLate,
      title: 'Cancellation too late',
      min: notice.inMinutes,
    ),
    InvalidTransition(:final from, :final to) => ProblemDto(
      status: 409,
      code: ErrorCodes.invalidTransition,
      title: 'Invalid transition',
      from: from.toDto(),
      to: to.toDto(),
    ),
    PetAlreadyBooked() => const ProblemDto(status: 409, code: ErrorCodes.petAlreadyBooked, title: 'Pet already booked'),
    NoKennelAvailable() => const ProblemDto(
      status: 409,
      code: ErrorCodes.noKennelAvailable,
      title: 'No kennel available',
    ),
    StaffNotAvailable() => const ProblemDto(
      status: 409,
      code: ErrorCodes.staffNotAvailable,
      title: 'Staff not available',
    ),
    NotAllowed() => const ProblemDto(status: 403, code: ErrorCodes.notAllowed, title: 'Not allowed'),
    NotFound() => const ProblemDto(status: 404, code: ErrorCodes.notFound, title: 'Not found'),
  };
}

extension ProblemMapping on ProblemDto {
  /// Null for a code this build does not know, so an older app explains the refusal without crashing.
  DomainError? toDomainError() => switch (this) {
    ProblemDto(code: ErrorCodes.noteTooLong, :final value?, :final max?) => NoteTooLong(value, max: max),
    ProblemDto(code: ErrorCodes.invalidStayLength, :final value?, :final min?, :final max?) => InvalidStayLength(
      value,
      min: min,
      max: max,
    ),
    ProblemDto(code: ErrorCodes.periodInPast) => const PeriodInPast(),
    ProblemDto(code: ErrorCodes.notOnHalfHour) => const NotOnHalfHour(),
    ProblemDto(code: ErrorCodes.outsideOpeningHours) => const OutsideOpeningHours(),
    ProblemDto(code: ErrorCodes.cancellationTooLate, :final min?) => CancellationTooLate(
      notice: Duration(minutes: min),
    ),
    ProblemDto(code: ErrorCodes.invalidTransition, :final from?, :final to?) => InvalidTransition(
      from: from.toDomain(),
      to: to.toDomain(),
    ),
    ProblemDto(code: ErrorCodes.petAlreadyBooked) => const PetAlreadyBooked(),
    ProblemDto(code: ErrorCodes.noKennelAvailable) => const NoKennelAvailable(),
    ProblemDto(code: ErrorCodes.staffNotAvailable) => const StaffNotAvailable(),
    ProblemDto(code: ErrorCodes.notAllowed) => const NotAllowed(),
    ProblemDto(code: ErrorCodes.notFound) => const NotFound(),
    _ => null,
  };
}
