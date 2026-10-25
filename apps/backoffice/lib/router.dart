import 'package:go_router/go_router.dart';

import 'screens/orders_screen.dart';

GoRouter createRouter() => GoRouter(
  initialLocation: '/',
  routes: [GoRoute(path: '/', builder: (context, state) => const OrdersScreen())],
);
