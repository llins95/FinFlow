import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app_theme.dart';
import 'navigation_page.dart';

class FinFlowApp extends StatelessWidget {
  const FinFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FinFlow',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,

      locale: const Locale('pt', 'BR'),

      supportedLocales: const [Locale('pt', 'BR')],

      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      home: const NavigationPage(),
    );
  }
}
