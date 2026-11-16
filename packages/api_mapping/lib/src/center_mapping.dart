import 'package:api_contract/api_contract.dart';
import 'package:domain/domain.dart';

extension ServiceTypeMapping on ServiceType {
  String toDto() => switch (this) {
    ServiceType.boarding => ServiceTypeValues.boarding,
    ServiceType.grooming => ServiceTypeValues.grooming,
    ServiceType.vetCheckup => ServiceTypeValues.vetCheckup,
    ServiceType.walk => ServiceTypeValues.walk,
  };
}

ServiceType serviceTypeFromDto(String value) => switch (value) {
  ServiceTypeValues.boarding => ServiceType.boarding,
  ServiceTypeValues.grooming => ServiceType.grooming,
  ServiceTypeValues.vetCheckup => ServiceType.vetCheckup,
  ServiceTypeValues.walk => ServiceType.walk,
  _ => throw FormatException('Unknown service type', value),
};

extension SpeciesMapping on Species {
  String toDto() => switch (this) {
    Species.dog => SpeciesValues.dog,
    Species.cat => SpeciesValues.cat,
  };
}

Species speciesFromDto(String value) => switch (value) {
  SpeciesValues.dog => Species.dog,
  SpeciesValues.cat => Species.cat,
  _ => throw FormatException('Unknown species', value),
};

extension PetSizeMapping on PetSize {
  String toDto() => switch (this) {
    PetSize.small => PetSizeValues.small,
    PetSize.medium => PetSizeValues.medium,
    PetSize.large => PetSizeValues.large,
  };
}

PetSize petSizeFromDto(String value) => switch (value) {
  PetSizeValues.small => PetSize.small,
  PetSizeValues.medium => PetSize.medium,
  PetSizeValues.large => PetSize.large,
  _ => throw FormatException('Unknown pet size', value),
};

extension RoleMapping on Role {
  String toDto() => switch (this) {
    Role.owner => RoleValues.owner,
    Role.caretaker => RoleValues.caretaker,
    Role.veterinarian => RoleValues.veterinarian,
    Role.walker => RoleValues.walker,
    Role.manager => RoleValues.manager,
  };
}

Role roleFromDto(String value) => switch (value) {
  RoleValues.owner => Role.owner,
  RoleValues.caretaker => Role.caretaker,
  RoleValues.veterinarian => Role.veterinarian,
  RoleValues.walker => Role.walker,
  RoleValues.manager => Role.manager,
  _ => throw FormatException('Unknown role', value),
};

extension UserMapping on User {
  UserDto toDto() => UserDto(id: id.value, name: name, role: role.toDto());
}

extension UserDtoMapping on UserDto {
  User toDomain() => User(id: UserId(id), name: name, role: roleFromDto(role));
}

extension PetMapping on Pet {
  PetDto toDto() =>
      PetDto(id: id.value, ownerId: ownerId.value, name: name, species: species.toDto(), size: size.toDto());
}

extension PetDtoMapping on PetDto {
  Pet toDomain() => Pet(
    id: PetId(id),
    ownerId: UserId(ownerId),
    name: name,
    species: speciesFromDto(species),
    size: petSizeFromDto(size),
  );
}

extension KennelMapping on Kennel {
  KennelDto toDto() => KennelDto(id: id.value, label: label, size: size.toDto());
}

extension KennelDtoMapping on KennelDto {
  Kennel toDomain() => Kennel(id: KennelId(id), label: label, size: petSizeFromDto(size));
}

extension OpeningHoursMapping on OpeningHours {
  OpeningHoursDto toDto() => OpeningHoursDto(
    timeZone: location.name,
    days: [
      for (var weekday = DateTime.monday; weekday <= DateTime.sunday; weekday++)
        if (forWeekday(weekday) case final hours?)
          DayHoursDto(weekday: weekday, open: hours.open.toString(), close: hours.close.toString()),
    ],
  );
}

extension OpeningHoursDtoMapping on OpeningHoursDto {
  OpeningHours toDomain() => OpeningHours({
    for (final day in days) day.weekday: DayHours(open: _localTime(day.open), close: _localTime(day.close)),
  }, timeZone: timeZone);
}

LocalTime _localTime(String value) => switch (value.split(':')) {
  [final hour, final minute] => LocalTime(int.parse(hour), int.parse(minute)),
  _ => throw FormatException('Expected a time like 08:30', value),
};
