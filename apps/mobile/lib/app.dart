import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'router.dart';
import 'theme/theme.dart';

class SapaApp extends StatelessWidget {
  const SapaApp({super.key});

  static const locale = Locale.fromSubtags(languageCode: 'sr', scriptCode: 'Latn');

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Šapa',
      theme: SapaTheme.light(),
      darkTheme: SapaTheme.dark(),
      themeMode: ThemeMode.system,
      locale: locale,
      supportedLocales: const [locale],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      routerConfig: router,
    );
  }
}
