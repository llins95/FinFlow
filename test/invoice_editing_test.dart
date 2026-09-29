import 'package:finflow/controllers/financial_month_controller.dart';
import 'package:finflow/features/cards/pages/cards_page.dart';
import 'package:finflow/models/financial_entry.dart';
import 'package:finflow/models/financial_month.dart';
import 'package:finflow/shared/financial_month_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'identifica setembro e edita o total PicPay sem perder parcelas',
    (tester) async {
      final store = MemoryFinancialMonthStore();
      await store.save(
        FinancialMonth(
          year: 2026,
          month: 8,
          entries: [
            const FinancialEntry(
              id: 'card-picpay',
              name: 'PicPay',
              amountInCents: 0,
              type: FinancialEntryType.cardInvoice,
              isRecurring: true,
              relatedCardId: 'picpay',
              cardBank: 'PicPay',
              cardBrand: 'Mastercard',
              cardLimitInCents: 100000,
              closingDay: 3,
              dueDay: 10,
            ),
            FinancialEntry(
              id: 'purchase-picpay',
              name: 'Compra parcelada',
              amountInCents: 3000,
              type: FinancialEntryType.purchase,
              relatedCardId: 'picpay',
              relatedCardName: 'PicPay',
              closingDay: 3,
              dueDay: 10,
              purchaseDate: DateTime(2026, 8, 5),
              installments: 1,
            ),
          ],
        ),
      );
      await store.save(
        FinancialMonth(
          year: 2026,
          month: 9,
          entries: const [
            FinancialEntry(
              id: 'card-picpay',
              name: 'PicPay',
              amountInCents: 10000,
              type: FinancialEntryType.cardInvoice,
              isRecurring: true,
              relatedCardId: 'picpay',
              cardBank: 'PicPay',
              cardBrand: 'Mastercard',
              cardLimitInCents: 100000,
              closingDay: 3,
              dueDay: 10,
            ),
          ],
        ),
      );
      final controller = FinancialMonthController(store);
      addTearDown(controller.dispose);
      await controller.initialize(now: DateTime(2026, 9, 5));

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('pt', 'BR'),
          supportedLocales: const [Locale('pt', 'BR')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: CardsPage(controller: controller),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Fatura de Setembro/2026'), findsOneWidget);
      expect(find.textContaining('130,00'), findsOneWidget);

      await tester.tap(find.byTooltip('Editar fatura'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Editar fatura de Setembro/2026'),
        findsOneWidget,
      );
      expect(
        find.textContaining('compras e parcelas deste mês'),
        findsOneWidget,
      );

      await tester.enterText(find.byType(TextFormField).at(1), '150,00');
      await tester.tap(find.widgetWithText(FilledButton, 'Salvar'));
      await tester.pumpAndSettle();

      final invoice = controller.activeCardInvoices.single;
      expect(invoice.amountInCents, 12000);
      expect(controller.cardInvoiceTotalInCents(invoice), 15000);
      expect(find.textContaining('150,00'), findsOneWidget);
    },
  );
}
