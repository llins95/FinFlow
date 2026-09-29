import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/financial_entry.dart';
import '../../../shared/mini_credit_card.dart';
import '../../../utils/card_mapper.dart';

class FinancialEntrySection extends StatelessWidget {
  const FinancialEntrySection({
    super.key,
    required this.title,
    required this.icon,
    required this.entries,
    required this.onEdit,
    this.onAdd,
    this.onDelete,
    this.onTogglePaid,
    this.amountInCentsFor,
  });

  final String title;
  final IconData icon;
  final List<FinancialEntry> entries;
  final ValueChanged<FinancialEntry> onEdit;
  final VoidCallback? onAdd;
  final ValueChanged<FinancialEntry>? onDelete;
  final ValueChanged<FinancialEntry>? onTogglePaid;
  final int Function(FinancialEntry entry)? amountInCentsFor;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final total = entries
        .where((entry) {
          return onTogglePaid == null || !entry.isPaid;
        })
        .fold(
          0,
          (value, entry) =>
              value + (amountInCentsFor?.call(entry) ?? entry.amountInCents),
        );

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        currency.format(total / 100),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onAdd != null)
                  IconButton(
                    onPressed: onAdd,
                    tooltip: 'Adicionar',
                    icon: const Icon(Icons.add),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (entries.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Nenhum lançamento neste grupo.'),
              )
            else
              ...entries.map((entry) {
                final details = _subtitle(entry, currency);
                final card = entry.type == FinancialEntryType.cardInvoice
                    ? creditCardFromInvoice(entry)
                    : null;

                return ListTile(
                  contentPadding: const EdgeInsets.only(left: 4, right: 0),
                  leading: card == null
                      ? null
                      : MiniCreditCard(
                          key: ValueKey('mini-card-${entry.id}'),
                          color: card.color,
                          brand: card.brand,
                        ),
                  title: Text(
                    entry.name,
                    style: entry.isPaid
                        ? TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                            decoration: TextDecoration.lineThrough,
                          )
                        : null,
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ?details,
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (onTogglePaid case final togglePaid?)
                            _PaidButton(
                              entry: entry,
                              onPressed: () => togglePaid(entry),
                            ),
                          IconButton(
                            onPressed: () => onEdit(entry),
                            tooltip: 'Editar ${entry.name}',
                            icon: const Icon(Icons.edit_outlined),
                          ),
                          if (onDelete != null)
                            IconButton(
                              onPressed: () => onDelete!(entry),
                              tooltip: 'Excluir ${entry.name}',
                              icon: const Icon(Icons.delete_outline),
                            ),
                        ],
                      ),
                    ],
                  ),
                  trailing: Text(
                    currency.format(
                      (amountInCentsFor?.call(entry) ?? entry.amountInCents) /
                          100,
                    ),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  onTap: () => onEdit(entry),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget? _subtitle(FinancialEntry entry, NumberFormat currency) {
    final details = <String>[];
    if (entry.closingDay != null) {
      details.add('Fecha dia ${entry.closingDay}');
    }
    if (entry.dueDay != null) {
      details.add('Vence dia ${entry.dueDay}');
    }
    if (entry.isRecurring && entry.type != FinancialEntryType.cardInvoice) {
      final endMonth = entry.recurrenceEndMonth;
      details.add(
        endMonth == null
            ? 'Recorrente sem data final'
            : 'Recorrente até '
                  '${DateFormat('MMMM/yyyy', 'pt_BR').format(endMonth)}',
      );
    }
    if (entry.type == FinancialEntryType.cardInvoice &&
        amountInCentsFor != null) {
      final automaticAmount = amountInCentsFor!(entry) - entry.amountInCents;
      if (automaticAmount > 0) {
        details.add(
          'Inclui ${currency.format(automaticAmount / 100)} em compras',
        );
      }
    }

    return details.isEmpty ? null : Text(details.join(' • '));
  }
}

class _PaidButton extends StatelessWidget {
  const _PaidButton({required this.entry, required this.onPressed});

  final FinancialEntry entry;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final paidColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.green.shade200
        : Colors.green.shade800;

    return Tooltip(
      message: entry.isPaid ? 'Marcar como pendente' : 'Marcar como pago',
      child: FilledButton.tonalIcon(
        key: ValueKey('paid-toggle-${entry.id}'),
        onPressed: onPressed,
        icon: Icon(
          entry.isPaid ? Icons.check_circle : Icons.circle_outlined,
          size: 18,
        ),
        label: const Text('PAGO'),
        style: FilledButton.styleFrom(
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          backgroundColor: entry.isPaid
              ? paidColor.withValues(alpha: 0.18)
              : colorScheme.surfaceContainerHighest,
          foregroundColor: entry.isPaid
              ? paidColor
              : colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
