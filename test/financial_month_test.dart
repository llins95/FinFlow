import 'package:finflow/controllers/financial_month_controller.dart';
import 'package:finflow/models/financial_entry.dart';
import 'package:finflow/shared/financial_month_repository.dart';
import 'package:finflow/shared/initial_financial_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('mês financeiro inicial', () {
    test('reproduz os totais da planilha de agosto de 2026', () {
      final month = buildInitialFinancialMonth();

      expect(month.totalDebtInCents, 575927);
      expect(month.totalAvailableInCents, 487557);
      expect(month.balanceInCents, -88370);
    });

    test('cria o próximo mês com recorrentes e saldo anterior', () {
      final august = buildInitialFinancialMonth();
      final september = august.createNextMonth();

      expect(september.year, 2026);
      expect(september.month, 9);

      final previousBalance = september.entries.singleWhere(
        (entry) => entry.type == FinancialEntryType.previousBalance,
      );
      expect(previousBalance.amountInCents, -88370);

      final invoices = september.entriesOfType(
        FinancialEntryType.cardInvoice,
      );
      expect(invoices, hasLength(8));
      expect(invoices.every((entry) => entry.amountInCents == 0), isTrue);

      expect(
        september.entries.any((entry) => entry.name == 'Energisa'),
        isTrue,
      );
      expect(
        september.entries.any((entry) => entry.name == 'Tomografia Alícia'),
        isFalse,
      );
    });

    test('salva a atualização de uma fatura', () async {
      final store = MemoryFinancialMonthStore();
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
  });
}
