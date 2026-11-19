import 'package:api_contract/api_contract.dart';
import 'package:api_mapping/api_mapping.dart';
import 'package:domain/domain.dart';
import 'package:use_cases/use_cases.dart';

import 'api_client.dart';

final class HttpCenterRepository implements CenterRepository {
  const HttpCenterRepository(this._api);

  final ApiClient _api;

  @override
  Future<OpeningHours> openingHours() async {
    final answer = await _api.get(ApiPaths.openingHours);
    return accepted(answer, (json) => OpeningHoursDto.fromJson(object(json)).toDomain());
  }
}
