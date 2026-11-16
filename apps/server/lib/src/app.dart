import 'package:api_contract/api_contract.dart';
import 'package:relic/relic.dart';

import 'cors.dart';
import 'handlers.dart';
import 'http.dart';
import 'sessions.dart';

Handler buildHandler(CenterHandlers handlers, SessionHandlers sessions, {required List<String> corsOrigins}) {
  final signedIn = sessions.signedIn;
  final router = RelicRouter()
    ..get(ApiPaths.health, (request) => Response.ok(body: Body.fromString('ok')))
    ..get(ApiPaths.openingHours, handlers.openingHours)
    ..post(ApiPaths.sessions, sessions.logIn)
    ..get(ApiPaths.currentSession, signedIn(sessions.current))
    ..delete(ApiPaths.currentSession, signedIn(sessions.logOut))
    ..get(ApiPaths.board, signedIn(handlers.board))
    ..get(ApiPaths.ordersOfOwner(':ownerId'), signedIn(handlers.ordersOfOwner))
    ..get(ApiPaths.petsOfOwner(':ownerId'), signedIn(handlers.petsOfOwner))
    ..get(ApiPaths.order(':id'), signedIn(handlers.find))
    ..post(ApiPaths.orders, signedIn(handlers.create))
    ..post(ApiPaths.confirmation(':id'), signedIn(handlers.confirm))
    ..post(ApiPaths.rejection(':id'), signedIn(handlers.reject))
    ..post(ApiPaths.cancellation(':id'), signedIn(handlers.cancel))
    ..fallback = respondWith((request) => problemResponse(notFoundRoute));
  // Middleware added with use() runs only when a route exists; in the Pipeline it runs for every call, 404 included.
  return const Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(allowOrigins(corsOrigins))
      .addMiddleware(handleErrors())
      .addHandler(router.asHandler);
}

const notFoundRoute = ProblemDto(status: 404, code: ErrorCodes.notFound, title: 'No such route');
