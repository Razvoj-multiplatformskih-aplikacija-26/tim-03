import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:ui/ui.dart';
import 'package:use_cases/use_cases.dart';

import 'dependencies.dart';
import 'router.dart';

class SapaApp extends StatefulWidget {
  const SapaApp({super.key, required this.dependencies});

  static const locale = Locale.fromSubtags(languageCode: 'sr', scriptCode: 'Latn');

  final AppDependencies dependencies;

  @override
  State<SapaApp> createState() => _SapaAppState();
}

class _SapaAppState extends State<SapaApp> {
  late final AppDependencies _dependencies = widget.dependencies;
  late final SessionBloc _session = SessionBloc(
    restoreSession: RestoreSession(sessions: _dependencies.sessions),
    logOut: LogOut(sessions: _dependencies.sessions),
    admits: AccessPolicy.canUseMobile,
    expirations: _dependencies.sessions.expirations,
  )..add(const SessionRestoreRequested());
  late final MyOrdersBloc _orders = MyOrdersBloc(
    getMyOrders: GetMyOrders(orders: _dependencies.orders),
    getMyPets: GetMyPets(pets: _dependencies.pets),
    cancelOrder: CancelOrder(orders: _dependencies.orders, clock: _dependencies.clock),
    clock: _dependencies.clock,
  );
  late final SessionChanges _sessionChanges = SessionChanges(_session.stream);
  late final GoRouter _router = createRouter(_session, sessionChanges: _sessionChanges);

  @override
  void dispose() {
    _router.dispose();
    _sessionChanges.dispose();
    _orders.close();
    _session.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider.value(
      value: _dependencies,
      child: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: _session),
          BlocProvider.value(value: _orders),
        ],
        // The session tells MyOrdersBloc whose orders to show: blocs talk through the presentation layer (V6).
        child: BlocListener<SessionBloc, SessionState>(
          listenWhen: (previous, current) => current is! SessionUnknown,
          listener: (context, session) => _orders.add(
            MyOrdersOwnerChanged(switch (session) {
              SignedIn(:final user) => user,
              SignedOut() || SessionUnknown() => null,
            }),
          ),
          child: MaterialApp.router(
            title: 'Šapa',
            theme: SapaTheme.light(),
            darkTheme: SapaTheme.dark(),
            themeMode: ThemeMode.system,
            locale: SapaApp.locale,
            supportedLocales: const [SapaApp.locale],
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            routerConfig: _router,
          ),
        ),
      ),
    );
  }
}
