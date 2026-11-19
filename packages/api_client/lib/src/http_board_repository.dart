import 'package:api_contract/api_contract.dart';
import 'package:api_mapping/api_mapping.dart';
import 'package:use_cases/use_cases.dart';

import 'api_client.dart';

final class HttpBoardRepository implements BoardRepository {
  const HttpBoardRepository(this._api);

  final ApiClient _api;

  @override
  Future<CenterBoard> board() async {
    final answer = await _api.get(ApiPaths.board);
    return accepted(answer, (json) => BoardDto.fromJson(object(json)).toDomain());
  }
}
