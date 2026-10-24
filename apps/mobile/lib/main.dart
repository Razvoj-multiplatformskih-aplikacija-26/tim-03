import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'dependencies.dart';

void main() {
  initializeDomainTimeZones();
  // The only line that picks the implementation of the port.
  runApp(SapaApp(dependencies: AppDependencies.fake()));
}
