import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../controllers/financial_month_controller.dart';
import '../shared/financial_month_repository.dart';
import 'app_theme.dart';
import 'navigation_page.dart';

class FinFlowApp extends StatefulWidget {
  const FinFlowApp({super.key, this.financialMonthController});

  final FinancialMonthController? financialMonthController;

  @override
  State<FinFlowApp> createState() => _FinFlowAppState();
}

class _FinFlowAppState extends State<FinFlowApp> {
  late final FinancialMonthController controller;
  late final bool ownsController;

  @override
  void initState() {
    super.initState();
    ownsController = widget.financialMonthController == null;
    controller =
        widget.financialMonthController ??
        FinancialMonthController(HiveFinancialMonthStore());
    controller.initialize();
  }

  @override
  void dispose() {
    if (ownsController) {
      controller.dispose();
    }
    super.dispose();
  }

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
      home: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          if (!controller.isInitialized) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          return NavigationPage(controller: controller);
        },
      ),
    );
  }
}
