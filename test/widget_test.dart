import 'package:finflow/app/app.dart';
import 'package:finflow/controllers/financial_month_controller.dart';
import 'package:finflow/models/financial_entry.dart';
import 'package:finflow/models/financial_month.dart';
import 'package:finflow/shared/financial_month_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('exibe o resumo financeiro de agosto de 2026', (tester) async {
    final store = MemoryFinancialMonthStore();
    await store.save(
      FinancialMonth(
        year: 2026,
        month: 8,
        entries: const [
          FinancialEntry(
            id: 'income-test',
            name: 'Receita de teste',
            amountInCents: 487557,
            type: FinancialEntryType.income,
          ),
          FinancialEntry(
            id: 'expense-test',
            name: 'Despesa de teste',
            amountInCents: 575927,
            type: FinancialEntryType.expense,
          ),
        ],
      ),
    );
    final controller = FinancialMonthController(store);
    await controller.initialize(now: DateTime(2026, 8, 5));
    addTearDown(controller.dispose);

    await tester.pumpWidget(FinFlowApp(financialMonthController: controller));
    await tester.pumpAndSettle();

    expect(find.text('FinFlow'), findsOneWidget);
    expect(find.text('Agosto 2026'), findsOneWidget);
    expect(find.text('Total a pagar'), findsOneWidget);
    expect(find.textContaining('5.759,27'), findsAtLeastNWidgets(1));
    expect(find.textContaining('4.875,57'), findsOneWidget);
    expect(find.text('Falta'), findsOneWidget);
    expect(find.textContaining('883,70'), findsOneWidget);

    final appBar = find.byType(AppBar);
    expect(
      find.descendant(of: appBar, matching: find.text('FinFlow')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: appBar, matching: find.text('Agosto 2026')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: appBar,
        matching: find.byKey(const ValueKey('home-purchase-search')),
      ),
      findsOneWidget,
    );
    expect(find.textContaining('👋'), findsNothing);

    await tester.drag(find.byType(ListView).first, const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: appBar, matching: find.text('Agosto 2026')),
      findsOneWidget,
    );
  });

  testWidgets('dois toques seguidos em Início voltam ao mês atual', (
    tester,
  ) async {
    final store = MemoryFinancialMonthStore();
    final controller = FinancialMonthController(
      store,
      now: () => DateTime(2026, 9, 5),
    );
    await controller.initialize();
    expect(await controller.goToMonth(2026, 8), isTrue);
    addTearDown(controller.dispose);

    await tester.pumpWidget(FinFlowApp(financialMonthController: controller));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cartões'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Início'));
    await tester.pumpAndSettle();
    expect(find.text('Agosto 2026'), findsOneWidget);

    await tester.tap(find.text('Início'));
    await tester.pumpAndSettle();
    expect(find.text('Setembro 2026'), findsOneWidget);
  });

  testWidgets('abre a busca de compras pelo início', (tester) async {
    final controller = FinancialMonthController(MemoryFinancialMonthStore());
    await controller.initialize(now: DateTime(2026, 8, 5));
    addTearDown(controller.dispose);

    await tester.pumpWidget(FinFlowApp(financialMonthController: controller));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('home-purchase-search')));
    await tester.pumpAndSettle();

    expect(find.text('Compra ou mês'), findsOneWidget);
    expect(
      find.text('Busque pelo nome da compra ou por um mês'),
      findsOneWidget,
    );
  });

  testWidgets('mostra o nome de todas as abas e retira Parcelas', (
    tester,
  ) async {
    final controller = FinancialMonthController(MemoryFinancialMonthStore());
    await controller.initialize(now: DateTime(2026, 8, 5));
    addTearDown(controller.dispose);

    await tester.pumpWidget(FinFlowApp(financialMonthController: controller));
    await tester.pumpAndSettle();

    for (final label in [
      'Início',
      'Cartões',
      'Compra',
      'Histórico',
      'Chaves Pix',
      'Mais',
    ]) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.text('Parcelas'), findsNothing);
  });

  testWidgets('adapta a navegação e os recursos para o Windows 11', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;

    final controller = FinancialMonthController(MemoryFinancialMonthStore());
    await controller.initialize(now: DateTime(2026, 8, 5));
    addTearDown(controller.dispose);

    await tester.pumpWidget(FinFlowApp(financialMonthController: controller));
    await tester.pumpAndSettle();

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.byKey(const ValueKey('desktop-finflow-icon')), findsOneWidget);

    await tester.tap(find.text('Mais'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('windows-update-channel')),
      findsOneWidget,
    );
    final updateButton = tester.widget<OutlinedButton>(
      find.byKey(const ValueKey('windows-update-channel')),
    );
    expect(updateButton.onPressed, isNotNull);
    expect(find.text('Verificar atualizações'), findsOneWidget);
    expect(
      find.textContaining('Disponível somente no Android'),
      findsOneWidget,
    );

    debugDefaultTargetPlatformOverride = null;
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  testWidgets('exige duas confirmações antes de apagar todos os dados', (
    tester,
  ) async {
    final controller = FinancialMonthController(MemoryFinancialMonthStore());
    await controller.initialize(now: DateTime(2026, 8, 5));
    addTearDown(controller.dispose);

    await tester.pumpWidget(FinFlowApp(financialMonthController: controller));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Mais'));
    await tester.pumpAndSettle();
    final deleteButton = find.widgetWithText(
      OutlinedButton,
      'Apagar meus dados do FinFlow',
    );
    await tester.scrollUntilVisible(
      deleteButton,
      400,
      scrollable: find.byType(Scrollable).first,
      maxScrolls: 20,
    );
    await tester.pumpAndSettle();
    await tester.tap(deleteButton);
    await tester.pumpAndSettle();

    expect(find.text('Apagar todos os dados do FinFlow?'), findsOneWidget);
    expect(find.textContaining('não pode ser desfeita'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Continuar'));
    await tester.pumpAndSettle();

    final destructiveButton = find.widgetWithText(
      FilledButton,
      'Apagar definitivamente',
    );
    expect(tester.widget<FilledButton>(destructiveButton).onPressed, isNull);
    await tester.enterText(find.byType(TextField), 'APAGAR');
    await tester.pump();
    expect(tester.widget<FilledButton>(destructiveButton).onPressed, isNotNull);

    await tester.tap(find.widgetWithText(TextButton, 'Cancelar'));
    await tester.pumpAndSettle();
    expect(controller.isInitialized, isTrue);
  });
}
