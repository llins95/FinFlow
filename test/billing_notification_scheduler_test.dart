import 'package:finflow/models/financial_entry.dart';
import 'package:finflow/models/financial_month.dart';
import 'package:finflow/services/billing_notification_scheduler.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const planner = BillingReminderPlanner(monthsAhead: 1);

  test('agenda fechamento no dia e vencimento no dia anterior', () {
    final month = FinancialMonth(
      year: 2026,
      month: 8,
      entries: const [
        FinancialEntry(
          id: 'card-test',
          name: 'Cartão Teste',
          amountInCents: 10000,
          type: FinancialEntryType.cardInvoice,
          isRecurring: true,
          closingDay: 15,
          dueDay: 20,
        ),
        FinancialEntry(
          id: 'expense-test',
          name: 'Internet',
          amountInCents: 10000,
          type: FinancialEntryType.expense,
          dueDay: 12,
        ),
      ],
    );

    final reminders = planner.plan(
      currentMonth: month,
      now: DateTime(2026, 8, 10, 8),
    );

    expect(reminders, hasLength(3));
    expect(
      reminders
          .singleWhere(
            (item) => item.kind == BillingReminderKind.invoiceClosing,
          )
          .scheduledDate,
      DateTime(2026, 8, 15, 9),
    );
    expect(
      reminders
          .singleWhere(
            (item) =>
                item.entryId == 'card-test' &&
                item.kind == BillingReminderKind.dueTomorrow,
          )
          .scheduledDate,
      DateTime(2026, 8, 19, 9),
    );
    expect(
      reminders
          .singleWhere((item) => item.entryId == 'expense-test')
          .scheduledDate,
      DateTime(2026, 8, 11, 9),
    );
  });

  test('não agenda despesa ou fatura já paga', () {
    final month = FinancialMonth(
      year: 2026,
      month: 8,
      entries: const [
        FinancialEntry(
          id: 'paid-card',
          name: 'Cartão pago',
          amountInCents: 10000,
          type: FinancialEntryType.cardInvoice,
          closingDay: 15,
          dueDay: 20,
          isPaid: true,
        ),
        FinancialEntry(
          id: 'paid-expense',
          name: 'Despesa paga',
          amountInCents: 5000,
          type: FinancialEntryType.expense,
          dueDay: 18,
          isPaid: true,
        ),
      ],
    );

    final reminders = planner.plan(
      currentMonth: month,
      now: DateTime(2026, 8, 10),
    );

    expect(reminders, isEmpty);
  });

  test('mantém lembretes futuros somente para itens recorrentes ativos', () {
    const futurePlanner = BillingReminderPlanner(monthsAhead: 2);
    final month = FinancialMonth(
      year: 2026,
      month: 8,
      entries: const [
        FinancialEntry(
          id: 'recurring-expense',
          name: 'Internet',
          amountInCents: 10000,
          type: FinancialEntryType.expense,
          dueDay: 12,
          isRecurring: true,
        ),
        FinancialEntry(
          id: 'single-expense',
          name: 'Consulta',
          amountInCents: 5000,
          type: FinancialEntryType.expense,
          dueDay: 18,
        ),
      ],
    );

    final reminders = futurePlanner.plan(
      currentMonth: month,
      now: DateTime(2026, 8, 1),
    );

    expect(
      reminders.where((item) => item.entryId == 'recurring-expense'),
      hasLength(2),
    );
    expect(
      reminders.where((item) => item.entryId == 'single-expense'),
      hasLength(1),
    );
  });
}
