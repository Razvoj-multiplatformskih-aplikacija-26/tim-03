import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:ui/ui.dart';

class BackofficeApp extends StatelessWidget {
  const BackofficeApp({super.key});

  static const locale = Locale.fromSubtags(languageCode: 'sr', scriptCode: 'Latn');

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Šapa · osoblje',
      theme: SapaTheme.light(),
      darkTheme: SapaTheme.dark(),
      themeMode: ThemeMode.system,
      locale: locale,
      supportedLocales: const [locale],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: const Scaffold(body: Center(child: Text('Nalozi centra'))),
    );
  }
}
