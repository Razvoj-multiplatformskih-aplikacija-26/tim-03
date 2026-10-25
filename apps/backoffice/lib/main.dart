import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'dependencies.dart';

void main() {
  initializeDomainTimeZones();
  // The only line that picks the implementation of the ports.
  runApp(BackofficeApp(dependencies: BackofficeDependencies.fake()));
}
