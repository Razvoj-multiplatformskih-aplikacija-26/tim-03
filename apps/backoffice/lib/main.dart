import 'package:api_client/api_client.dart';
import 'package:domain/domain.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'data/secure_token_store.dart';
import 'dependencies.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  initializeDomainTimeZones();
  runApp(
    BackofficeApp(
      dependencies: BackofficeDependencies.server(
        baseUri: Uri.parse(const String.fromEnvironment('SERVER_URL', defaultValue: 'http://localhost:8080')),
        // In the browser the server keeps the sign-in in an HttpOnly cookie, out of reach of the page.
        tokens: kIsWeb ? MemoryTokenStore() : const SecureTokenStore(),
      ),
    ),
  );
}
