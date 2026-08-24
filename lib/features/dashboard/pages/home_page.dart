import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../controllers/financial_month_controller.dart';
import '../../../models/financial_entry.dart';
import '../../../shared/balance_details_dialog.dart';
import '../../finance/widgets/financial_entry_dialog.dart';
import 'purchase_search_page.dart';
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
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${_greeting()} 👋',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton.filledTonal(
                    key: const ValueKey('home-purchase-search'),
                    onPressed: () =>
                        showPurchaseSearch(context, controller.purchaseRecords),
                    tooltip: 'Buscar compra ou mês',
                    icon: const Icon(FluentIcons.search_24_regular),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _MonthSelector(controller: controller),
              const SizedBox(height: 16),
              _FinancialOverview(controller: controller),
              const SizedBox(height: 16),
              _DashboardDetails(controller: controller),
              const SizedBox(height: 24),
              Text(
                'Toque em qualquer valor para atualizar',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              FinancialEntrySection(
                title:
                    'Faturas dos cartões — ${_monthLabel(financialMonth.date)}',
                icon: Icons.credit_card,
                entries: cardInvoices,
                amountInCentsFor: controller.cardInvoiceTotalInCents,
                onEdit: (entry) => _editEntry(context, entry),
                onTogglePaid: _togglePaid,
              ),
              const SizedBox(height: 16),
              FinancialEntrySection(
                title: 'Despesas',
                icon: Icons.receipt_long_outlined,
                entries: expenses,
                onEdit: (entry) => _editEntry(context, entry),
                onTogglePaid: _togglePaid,
                onAdd: () => _addEntry(
                  context,
                  FinancialEntryType.expense,
                  'Adicionar despesa',
                ),
                onDelete: (entry) => _deleteEntry(context, entry),
              ),
              const SizedBox(height: 16),
              if (controller.canGoToPreviousMonth) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: () => _carryPreviousBalance(context),
                    icon: const Icon(Icons.savings_outlined),
                    label: Text(
                      controller.hasPreviousBalanceTransfer
                          ? 'Atualizar saldo do mês anterior'
                          : 'Adicionar saldo do mês anterior',
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
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

  Future<void> _editEntry(BuildContext context, FinancialEntry entry) async {
    final isCardInvoice = entry.type == FinancialEntryType.cardInvoice;
    final automaticAmount = isCardInvoice
        ? controller.purchaseInstallmentsForCardInMonth(
            entry,
            controller.currentMonth.date,
          )
        : 0;
    final draft = await FinancialEntryDialog.show(
      context,
      title: isCardInvoice
          ? 'Editar fatura de ${_monthLabel(controller.currentMonth.date)} '
                '• ${entry.name}'
          : 'Atualizar ${entry.name}',
      initialName: entry.name,
      initialAmountInCents: entry.amountInCents + automaticAmount,
      initialRecurring: entry.isRecurring,
      initialRecurrenceEndMonth: entry.recurrenceEndMonth,
      recurrenceStartMonth: controller.currentMonth.date,
      initialDueDay: entry.dueDay,
      allowNameEditing: !isCardInvoice,
      showRecurringOption:
          entry.type == FinancialEntryType.expense ||
          entry.type == FinancialEntryType.income,
      showDueDay: entry.type == FinancialEntryType.expense,
      allowNegative: entry.type == FinancialEntryType.previousBalance,
      amountLabel: isCardInvoice ? 'Total da fatura' : 'Valor',
      amountHelperText: isCardInvoice && automaticAmount > 0
          ? 'O total já inclui as compras e parcelas deste mês.'
          : null,
      minimumAmountInCents: isCardInvoice ? automaticAmount : null,
    );

    if (draft == null) {
      return;
    }

    await controller.updateEntry(
      entry.copyWith(
        name: draft.name,
        amountInCents: draft.amountInCents - automaticAmount,
        isRecurring: draft.isRecurring,
        recurrenceEndMonth: draft.recurrenceEndMonth,
        dueDay: draft.dueDay,
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
      showDueDay: type == FinancialEntryType.expense,
      recurrenceStartMonth: controller.currentMonth.date,
    );

    if (draft == null) {
      return;
    }

    await controller.addEntry(
      name: draft.name,
      amountInCents: draft.amountInCents,
      type: type,
      isRecurring: draft.isRecurring,
      recurrenceEndMonth: draft.recurrenceEndMonth,
      dueDay: draft.dueDay,
    );
  }

  Future<void> _deleteEntry(BuildContext context, FinancialEntry entry) async {
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

  Future<void> _togglePaid(FinancialEntry entry) {
    return controller.setEntryPaid(entry, !entry.isPaid);
  }

  Future<void> _carryPreviousBalance(BuildContext context) async {
    final updated = await controller.carryPreviousMonthBalance();
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          updated
              ? 'Saldo do mês anterior adicionado sem duplicação.'
              : 'Não foi possível localizar o mês anterior.',
        ),
      ),
    );
  }

  String _monthLabel(DateTime month) {
    final formatted = DateFormat('MMMM/yyyy', 'pt_BR').format(month);
    return toBeginningOfSentenceCase(formatted);
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
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            onPressed: controller.canGoToNextMonth
                ? controller.goToNextMonth
                : null,
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
    final totalDebtInCents = controller.currentTotalPendingInCents;
    final balanceInCents = controller.currentBalanceInCents;
    final hasSurplus = balanceInCents >= 0;

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
              key: const ValueKey('home-payable-details'),
              width: cardWidth,
              label: 'Total a pagar',
              value: currency.format(totalDebtInCents / 100),
              icon: Icons.arrow_upward_rounded,
              color: Colors.orange,
              onTap: () => BalanceDetailsDialog.show(
                context,
                controller: controller,
                month: month,
                type: FinancialSummaryDetailsType.payable,
              ),
            ),
            _SummaryCard(
              key: const ValueKey('home-available-details'),
              width: cardWidth,
              label: 'Total disponível',
              value: currency.format(month.totalAvailableInCents / 100),
              icon: Icons.arrow_downward_rounded,
              color: Colors.blue,
              onTap: () => BalanceDetailsDialog.show(
                context,
                controller: controller,
                month: month,
                type: FinancialSummaryDetailsType.available,
              ),
            ),
            _SummaryCard(
              key: const ValueKey('home-balance-details'),
              width: cardWidth,
              label: hasSurplus ? 'Sobra' : 'Falta',
              value: currency.format(balanceInCents.abs() / 100),
              icon: hasSurplus
                  ? Icons.check_circle_outline
                  : Icons.error_outline,
              color: hasSurplus ? Colors.green : Colors.redAccent,
              onTap: () => BalanceDetailsDialog.show(
                context,
                controller: controller,
                month: month,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DashboardDetails extends StatelessWidget {
  const _DashboardDetails({required this.controller});

  final FinancialMonthController controller;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth >= 760
            ? (constraints.maxWidth - 16) / 2
            : constraints.maxWidth;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            SizedBox(
              width: width,
              child: _PaymentProgress(controller: controller),
            ),
            SizedBox(
              width: width,
              child: _UpcomingDueDates(controller: controller),
            ),
          ],
        );
      },
    );
  }
}

