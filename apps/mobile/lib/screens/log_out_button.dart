import 'package:blocs/blocs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Signs out: SessionBloc deletes the token on the server and on the device, and the router goes to /login,
/// which then says „Odjavili ste se.“
class LogOutButton extends StatelessWidget {
  const LogOutButton({super.key});

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: 'Odjavi se',
    icon: const Icon(Icons.logout),
    onPressed: () => context.read<SessionBloc>().add(const SessionLogOutRequested()),
  );
}
