import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:ui/ui.dart';

import 'dependencies.dart';
import 'router.dart';

class BackofficeApp extends StatefulWidget {
  const BackofficeApp({super.key, required this.dependencies});

  static const locale = Locale.fromSubtags(languageCode: 'sr', scriptCode: 'Latn');

  final BackofficeDependencies dependencies;

  @override
  State<BackofficeApp> createState() => _BackofficeAppState();
}

class _BackofficeAppState extends State<BackofficeApp> {
  late final SessionBloc _session = SessionBloc(
    restoreSession: widget.dependencies.restoreSession,
    logOut: widget.dependencies.logOut,
    admits: AccessPolicy.canUseBackoffice,
    expirations: widget.dependencies.sessionExpirations,
  )..add(const SessionRestoreRequested());

  @override
  void dispose() {
    _session.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dependencies = widget.dependencies;
    return RepositoryProvider.value(
      value: dependencies,
      child: BlocProvider.value(
        value: _session,
        child: BlocBuilder<SessionBloc, SessionState>(
          builder: (context, session) => switch (session) {
            SessionUnknown() => _material(
              key: const ValueKey('session-unknown'),
              home: Scaffold(
                body: Center(
                  child: Semantics(label: 'Provera prijave', child: const CircularProgressIndicator()),
                ),
              ),
            ),
            SignedOut(:final reason) => _material(
              key: ValueKey('signed-out ${reason?.name}'),
              home: LoginScreen(
                title: 'Šapa · osoblje',
                logIn: dependencies.logIn,
                reason: reason,
                roleNotAllowedMessage: 'Backoffice je za osoblje centra.',
                onSignedIn: (user) => _session.add(SessionStarted(user)),
              ),
            ),
            // A new key for every user, so the board, the selection and the router start over after a new sign-in.
            SignedIn(:final user) => _SignedInApp(key: ValueKey(user.id), staff: user, dependencies: dependencies),
          },
        ),
      ),
    );
  }
}

/// The backoffice of one signed-in staff member: the board acts in their name.
class _SignedInApp extends StatefulWidget {
  const _SignedInApp({super.key, required this.staff, required this.dependencies});

  final User staff;
  final BackofficeDependencies dependencies;

  @override
  State<_SignedInApp> createState() => _SignedInAppState();
}

class _SignedInAppState extends State<_SignedInApp> {
  late final GoRouter _router = createRouter();

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dependencies = widget.dependencies;
    return BlocProvider(
      create: (_) => OrderBoardBloc(
        getCenterBoard: dependencies.getCenterBoard,
        confirmOrder: dependencies.confirmOrder,
        rejectOrder: dependencies.rejectOrder,
        clock: dependencies.clock,
        staff: widget.staff,
      )..add(const OrderBoardRequested()),
      child: _material(router: _router),
    );
  }
}

Widget _material({Key? key, Widget? home, GoRouter? router}) {
  if (router != null) {
    return MaterialApp.router(
      key: key,
      title: 'Šapa · osoblje',
      theme: SapaTheme.light(),
      darkTheme: SapaTheme.dark(),
      themeMode: ThemeMode.system,
      locale: BackofficeApp.locale,
      supportedLocales: const [BackofficeApp.locale],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      routerConfig: router,
    );
  }
  return MaterialApp(
    key: key,
    title: 'Šapa · osoblje',
    theme: SapaTheme.light(),
    darkTheme: SapaTheme.dark(),
    themeMode: ThemeMode.system,
    locale: BackofficeApp.locale,
    supportedLocales: const [BackofficeApp.locale],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    home: home,
  );
}
