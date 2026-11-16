import 'json.dart';
import 'order_dto.dart';

final class UserDto {
  const UserDto({required this.id, required this.name, required this.role});

  final String id;
  final String name;
  final String role;

  Map<String, Object?> toJson() => {'id': id, 'name': name, 'role': role};

  factory UserDto.fromJson(Map<String, Object?> json) =>
      UserDto(id: jsonString(json, 'id'), name: jsonString(json, 'name'), role: jsonString(json, 'role'));
}

final class PetDto {
  const PetDto({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.species,
    required this.size,
  });

  final String id;
  final String ownerId;
  final String name;
  final String species;
  final String size;

  Map<String, Object?> toJson() => {'id': id, 'ownerId': ownerId, 'name': name, 'species': species, 'size': size};

  factory PetDto.fromJson(Map<String, Object?> json) => PetDto(
    id: jsonString(json, 'id'),
    ownerId: jsonString(json, 'ownerId'),
    name: jsonString(json, 'name'),
    species: jsonString(json, 'species'),
    size: jsonString(json, 'size'),
  );
}

final class KennelDto {
  const KennelDto({required this.id, required this.label, required this.size});

  final String id;
  final String label;
  final String size;

  Map<String, Object?> toJson() => {'id': id, 'label': label, 'size': size};

  factory KennelDto.fromJson(Map<String, Object?> json) =>
      KennelDto(id: jsonString(json, 'id'), label: jsonString(json, 'label'), size: jsonString(json, 'size'));
}

final class DayHoursDto {
  const DayHoursDto({required this.weekday, required this.open, required this.close});

  final int weekday;
  final String open;
  final String close;

  Map<String, Object?> toJson() => {'weekday': weekday, 'open': open, 'close': close};

  factory DayHoursDto.fromJson(Map<String, Object?> json) =>
      DayHoursDto(weekday: jsonInt(json, 'weekday'), open: jsonString(json, 'open'), close: jsonString(json, 'close'));
}

final class OpeningHoursDto {
  const OpeningHoursDto({required this.timeZone, required this.days});

  final String timeZone;
  final List<DayHoursDto> days;

  Map<String, Object?> toJson() => {
    'timeZone': timeZone,
    'days': [for (final day in days) day.toJson()],
  };

  factory OpeningHoursDto.fromJson(Map<String, Object?> json) => OpeningHoursDto(
    timeZone: jsonString(json, 'timeZone'),
    days: [for (final day in jsonObjects(json, 'days')) DayHoursDto.fromJson(day)],
  );
}

final class BoardDto {
  const BoardDto({required this.orders, required this.pets, required this.people, required this.kennels});

  final List<OrderDto> orders;
  final List<PetDto> pets;
  final List<UserDto> people;
  final List<KennelDto> kennels;

  Map<String, Object?> toJson() => {
    'orders': [for (final order in orders) order.toJson()],
    'pets': [for (final pet in pets) pet.toJson()],
    'people': [for (final person in people) person.toJson()],
    'kennels': [for (final kennel in kennels) kennel.toJson()],
  };

  factory BoardDto.fromJson(Map<String, Object?> json) => BoardDto(
    orders: [for (final order in jsonObjects(json, 'orders')) OrderDto.fromJson(order)],
    pets: [for (final pet in jsonObjects(json, 'pets')) PetDto.fromJson(pet)],
    people: [for (final person in jsonObjects(json, 'people')) UserDto.fromJson(person)],
    kennels: [for (final kennel in jsonObjects(json, 'kennels')) KennelDto.fromJson(kennel)],
  );
}
