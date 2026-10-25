import 'package:blocs/blocs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:ui/ui.dart';
import 'package:use_cases/use_cases.dart';

import 'dependencies.dart';
import 'router.dart';

class SapaApp extends StatelessWidget {
  const SapaApp({super.key, required this.dependencies});

  static const locale = Locale.fromSubtags(languageCode: 'sr', scriptCode: 'Latn');

  final AppDependencies dependencies;

  @override
  Widget build(BuildContext context) {
    // Above the router, so every screen and dialog of the orders sees the same bloc.
    return RepositoryProvider.value(
      value: dependencies,
      child: BlocProvider(
        create: (_) => MyOrdersBloc(
          getMyOrders: GetMyOrders(orders: dependencies.orders),
          cancelOrder: CancelOrder(orders: dependencies.orders, clock: dependencies.clock),
          clock: dependencies.clock,
          owner: dependencies.owner,
        )..add(const MyOrdersRequested()),
        child: MaterialApp.router(
          title: 'Šapa',
          theme: SapaTheme.light(),
          darkTheme: SapaTheme.dark(),
          themeMode: ThemeMode.system,
          locale: locale,
          supportedLocales: const [locale],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          routerConfig: router,
        ),
      ),
    );
  }
}
