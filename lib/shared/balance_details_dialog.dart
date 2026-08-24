import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../controllers/financial_month_controller.dart';
import '../models/financial_entry.dart';
import '../models/financial_month.dart';

class BalanceDetailsDialog extends StatelessWidget {
  const BalanceDetailsDialog({
    super.key,
    required this.controller,
    required this.month,
  });

  final FinancialMonthController controller;
  final FinancialMonth month;

  static Future<void> show(
    BuildContext context, {
    required FinancialMonthController controller,
    required FinancialMonth month,
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => BalanceDetailsDialog(
        controller: controller,
        month: month,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final totalDebt = controller.totalDebtInCentsForMonth(month);
    final totalPending = controller.totalPendingInCentsForMonth(month);
    final totalPaid = controller.totalPaidInCentsForMonth(month);
    final available = month.totalAvailableInCents;
    final balance = controller.balanceInCentsForMonth(month);
    final hasSurplus = balance >= 0;
    final resultColor = hasSurplus ? Colors.green : Colors.redAccent;
    final debtEntries = month.entries.where((entry) => entry.isDebt).where((entry) {
      return _amountFor(entry) > 0;
    }).toList()
      ..sort((a, b) {
        if (a.isPaid != b.isPaid) {
          return a.isPaid ? 1 : -1;
        }
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });

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
                const Text('Nenhuma despesa ou fatura com valor foi encontrada.')
              else
                for (final entry in debtEntries)
                  ListTile(
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
                      currency.format(_amountFor(entry) / 100),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
            ],
          ),
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Entendi'),
        ),
      ],
    );
  }

  int _amountFor(FinancialEntry entry) {
    if (entry.type == FinancialEntryType.cardInvoice) {
      return controller.cardInvoiceTotalInCentsForMonth(entry, month.date);
    }
    return entry.amountInCents;
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
