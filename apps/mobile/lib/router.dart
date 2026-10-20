import 'package:domain/domain.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'screens/home_shell.dart';
import 'screens/my_orders_screen.dart';
import 'screens/order_detail_screen.dart';
import 'screens/order_form_screen.dart';
import 'screens/pets_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/orders',
  redirect: (context, state) => state.uri.path == '/' ? '/orders' : null,
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => HomeShell(shell: shell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/orders',
              builder: (context, state) => const MyOrdersScreen(),
              routes: [
                // Listed before ':id', otherwise 'new' would be read as an order id.
                GoRoute(
                  path: 'new',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) {
                    final petId = state.uri.queryParameters['pet'];
                    return OrderFormScreen(initialPetId: petId == null ? null : PetId(petId));
                  },
                ),
                GoRoute(
                  path: ':id',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) => OrderDetailScreen(id: OrderId(state.pathParameters['id']!)),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [GoRoute(path: '/pets', builder: (context, state) => const PetsScreen())],
        ),
      ],
    ),
  ],
);
