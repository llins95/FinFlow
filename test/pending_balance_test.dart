import 'package:finflow/controllers/financial_month_controller.dart';
import 'package:finflow/models/financial_entry.dart';
import 'package:finflow/models/financial_month.dart';
import 'package:finflow/shared/financial_month_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<FinancialMonthController> controllerFor(
    List<FinancialEntry> entries,
  ) async {
    final store = MemoryFinancialMonthStore();
    await store.save(FinancialMonth(year: 2026, month: 8, entries: entries));
    final controller = FinancialMonthController(store);
    addTearDown(controller.dispose);
    await controller.initialize(now: DateTime(2026, 8, 10));
    return controller;
  }

  test('regressão: falta 969,19, sem incluir 4.312,75 já pagos', () async {
    final controller = await controllerFor(const [
      FinancialEntry(
        id: 'income', name: 'Disponível', amountInCents: 13597,
        type: FinancialEntryType.income,
      ),
      FinancialEntry(
        id: 'paid', name: 'Fatura paga', amountInCents: 431275,
        type: FinancialEntryType.cardInvoice, isPaid: true,
      ),
      FinancialEntry(
        id: 'pending', name: 'Pendente', amountInCents: 110516,
        type: FinancialEntryType.expense,
      ),
    ]);

    expect(controller.currentPendingBalanceInCents, -96919);
    expect(controller.currentTotalDebtInCents, 541791);
    expect(controller.currentTotalPaidInCents, 431275);
    expect(controller.currentTotalPendingInCents, 110516);
    expect(controller.currentBalanceInCents, -528194);
    expect(controller.currentMonth.totalAvailableInCents, 13597);

    final pending = controller.currentMonth.entries.last;
    await controller.setEntryPaid(pending, true);
    expect(controller.currentPendingBalanceInCents, 13597);
    expect(controller.currentTotalPendingInCents, 0);
    expect(controller.currentBalanceInCents, -528194);

    await controller.setEntryPaid(pending, false);
    expect(controller.currentPendingBalanceInCents, -96919);
  });

  test('inclui parcelas na fatura pendente e exclui quando paga', () async {
    final controller = await controllerFor([
      const FinancialEntry(
        id: 'income', name: 'Receita', amountInCents: 2000,
        type: FinancialEntryType.income,
      ),
      const FinancialEntry(
        id: 'card', name: 'Cartão', amountInCents: 1000,
        type: FinancialEntryType.cardInvoice, relatedCardId: 'card',
      ),
      FinancialEntry(
        id: 'purchase', name: 'Compra', amountInCents: 3000,
        type: FinancialEntryType.purchase, relatedCardId: 'card',
        installments: 3, purchaseDate: DateTime(2026, 8, 5),
        closingDay: 10, dueDay: 15,
      ),
    ]);
    expect(controller.currentTotalPendingInCents, 2000);
    expect(controller.currentPendingBalanceInCents, 0);

    final card = controller.currentMonth.entries[1];
    await controller.setEntryPaid(card, true);
    expect(controller.currentPendingBalanceInCents, 2000);
    expect(controller.currentTotalPaidInCents, 2000);
    expect(controller.currentBalanceInCents, 0);
  });

  test('sem lançamentos o saldo pendente é zero', () async {
    final controller = await controllerFor([]);
    expect(controller.currentPendingBalanceInCents, 0);
  });

  test('saldo anterior negativo continua incluído', () async {
    final controller = await controllerFor(const [
      FinancialEntry(
        id: 'previous', name: 'Saldo anterior', amountInCents: -500,
        type: FinancialEntryType.previousBalance,
      ),
    ]);
    expect(controller.currentPendingBalanceInCents, -500);
  });
}
