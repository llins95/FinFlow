import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../controllers/financial_month_controller.dart';
import '../models/financial_entry.dart';
import '../models/financial_month.dart';

enum FinancialSummaryDetailsType { balance, available, payable }

class BalanceDetailsDialog extends StatelessWidget {
  const BalanceDetailsDialog({
    super.key,
    required this.controller,
    required this.month,
    this.type = FinancialSummaryDetailsType.balance,
  });

  final FinancialMonthController controller;
  final FinancialMonth month;
  final FinancialSummaryDetailsType type;

  static Future<void> show(
    BuildContext context, {
    required FinancialMonthController controller,
    required FinancialMonth month,
    FinancialSummaryDetailsType type = FinancialSummaryDetailsType.balance,
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => BalanceDetailsDialog(
        controller: controller,
        month: month,
        type: type,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return switch (type) {
      FinancialSummaryDetailsType.balance => _buildBalanceDialog(
        context,
        currency,
      ),
      FinancialSummaryDetailsType.available => _buildAvailableDialog(
        context,
        currency,
      ),
      FinancialSummaryDetailsType.payable => _buildPayableDialog(
        context,
        currency,
      ),
    };
  }

  Widget _buildBalanceDialog(BuildContext context, NumberFormat currency) {
    final totalDebt = controller.totalDebtInCentsForMonth(month);
    final totalPending = controller.totalPendingInCentsForMonth(month);
    final totalPaid = controller.totalPaidInCentsForMonth(month);
    final available = month.totalAvailableInCents;
    final balance = controller.balanceInCentsForMonth(month);
    final hasSurplus = balance >= 0;
    final resultColor = hasSurplus ? Colors.green : Colors.redAccent;
    final debtEntries = _debtEntries();

    return AlertDialog(
      icon: Icon(
        hasSurplus ? Icons.check_circle_outline : Icons.error_outline,
        color: resultColor,
      ),
      title: Text(hasSurplus ? 'Detalhes da sobra' : 'O que está faltando?'),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                hasSurplus
                    ? 'Depois de considerar todos os compromissos deste mês, ainda há valor disponível.'
                    : 'O valor disponível não cobre todos os compromissos cadastrados neste mês.',
              ),
              const SizedBox(height: 16),
              _FormulaRow(
                label: 'Total disponível',
                value: currency.format(available / 100),
              ),
              const SizedBox(height: 8),
              _FormulaRow(
                label: 'Compromissos do mês',
                value: '- ${currency.format(totalDebt / 100)}',
              ),
              const Divider(height: 24),
              _FormulaRow(
                label: hasSurplus ? 'Sobra' : 'Falta',
                value: currency.format(balance.abs() / 100),
                valueColor: resultColor,
                emphasize: true,
              ),
              const SizedBox(height: 12),
              Text(
                'Dos compromissos do mês, ${currency.format(totalPaid / 100)} '
                'já está marcado como pago e ${currency.format(totalPending / 100)} '
                'ainda está pendente.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'O que compõe os compromissos',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              if (debtEntries.isEmpty)
                const Text(
                  'Nenhuma despesa ou fatura com valor foi encontrada.',
                )
              else
                for (final entry in debtEntries)
                  _DebtTile(
                    entry: entry,
                    amountInCents: _amountFor(entry),
                    currency: currency,
                  ),
            ],
          ),
        ),
      ),
      actions: [_closeButton(context)],
    );
  }

  Widget _buildAvailableDialog(BuildContext context, NumberFormat currency) {
    final available = month.totalAvailableInCents;
    final availableEntries = month.entries
        .where(
          (entry) =>
              (entry.type == FinancialEntryType.income ||
                  entry.type == FinancialEntryType.previousBalance) &&
              entry.amountInCents != 0,
        )
        .toList()
      ..sort((a, b) {
        if (a.type != b.type) {
          return a.type == FinancialEntryType.previousBalance ? -1 : 1;
        }
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });

    return AlertDialog(
      icon: const Icon(Icons.account_balance_wallet_outlined, color: Colors.blue),
      title: const Text('O que compõe o total disponível?'),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'O total disponível é a soma das receitas cadastradas e do saldo trazido do mês anterior.',
              ),
              const SizedBox(height: 16),
              _FormulaRow(
                label: 'Total disponível',
                value: currency.format(available / 100),
                valueColor: Colors.blue,
                emphasize: true,
              ),
              const SizedBox(height: 20),
              Text(
                'Valores incluídos',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              if (availableEntries.isEmpty)
                const Text('Nenhuma receita ou saldo anterior foi cadastrado.')
              else
                for (final entry in availableEntries)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      entry.type == FinancialEntryType.previousBalance
                          ? Icons.savings_outlined
                          : Icons.arrow_downward_rounded,
                    ),
                    title: Text(entry.name),
                    subtitle: Text(
                      entry.type == FinancialEntryType.previousBalance
                          ? 'Saldo do mês anterior'
                          : 'Receita',
                    ),
                    trailing: Text(
                      currency.format(entry.amountInCents / 100),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
            ],
          ),
        ),
      ),
      actions: [_closeButton(context)],
    );
  }

  Widget _buildPayableDialog(BuildContext context, NumberFormat currency) {
    final totalPending = controller.totalPendingInCentsForMonth(month);
    final totalPaid = controller.totalPaidInCentsForMonth(month);
    final pendingEntries = _debtEntries()
        .where((entry) => !entry.isPaid)
        .toList(growable: false);

    return AlertDialog(
      icon: const Icon(Icons.payments_outlined, color: Colors.orange),
      title: const Text('O que compõe o total a pagar?'),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'O total a pagar soma somente as despesas e faturas que ainda não estão marcadas como pagas.',
              ),
              const SizedBox(height: 16),
              _FormulaRow(
                label: 'Total a pagar',
                value: currency.format(totalPending / 100),
                valueColor: Colors.orange,
                emphasize: true,
              ),
              const SizedBox(height: 8),
              _FormulaRow(
                label: 'Já pago no mês',
                value: currency.format(totalPaid / 100),
              ),
              const SizedBox(height: 20),
              Text(
                'Pendências incluídas',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              if (pendingEntries.isEmpty)
                const Text('Nenhuma despesa ou fatura está pendente.')
              else
                for (final entry in pendingEntries)
                  _DebtTile(
                    entry: entry,
                    amountInCents: _amountFor(entry),
                    currency: currency,
                  ),
            ],
          ),
        ),
      ),
      actions: [_closeButton(context)],
    );
  }

  List<FinancialEntry> _debtEntries() {
    final entries = month.entries.where((entry) => entry.isDebt).where((entry) {
      return _amountFor(entry) > 0;
    }).toList()
      ..sort((a, b) {
        if (a.isPaid != b.isPaid) {
          return a.isPaid ? 1 : -1;
        }
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
    return entries;
  }

  Widget _closeButton(BuildContext context) {
    return FilledButton(
      onPressed: () => Navigator.pop(context),
      child: const Text('Entendi'),
    );
  }

  int _amountFor(FinancialEntry entry) {
    if (entry.type == FinancialEntryType.cardInvoice) {
      return controller.cardInvoiceTotalInCentsForMonth(entry, month.date);
    }
    return entry.amountInCents;
  }
}

class _DebtTile extends StatelessWidget {
  const _DebtTile({
    required this.entry,
    required this.amountInCents,
    required this.currency,
  });

  final FinancialEntry entry;
  final int amountInCents;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        entry.type == FinancialEntryType.cardInvoice
            ? Icons.credit_card_outlined
            : Icons.receipt_long_outlined,
      ),
      title: Text(entry.name),
      subtitle: Text(entry.isPaid ? 'Pago' : 'Pendente'),
      trailing: Text(
        currency.format(amountInCents / 100),
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _FormulaRow extends StatelessWidget {
  const _FormulaRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final style = emphasize
        ? Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: valueColor,
          )
        : Theme.of(context).textTheme.bodyLarge?.copyWith(color: valueColor);

    return Row(
      children: [
        Expanded(child: Text(label)),
        const SizedBox(width: 16),
        Text(value, style: style),
      ],
    );
  }
}
