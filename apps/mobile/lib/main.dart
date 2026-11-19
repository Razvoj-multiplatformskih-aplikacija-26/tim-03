import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'data/secure_token_store.dart';
import 'dependencies.dart';
import 'server_address.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  initializeDomainTimeZones();
  runApp(
    SapaApp(
      dependencies: AppDependencies.server(baseUri: serverAddress(), tokens: const SecureTokenStore()),
    ),
  );
}
