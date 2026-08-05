import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../controllers/financial_month_controller.dart';
import '../../../models/financial_entry.dart';
import '../../finance/widgets/financial_entry_dialog.dart';
import '../widgets/financial_entry_section.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.controller});

  final FinancialMonthController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final financialMonth = controller.currentMonth;
        final cardInvoices = financialMonth.entriesOfType(
          FinancialEntryType.cardInvoice,
        );
        final expenses = financialMonth.entriesOfType(
          FinancialEntryType.expense,
        );
        final availableEntries = financialMonth.entries
            .where(
              (entry) =>
                  entry.type == FinancialEntryType.income ||
                  entry.type == FinancialEntryType.previousBalance,
            )
            .toList();

        return Scaffold(
          appBar: AppBar(title: const Text('FinFlow')),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              Text(
                '${_greeting()}, Murilo 👋',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _MonthSelector(controller: controller),
              const SizedBox(height: 16),
              _FinancialOverview(controller: controller),
              const SizedBox(height: 24),
              Text(
                'Toque em qualquer valor para atualizar',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              FinancialEntrySection(
                title: 'Faturas dos cartões',
                icon: Icons.credit_card,
                entries: cardInvoices,
                onEdit: (entry) => _editEntry(context, entry),
              ),
              const SizedBox(height: 16),
              FinancialEntrySection(
                title: 'Despesas',
                icon: Icons.receipt_long_outlined,
                entries: expenses,
                onEdit: (entry) => _editEntry(context, entry),
                onAdd: () => _addEntry(
                  context,
                  FinancialEntryType.expense,
                  'Adicionar despesa',
                ),
                onDelete: (entry) => _deleteEntry(context, entry),
              ),
              const SizedBox(height: 16),
              FinancialEntrySection(
                title: 'Receitas e saldo anterior',
                icon: Icons.savings_outlined,
                entries: availableEntries,
                onEdit: (entry) => _editEntry(context, entry),
                onAdd: () => _addEntry(
                  context,
                  FinancialEntryType.income,
                  'Adicionar receita',
                ),
                onDelete: (entry) => _deleteEntry(context, entry),
              ),
            ],
          ),
        );
      },
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Bom dia';
    }
    if (hour < 18) {
      return 'Boa tarde';
    }
    return 'Boa noite';
  }

  Future<void> _editEntry(
    BuildContext context,
    FinancialEntry entry,
  ) async {
    final draft = await FinancialEntryDialog.show(
      context,
      title: 'Atualizar ${entry.name}',
      initialName: entry.name,
      initialAmountInCents: entry.amountInCents,
      initialRecurring: entry.isRecurring,
      allowNameEditing: entry.type != FinancialEntryType.cardInvoice,
      showRecurringOption: entry.type == FinancialEntryType.expense,
      allowNegative: entry.type == FinancialEntryType.previousBalance,
    );

    if (draft == null) {
      return;
    }

    await controller.updateEntry(
      entry.copyWith(
        name: draft.name,
        amountInCents: draft.amountInCents,
        isRecurring: draft.isRecurring,
      ),
    );
  }

  Future<void> _addEntry(
    BuildContext context,
    FinancialEntryType type,
    String title,
  ) async {
    final draft = await FinancialEntryDialog.show(
      context,
      title: title,
      showRecurringOption: true,
    );

    if (draft == null) {
      return;
    }

    await controller.addEntry(
      name: draft.name,
      amountInCents: draft.amountInCents,
      type: type,
      isRecurring: draft.isRecurring,
    );
  }

  Future<void> _deleteEntry(
    BuildContext context,
    FinancialEntry entry,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir lançamento?'),
        content: Text('Deseja excluir “${entry.name}” deste mês?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await controller.removeEntry(entry.id);
    }
  }
}

class _MonthSelector extends StatelessWidget {
  const _MonthSelector({required this.controller});

  final FinancialMonthController controller;

  @override
  Widget build(BuildContext context) {
    final month = controller.currentMonth;
    final formatter = DateFormat('MMMM yyyy', 'pt_BR');
    final label = toBeginningOfSentenceCase(formatter.format(month.date));

    return Card(
      margin: EdgeInsets.zero,
      child: Row(
        children: [
          IconButton(
            onPressed: controller.canGoToPreviousMonth
                ? controller.goToPreviousMonth
                : null,
            tooltip: 'Mês anterior',
            icon: const Icon(Icons.chevron_left),
          ),
          Expanded(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            onPressed: controller.goToNextMonth,
            tooltip: 'Próximo mês',
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}

class _FinancialOverview extends StatelessWidget {
  const _FinancialOverview({required this.controller});

  final FinancialMonthController controller;

  @override
  Widget build(BuildContext context) {
    final month = controller.currentMonth;
    final currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final hasSurplus = month.balanceInCents >= 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth >= 760
            ? (constraints.maxWidth - 24) / 3
            : constraints.maxWidth;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _SummaryCard(
              width: cardWidth,
              label: 'Total a pagar',
              value: currency.format(month.totalDebtInCents / 100),
              icon: Icons.arrow_upward_rounded,
              color: Colors.orange,
            ),
            _SummaryCard(
              width: cardWidth,
              label: 'Total disponível',
              value: currency.format(month.totalAvailableInCents / 100),
              icon: Icons.arrow_downward_rounded,
              color: Colors.blue,
            ),
            _SummaryCard(
              width: cardWidth,
              label: hasSurplus ? 'Sobra' : 'Falta',
              value: currency.format(month.balanceInCents.abs() / 100),
              icon: hasSurplus
                  ? Icons.check_circle_outline
                  : Icons.error_outline,
              color: hasSurplus ? Colors.green : Colors.redAccent,
            ),
          ],
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.width,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final double width;
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.15),
                foregroundColor: color,
                child: Icon(icon),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
