import 'package:api_contract/api_contract.dart';
import 'package:api_mapping/api_mapping.dart';
import 'package:domain/domain.dart';
import 'package:use_cases/use_cases.dart';

import 'api_client.dart';

final class HttpPetRepository implements PetRepository {
  const HttpPetRepository(this._api);

  final ApiClient _api;

  @override
  Future<List<Pet>> petsOf(UserId ownerId) async {
    final answer = await _api.get(ApiPaths.petsOfOwner(ownerId.value));
    return accepted(answer, (json) => [for (final item in objects(json)) PetDto.fromJson(item).toDomain()]);
  }
}
