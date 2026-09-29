import 'package:finflow/controllers/financial_month_controller.dart';
import 'package:finflow/features/dashboard/pages/home_page.dart';
import 'package:finflow/features/history/pages/history_page.dart';
import 'package:finflow/models/financial_entry.dart';
import 'package:finflow/models/financial_month.dart';
import 'package:finflow/shared/financial_month_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<FinancialMonthController> buildController() async {
    final store = MemoryFinancialMonthStore();
    await store.save(
      FinancialMonth(
        year: 2026,
        month: 8,
        entries: const [
          FinancialEntry(
            id: 'income',
            name: 'Salário',
            amountInCents: 10000,
            type: FinancialEntryType.income,
          ),
          FinancialEntry(
            id: 'previous-balance',
            name: 'Saldo de julho',
            amountInCents: 1500,
            type: FinancialEntryType.previousBalance,
          ),
          FinancialEntry(
            id: 'expense-pending',
            name: 'Conta de luz',
            amountInCents: 8000,
            type: FinancialEntryType.expense,
          ),
          FinancialEntry(
            id: 'expense-paid',
            name: 'Internet',
            amountInCents: 4000,
            type: FinancialEntryType.expense,
            isPaid: true,
          ),
        ],
      ),
    );
    final controller = FinancialMonthController(store);
    await controller.initialize(now: DateTime(2026, 8, 10));
    return controller;
  }

  Widget app(Widget home) {
    return MaterialApp(
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: home,
    );
  }

  testWidgets('mostra o que compõe o total a pagar na tela Início', (
    tester,
  ) async {
    final controller = await buildController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(app(HomePage(controller: controller)));
    await tester.tap(find.byKey(const ValueKey('home-payable-details')));
    await tester.pumpAndSettle();

    expect(find.text('O que compõe o total a pagar?'), findsOneWidget);
    expect(find.text('Pendências incluídas'), findsOneWidget);
    expect(find.text('Conta de luz'), findsWidgets);
  });

  testWidgets('mostra o que compõe o total disponível na tela Início', (
    tester,
  ) async {
    final controller = await buildController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(app(HomePage(controller: controller)));
    await tester.tap(find.byKey(const ValueKey('home-available-details')));
    await tester.pumpAndSettle();

    expect(find.text('O que compõe o total disponível?'), findsOneWidget);
    expect(find.text('Valores incluídos'), findsOneWidget);
    expect(find.text('Salário'), findsWidgets);
    expect(find.text('Saldo de julho'), findsWidgets);
  });

  testWidgets('mostra sobra sem descontar pagamentos na tela Início', (tester) async {
    final controller = await buildController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(app(HomePage(controller: controller)));
    await tester.tap(find.byKey(const ValueKey('home-balance-details')));
    await tester.pumpAndSettle();

    expect(find.text('Detalhes da sobra'), findsOneWidget);
    expect(find.text('Conta de luz'), findsWidgets);
    final dialog = find.byType(AlertDialog);
    expect(find.descendant(of: dialog, matching: find.text('Internet')), findsNothing);
    expect(find.text('Pendências incluídas'), findsOneWidget);
    expect(controller.currentPendingBalanceInCents, 3500);
  });

  testWidgets('mostra sobra sem descontar pagamentos no Histórico', (tester) async {
    final controller = await buildController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      app(HistoryPage(controller: controller, onOpenMonth: (_) async {})),
    );
    final key = ValueKey(
      'history-balance-details-${controller.currentMonth.storageKey}',
    );
    await tester.tap(find.byKey(key));
    await tester.pumpAndSettle();

    expect(find.text('Detalhes da sobra'), findsOneWidget);
    expect(find.text('Conta de luz'), findsWidgets);
    final dialog = find.byType(AlertDialog);
    expect(find.descendant(of: dialog, matching: find.text('Internet')), findsNothing);
    expect(controller.pendingBalanceInCentsForMonth(controller.currentMonth), 3500);
  });
}
