import 'package:finflow/controllers/financial_month_controller.dart';
import 'package:finflow/features/history/pages/history_page.dart';
import 'package:finflow/models/financial_entry.dart';
import 'package:finflow/models/financial_month.dart';
import 'package:finflow/shared/financial_month_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('exclui uma compra pelo botão do histórico', (tester) async {
    final store = MemoryFinancialMonthStore();
    await store.save(
      FinancialMonth(
        year: 2026,
        month: 8,
        entries: const [
          FinancialEntry(
            id: 'card-test',
            name: 'Cartão de teste',
            amountInCents: 0,
            type: FinancialEntryType.cardInvoice,
            isRecurring: true,
            relatedCardId: 'test',
            closingDay: 5,
            dueDay: 10,
          ),
        ],
      ),
    );
    final controller = FinancialMonthController(store);
    await controller.initialize(now: DateTime(2026, 8, 5));
    addTearDown(controller.dispose);
    await controller.addPurchase(
      description: 'Compra errada',
      amountInCents: 10000,
      installments: 2,
      purchaseDate: DateTime(2026, 8, 5),
      cardInvoice: controller.activeCardInvoices.first,
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('pt', 'BR'),
        supportedLocales: const [Locale('pt', 'BR')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: HistoryPage(controller: controller, onOpenMonth: (_) async {}),
      ),
    );
    await tester.tap(find.text('Compras'));
    await tester.pumpAndSettle();

    final purchaseId = controller.purchaseRecords.single.entry.id;
    await tester.tap(find.byKey(ValueKey('delete-purchase-$purchaseId')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Excluir'));
    await tester.pumpAndSettle();

    expect(controller.purchaseRecords, isEmpty);
    expect(find.text('Nenhuma compra cadastrada.'), findsOneWidget);
  });
}
