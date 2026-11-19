import 'dart:async';

import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:use_cases/use_cases.dart';

import 'dependencies.dart';
import 'screens/home_shell.dart';
import 'screens/my_orders_screen.dart';
import 'screens/order_detail_screen.dart';
import 'screens/order_form_screen.dart';
import 'screens/pets_screen.dart';
import 'screens/sign_in_screen.dart';

/// Tells the router to ask [GoRouter.redirect] again whenever the session changes.
final class SessionChanges extends ChangeNotifier {
  SessionChanges(Stream<SessionState> session) {
    _subscription = session.listen((_) => notifyListeners());
  }

  late final StreamSubscription<SessionState> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

/// Signing in is the way into the app: without SignedIn every path leads to /login.
GoRouter createRouter(SessionBloc session, {required Listenable sessionChanges}) {
  final rootNavigatorKey = GlobalKey<NavigatorState>();
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/orders',
    refreshListenable: sessionChanges,
    redirect: (context, state) {
      final path = state.uri.path;
      return switch (session.state) {
        SessionUnknown() => path == '/start' ? null : '/start',
        SignedOut() => path == '/login' ? null : '/login',
        SignedIn() => path == '/' || path == '/start' || path == '/login' ? '/orders' : null,
      };
    },
    routes: _routes(rootNavigatorKey),
  );
}

List<RouteBase> _routes(GlobalKey<NavigatorState> rootNavigatorKey) => [
  GoRoute(path: '/start', builder: (context, state) => const SessionCheckScreen()),
  GoRoute(path: '/login', builder: (context, state) => const SignInScreen()),
  StatefulShellRoute.indexedStack(
    builder: (context, state, shell) => HomeShell(shell: shell),
    branches: [
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: '/orders',
            builder: (context, state) => const MyOrdersScreen(),
            routes: [
              GoRoute(
                path: 'new',
                parentNavigatorKey: rootNavigatorKey,
                builder: (context, state) {
                  final petId = state.uri.queryParameters['pet'];
                  final dependencies = context.read<AppDependencies>();
                  return BlocProvider(
                    create: (_) => OrderFormBloc(
                      placeOrder: PlaceOrder(orders: dependencies.orders),
                      getMyPets: GetMyPets(pets: dependencies.pets),
                      getOpeningHours: GetOpeningHours(center: dependencies.center),
                      // The router lets this route open only while the session is SignedIn.
                      owner: (context.read<SessionBloc>().state as SignedIn).user,
                    )..add(const OrderFormStarted()),
                    child: OrderFormScreen(initialPetId: petId == null ? null : PetId(petId)),
                  );
                },
              ),
              GoRoute(
                path: ':id',
                parentNavigatorKey: rootNavigatorKey,
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
];
