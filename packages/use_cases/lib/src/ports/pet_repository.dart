import 'package:domain/domain.dart';

abstract interface class PetRepository {
  Future<List<Pet>> petsOf(UserId ownerId);
}
