import 'package:finflow/controllers/financial_month_controller.dart';
import 'package:finflow/models/financial_entry.dart';
import 'package:finflow/models/financial_month.dart';
import 'package:finflow/shared/financial_month_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('mês financeiro', () {
    test('calcula os totais somente a partir dos lançamentos salvos', () {
      final month = _sampleMonth();

      expect(month.totalDebtInCents, 575927);
      expect(month.totalAvailableInCents, 487557);
      expect(month.balanceInCents, -88370);
    });

    test('cria o próximo mês somente com lançamentos recorrentes', () {
      final august = _sampleMonth();
      final september = august.createNextMonth();

      expect(september.year, 2026);
      expect(september.month, 9);

      expect(
        september.entriesOfType(FinancialEntryType.previousBalance),
        isEmpty,
      );

      final invoices = september.entriesOfType(FinancialEntryType.cardInvoice);
      expect(invoices, hasLength(1));
      expect(invoices.every((entry) => entry.amountInCents == 0), isTrue);

      expect(
        september.entries.any((entry) => entry.name == 'Despesa recorrente'),
        isTrue,
      );
      expect(
        september.entries.any((entry) => entry.name == 'Despesa avulsa'),
        isFalse,
      );
    });

    test('salva a atualização de uma fatura', () async {
      final store = MemoryFinancialMonthStore();
      await store.save(_sampleMonth());
      final controller = FinancialMonthController(store);
      await controller.initialize(now: DateTime(2026, 8, 5));

      final picPay = controller.currentMonth.entries.singleWhere(
        (entry) => entry.id == 'card-picpay',
      );
      await controller.updateEntry(picPay.copyWith(amountInCents: 10000));

      final reloaded = await store.load(2026, 8);
      final savedPicPay = reloaded!.entries.singleWhere(
        (entry) => entry.id == 'card-picpay',
      );
      expect(savedPicPay.amountInCents, 10000);
    });

    test('marcar como pago retira somente do total pendente', () async {
      final store = MemoryFinancialMonthStore();
      await store.save(_sampleMonth());
      final controller = FinancialMonthController(store);
      await controller.initialize(now: DateTime(2026, 8, 5));

      final picPay = controller.currentMonth.entries.singleWhere(
        (entry) => entry.id == 'card-picpay',
      );
      final totalBefore = controller.currentTotalDebtInCents;
      await controller.setEntryPaid(picPay, true);

      expect(controller.currentTotalDebtInCents, totalBefore);
      expect(
        controller.currentTotalPendingInCents,
        totalBefore - picPay.amountInCents,
      );
      expect(controller.currentTotalPaidInCents, picPay.amountInCents);

      final saved = await store.load(2026, 8);
      expect(
        saved!.entries.singleWhere((entry) => entry.id == 'card-picpay').isPaid,
        isTrue,
      );
      controller.dispose();
    });

    test('novo mês redefine pagamentos recorrentes como pendentes', () {
      final august = _sampleMonth();
      final paidPicPay = august.entries.singleWhere(
        (entry) => entry.id == 'card-picpay',
      );
      final paidMonth = august.replaceEntry(paidPicPay.copyWith(isPaid: true));

      final september = paidMonth.createNextMonth();

      expect(
        september.entries
            .singleWhere((entry) => entry.id == 'card-picpay')
            .isPaid,
        isFalse,
      );
    });

    test('exclui uma receita antiga, mesmo sem prefixo custom', () async {
      final store = MemoryFinancialMonthStore();
      await store.save(_sampleMonth());
      final controller = FinancialMonthController(store);
      await controller.initialize(now: DateTime(2026, 8, 5));

      await controller.removeEntry('income-salary');

      expect(
        controller.currentMonth.entries.any(
          (entry) => entry.id == 'income-salary',
        ),
        isFalse,
      );
      controller.dispose();
    });

    test('lê meses antigos sem estado de pagamento', () {
      final entry = FinancialEntry.fromMap({
        'id': 'legacy-expense',
        'name': 'Despesa antiga',
        'amountInCents': 1000,
        'type': 'expense',
      });

      expect(entry.isPaid, isFalse);
    });

    test('lista o histórico e reabre um mês salvo', () async {
      final store = MemoryFinancialMonthStore();
      final controller = FinancialMonthController(store);
      await controller.initialize(now: DateTime(2026, 8, 5));

      await controller.goToNextMonth();

      expect(controller.availableMonths.map((month) => month.storageKey), [
        '2026-09',
        '2026-08',
      ]);

      final opened = await controller.goToMonth(2026, 8);

      expect(opened, isTrue);
      expect(controller.currentMonth.storageKey, '2026-08');

      controller.dispose();
    });

    test('preserva a versão do cliente ao serializar', () {
      final timestamp = DateTime.utc(2026, 8, 5, 19, 30);
      final month = FinancialMonth(
        year: 2026,
        month: 8,
        entries: const [],
        clientUpdatedAt: timestamp,
      );

      final restored = FinancialMonth.fromMap(month.toMap());

      expect(restored.clientUpdatedAt, timestamp);
      expect(restored.storageKey, '2026-08');
    });

    test('gera uma versão monotônica mesmo com relógio remoto no futuro', () {
      final remoteTimestamp = DateTime.utc(2026, 9, 15, 12);
      final september = FinancialMonth(
        year: 2026,
        month: 9,
        entries: const [
          FinancialEntry(
            id: 'card-picpay',
            name: 'PicPay',
            amountInCents: 10000,
            type: FinancialEntryType.cardInvoice,
            isRecurring: true,
          ),
        ],
        clientUpdatedAt: remoteTimestamp,
      );

      final edited = september.replaceEntry(
        september.entries.single.copyWith(amountInCents: 25000),
      );

      expect(edited.clientUpdatedAt.isAfter(remoteTimestamp), isTrue);
      expect(edited.entries.single.amountInCents, 25000);
    });
  });
}

FinancialMonth _sampleMonth() {
  return FinancialMonth(
    year: 2026,
    month: 8,
    entries: const [
      FinancialEntry(
        id: 'income-salary',
        name: 'Receita recorrente',
        amountInCents: 487557,
        type: FinancialEntryType.income,
        isRecurring: true,
      ),
      FinancialEntry(
        id: 'card-picpay',
        name: 'PicPay',
        amountInCents: 535927,
        type: FinancialEntryType.cardInvoice,
        isRecurring: true,
        relatedCardId: 'picpay',
      ),
      FinancialEntry(
        id: 'expense-recurring',
        name: 'Despesa recorrente',
        amountInCents: 30000,
        type: FinancialEntryType.expense,
        isRecurring: true,
      ),
      FinancialEntry(
        id: 'expense-once',
        name: 'Despesa avulsa',
        amountInCents: 10000,
        type: FinancialEntryType.expense,
      ),
    ],
  );
}
