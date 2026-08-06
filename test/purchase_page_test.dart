import 'package:finflow/controllers/financial_month_controller.dart';
import 'package:finflow/features/purchase/pages/purchase_page.dart';
import 'package:finflow/models/financial_entry.dart';
import 'package:finflow/models/financial_month.dart';
import 'package:finflow/shared/financial_month_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('salva as parcelas digitadas e libera uma nova compra', (
    tester,
  ) async {
    final store = MemoryFinancialMonthStore();
    await store.save(
      FinancialMonth(
        year: 2026,
        month: 8,
        entries: const [
          FinancialEntry(
            id: 'card-purchase-page-demo',
            name: 'Cartão de teste',
            amountInCents: 0,
            type: FinancialEntryType.cardInvoice,
            isRecurring: true,
            relatedCardId: 'purchase-page-demo',
            cardBank: 'Banco de teste',
            cardBrand: 'Bandeira de teste',
            cardLimitInCents: 200000,
            cardColor: 0xFF455A64,
            closingDay: 3,
            dueDay: 10,
          ),
          FinancialEntry(
            id: 'card-purchase-page-reserve',
            name: 'Cartão reserva',
            amountInCents: 0,
            type: FinancialEntryType.cardInvoice,
            isRecurring: true,
            relatedCardId: 'purchase-page-reserve',
            cardBank: 'Banco reserva',
            cardBrand: 'Bandeira de teste',
            cardLimitInCents: 100000,
            cardColor: 0xFF1565C0,
            closingDay: 4,
            dueDay: 12,
          ),
        ],
      ),
    );
    final controller = FinancialMonthController(store);
    await controller.initialize(now: DateTime(2026, 8, 5));
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('pt', 'BR'),
        supportedLocales: const [Locale('pt', 'BR')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: PurchasePage(controller: controller),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Adicionar compra'), findsOneWidget);
    final initialAmount = tester.widget<TextField>(
      find.byKey(const ValueKey('purchase-amount')),
    );
    expect(initialAmount.controller!.text, isEmpty);

    await tester.enterText(
      find.byKey(const ValueKey('purchase-description')),
      'Compra de teste',
    );
    await tester.enterText(
      find.byKey(const ValueKey('purchase-amount')),
      '100,01',
    );
    await tester.enterText(
      find.byKey(const ValueKey('purchase-installments')),
      '3',
    );
    await tester.tap(find.byKey(const ValueKey('simulate-purchase')));
    await tester.pumpAndSettle();

    expect(find.textContaining('1/3'), findsOneWidget);
    expect(find.textContaining('3/3'), findsOneWidget);

    final saveOrNewButton = find.byKey(
      const ValueKey('save-or-new-purchase'),
    );
    await tester.scrollUntilVisible(saveOrNewButton, 300);
    await tester.tap(saveOrNewButton);
    await tester.pumpAndSettle();

    expect(controller.purchaseRecords, hasLength(1));
    expect(controller.purchaseRecords.single.entry.installments, 3);
    expect(find.text('Registrar nova compra'), findsOneWidget);

    await tester.scrollUntilVisible(saveOrNewButton, 300);
    await tester.tap(saveOrNewButton);
    await tester.pumpAndSettle();

    final description = tester.widget<TextField>(
      find.byKey(const ValueKey('purchase-description')),
    );
    expect(description.controller!.text, isEmpty);
    expect(find.text('Resultado da simulação'), findsNothing);

    final selectedCard = controller.activeCardInvoices.first;
    await controller.updateEntry(selectedCard.copyWith(isActive: false));
    await tester.pumpAndSettle();

    expect(find.text('Cartão reserva'), findsOneWidget);
  });
}