class _PaymentProgress extends StatelessWidget {
  const _PaymentProgress({required this.controller});

  final FinancialMonthController controller;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final total = controller.currentTotalDebtInCents;
    final paid = controller.currentTotalPaidInCents;
    final pending = controller.currentTotalPendingInCents;
    final progress = total == 0 ? 1.0 : (paid / total).clamp(0.0, 1.0);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Progresso do mês',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 14),
            LinearProgressIndicator(value: progress, minHeight: 10),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _ProgressValue(
                    label: 'Pago',
                    value: currency.format(paid / 100),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ProgressValue(
                    label: 'Pendente',
                    value: currency.format(pending / 100),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressValue extends StatelessWidget {
  const _ProgressValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 3),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _UpcomingDueDates extends StatelessWidget {
  const _UpcomingDueDates({required this.controller});

  final FinancialMonthController controller;

  @override
  Widget build(BuildContext context) {
    final entries =
        controller.currentMonth.entries
            .where(
              (entry) =>
                  entry.isDebt &&
                  !entry.isPaid &&
                  entry.dueDay != null &&
                  (entry.type != FinancialEntryType.cardInvoice ||
                      controller.cardInvoiceTotalInCents(entry) > 0) &&
                  (entry.type != FinancialEntryType.expense ||
                      entry.amountInCents > 0),
            )
            .toList()
          ..sort((a, b) => a.dueDay!.compareTo(b.dueDay!));
    final visibleEntries = entries.take(3).toList();

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Próximos vencimentos',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            if (visibleEntries.isEmpty)
              const Text('Nenhum vencimento pendente neste mês.')
            else
              for (final entry in visibleEntries)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.event_outlined),
                  title: Text(entry.name),
                  trailing: Text('Dia ${entry.dueDay}'),
                ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    super.key,
    required this.width,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  final double width;
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
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
                if (onTap != null)
                  Icon(
                    Icons.chevron_right,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
