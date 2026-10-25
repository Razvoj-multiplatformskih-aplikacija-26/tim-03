import 'package:blocs/blocs.dart';
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
  late final GoRouter _router = createRouter();

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dependencies = widget.dependencies;
    // Above the router, so the screen and its dialogs see the same bloc.
    return BlocProvider(
      create: (_) => OrderBoardBloc(
        getCenterBoard: dependencies.getCenterBoard,
        confirmOrder: dependencies.confirmOrder,
        rejectOrder: dependencies.rejectOrder,
        clock: dependencies.clock,
        staff: dependencies.staff,
      )..add(const OrderBoardRequested()),
      child: MaterialApp.router(
        title: 'Šapa · osoblje',
        theme: SapaTheme.light(),
        darkTheme: SapaTheme.dark(),
        themeMode: ThemeMode.system,
        locale: BackofficeApp.locale,
        supportedLocales: const [BackofficeApp.locale],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        routerConfig: _router,
      ),
    );
  }
}
