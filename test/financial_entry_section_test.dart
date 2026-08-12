import 'package:finflow/features/dashboard/widgets/financial_entry_section.dart';
import 'package:finflow/models/financial_entry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('mostra excluir também para receita antiga', (tester) async {
    const salary = FinancialEntry(
      id: 'income-salary',
      name: 'Salário',
      amountInCents: 200000,
      type: FinancialEntryType.income,
    );
    FinancialEntry? deleted;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FinancialEntrySection(
            title: 'Receitas e saldo anterior',
            icon: Icons.savings_outlined,
            entries: const [salary],
            onEdit: (_) {},
            onDelete: (entry) => deleted = entry,
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip('Excluir Salário'));
    expect(deleted, salary);
  });

  testWidgets('mostra PAGO para despesas e permite alternar', (tester) async {
    const expense = FinancialEntry(
      id: 'expense-test',
      name: 'Internet',
      amountInCents: 10000,
      type: FinancialEntryType.expense,
    );
    FinancialEntry? toggled;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FinancialEntrySection(
            title: 'Despesas',
            icon: Icons.receipt_long_outlined,
            entries: const [expense],
            onEdit: (_) {},
            onTogglePaid: (entry) => toggled = entry,
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('paid-toggle-expense-test')));
    expect(toggled, expense);
  });
}
