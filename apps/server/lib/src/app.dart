import 'package:api_contract/api_contract.dart';
import 'package:relic/relic.dart';

Handler buildHandler() {
  final router = RelicRouter()..get(ApiPaths.health, (request) => Response.ok(body: Body.fromString('ok')));
  return const Pipeline().addMiddleware(logRequests()).addHandler(router.asHandler);
}
