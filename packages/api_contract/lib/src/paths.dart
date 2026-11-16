abstract final class ApiPaths {
  static const health = '/health';
  static const openingHours = '/api/v1/opening-hours';
  static const orders = '/api/v1/orders';
  static const board = '/api/v1/board';
  static const sessions = '/api/v1/sessions';
  static const currentSession = '/api/v1/sessions/current';

  static String order(String id) => '$orders/$id';

  static String confirmation(String id) => '${order(id)}/confirmation';

  static String rejection(String id) => '${order(id)}/rejection';

  static String cancellation(String id) => '${order(id)}/cancellation';

  static String ordersOfOwner(String ownerId) => '/api/v1/owners/$ownerId/orders';

  static String petsOfOwner(String ownerId) => '/api/v1/owners/$ownerId/pets';
}

abstract final class ApiQuery {
  static const from = 'from';
}

abstract final class ApiCookies {
  static const session = 'sapa_session';
}
