import 'package:blocs/blocs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ui/ui.dart';
import 'package:use_cases/use_cases.dart';

import '../dependencies.dart';

/// Every screen of the app is personal, so signing in is the way in. The router leaves this screen on its own
/// once the session is SignedIn.
class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.read<SessionBloc>();
    return BlocBuilder<SessionBloc, SessionState>(
      builder: (context, state) => LoginScreen(
        title: 'Šapa',
        logIn: LogIn(sessions: context.read<AppDependencies>().sessions),
        reason: switch (state) {
          SignedOut(:final reason) => reason,
          SessionUnknown() || SignedIn() => null,
        },
        roleNotAllowedMessage: 'Aplikacija je za vlasnike ljubimaca. Osoblje koristi backoffice.',
        onSignedIn: (user) => session.add(SessionStarted(user)),
      ),
    );
  }
}

/// Shown while the saved sign-in is checked at start, before the router knows where to go.
class SessionCheckScreen extends StatelessWidget {
  const SessionCheckScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Semantics(label: 'Provera prijave', child: const CircularProgressIndicator()),
    ),
  );
}
