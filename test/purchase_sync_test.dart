import 'package:finflow/controllers/financial_month_controller.dart';
import 'package:finflow/models/financial_entry.dart';
import 'package:finflow/models/financial_month.dart';
import 'package:finflow/models/purchase.dart';
import 'package:finflow/services/finance_service.dart';
import 'package:finflow/shared/financial_month_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('compras sincronizadas no mês financeiro', () {
    late MemoryFinancialMonthStore store;
    late FinancialMonthController controller;

    setUp(() async {
      store = MemoryFinancialMonthStore();
      await store.save(
        FinancialMonth(
          year: 2026,
          month: 8,
          entries: const [
            FinancialEntry(
              id: 'card-demo',
              name: 'Cartão de teste',
              amountInCents: 0,
              type: FinancialEntryType.cardInvoice,
              isRecurring: true,
              relatedCardId: 'demo',
              cardBank: 'Banco de teste',
              cardBrand: 'Bandeira de teste',
              cardLimitInCents: 200000,
              cardColor: 0xFF455A64,
              closingDay: 3,
              dueDay: 10,
            ),
          ],
        ),
      );
      controller = FinancialMonthController(store);
      await controller.initialize(now: DateTime(2026, 8, 5));
    });

    tearDown(() {
      controller.dispose();
    });

    test('salva em centavos sem alterar o total manual da fatura', () async {
      await controller.addPurchase(
        description: 'Compra de teste',
        amountInCents: 10001,
        installments: 3,
        purchaseDate: DateTime(2026, 8, 5),
        cardInvoice: controller.activeCardInvoices.single,
      );

      final record = controller.purchaseRecords.single;
      expect(record.entry.amountInCents, 10001);
      expect(record.entry.relatedCardName, 'Cartão de teste');
      expect(record.entry.cardColor, 0xFF455A64);
      expect(controller.currentMonth.totalDebtInCents, 0);

      final reloaded = await store.load(2026, 8);
      expect(reloaded!.purchases.single.id, record.entry.id);
    });

    test('distribui centavos e agenda pela data de fechamento', () async {
      await controller.addPurchase(
        description: 'Compra parcelada',
        amountInCents: 10001,
        installments: 3,
        purchaseDate: DateTime(2026, 8, 5),
        cardInvoice: controller.activeCardInvoices.single,
      );

      final schedule = FinanceService.scheduledInstallments(
        controller.purchaseRecords,
      );

      expect(schedule.map((item) => item.amountInCents), [3334, 3334, 3333]);
      expect(
        schedule.map((item) => item.amountInCents).reduce((a, b) => a + b),
        10001,
      );
      expect(schedule.first.dueDate, DateTime(2026, 9, 10));
      expect(schedule.last.dueDate, DateTime(2026, 11, 10));
    });

    test('soma cada parcela na fatura do mês correspondente', () async {
      await controller.addPurchase(
        description: 'Compra parcelada na fatura',
        amountInCents: 10001,
        installments: 3,
        purchaseDate: DateTime(2026, 8, 5),
        cardInvoice: controller.activeCardInvoices.single,
      );

      expect(controller.currentTotalDebtInCents, 0);

      await controller.goToNextMonth();
      final septemberInvoice = controller.activeCardInvoices.single;
      expect(controller.cardInvoiceTotalInCents(septemberInvoice), 3334);
      expect(controller.currentTotalDebtInCents, 3334);

      await controller.updateEntry(
        septemberInvoice.copyWith(amountInCents: 5000),
      );
      expect(
        controller.cardInvoiceTotalInCents(
          controller.activeCardInvoices.single,
        ),
        8334,
      );

      await controller.goToNextMonth();
      final octoberInvoice = controller.activeCardInvoices.single;
      expect(controller.cardInvoiceTotalInCents(octoberInvoice), 3334);
      expect(controller.currentTotalDebtInCents, 3334);
    });

    test('mostra no mês atual a compra feita antes do fechamento', () async {
      await controller.addPurchase(
        description: 'Compra antes do fechamento',
        amountInCents: 2500,
        installments: 1,
        purchaseDate: DateTime(2026, 8, 2),
        cardInvoice: controller.activeCardInvoices.single,
      );

      expect(
        controller.cardInvoiceTotalInCents(
          controller.activeCardInvoices.single,
        ),
        2500,
      );
      expect(controller.currentTotalDebtInCents, 2500);
    });

    test('move a compra quando a data muda de mês', () async {
      await controller.addPurchase(
        description: 'Compra móvel',
        amountInCents: 5000,
        installments: 1,
        purchaseDate: DateTime(2026, 8, 5),
        cardInvoice: controller.activeCardInvoices.single,
      );
      final original = controller.purchaseRecords.single;

      await controller.updatePurchase(
        record: original,
        description: 'Compra atualizada',
        amountInCents: 7500,
        installments: 2,
        purchaseDate: DateTime(2026, 9, 6),
        cardInvoice: controller.activeCardInvoices.single,
      );

      final august = await store.load(2026, 8);
      final september = await store.load(2026, 9);
      expect(august!.purchases, isEmpty);
      expect(september!.purchases.single.name, 'Compra atualizada');
      expect(controller.purchaseRecords.single.month.storageKey, '2026-09');
    });

    test('excluir compra remove o histórico e todas as parcelas', () async {
      await controller.addPurchase(
        description: 'Compra lançada por engano',
        amountInCents: 10001,
        installments: 3,
        purchaseDate: DateTime(2026, 8, 5),
        cardInvoice: controller.activeCardInvoices.single,
      );
      final record = controller.purchaseRecords.single;

      await controller.removePurchase(record);

      expect(controller.purchaseRecords, isEmpty);
      await controller.goToNextMonth();
      expect(controller.currentTotalDebtInCents, 0);
    });

    test('não duplica uma notificação já importada', () async {
      const sourceReference = 'wallet-notification-demo';

      await controller.addPurchase(
        description: 'Compra detectada',
        amountInCents: 2590,
        installments: 1,
        purchaseDate: DateTime(2026, 8, 5),
        cardInvoice: controller.activeCardInvoices.single,
        sourceReference: sourceReference,
      );
      await controller.addPurchase(
        description: 'Compra detectada novamente',
        amountInCents: 2590,
        installments: 1,
        purchaseDate: DateTime(2026, 8, 5),
        cardInvoice: controller.activeCardInvoices.single,
        sourceReference: sourceReference,
      );

      expect(controller.purchaseRecords, hasLength(1));
      expect(
        controller.purchaseRecords.single.entry.sourceReference,
        sourceReference,
      );
    });

    test('importa uma compra antiga do Hive somente uma vez', () async {
      final legacy = Purchase(
        id: 'legacy-demo',
        description: 'Compra antiga',
        amount: 42.35,
        cardId: 'demo',
        installments: 2,
        purchaseDate: DateTime(2026, 8, 4),
      );

      expect(await controller.importLegacyPurchases([legacy]), 1);
      expect(await controller.importLegacyPurchases([legacy]), 1);
      expect(controller.purchaseRecords, hasLength(1));
      expect(controller.purchaseRecords.single.entry.amountInCents, 4235);
    });
  });
}
