import 'package:api_contract/api_contract.dart';
import 'package:use_cases/use_cases.dart';

import 'center_mapping.dart';
import 'order_mapping.dart';

extension CenterBoardMapping on CenterBoard {
  BoardDto toDto() => BoardDto(
    orders: [for (final order in orders) order.toDto()],
    pets: [for (final pet in pets.values) pet.toDto()],
    people: [for (final person in people.values) person.toDto()],
    kennels: [for (final kennel in kennels) kennel.toDto()],
  );
}

extension BoardDtoMapping on BoardDto {
  CenterBoard toDomain() => CenterBoard(
    orders: [for (final order in orders) order.toDomain()],
    pets: {for (final pet in pets.map((dto) => dto.toDomain())) pet.id: pet},
    people: {for (final person in people.map((dto) => dto.toDomain())) person.id: person},
    kennels: [for (final kennel in kennels) kennel.toDomain()],
  );
}
