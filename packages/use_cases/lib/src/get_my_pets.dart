import 'package:domain/domain.dart';

import 'ports/pet_repository.dart';

final class GetMyPets {
  const GetMyPets({required this.pets});

  final PetRepository pets;

  Future<List<Pet>> call(User owner) => pets.petsOf(owner.id);
}
