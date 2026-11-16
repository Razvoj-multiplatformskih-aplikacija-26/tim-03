import 'package:api_contract/api_contract.dart';
import 'package:relic/relic.dart';

import 'sessions.dart';

Handler buildHandler(SessionHandlers sessions) {
  final signedIn = sessions.signedIn;
  final router = RelicRouter()
    ..get(ApiPaths.health, (request) => Response.ok(body: Body.fromString('ok')))
    ..post(ApiPaths.sessions, sessions.logIn)
    ..get(ApiPaths.currentSession, signedIn(sessions.current))
    ..delete(ApiPaths.currentSession, signedIn(sessions.logOut));
  return const Pipeline().addMiddleware(logRequests()).addHandler(router.asHandler);
}
