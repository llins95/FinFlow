import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/financial_entry.dart';

class FinancialEntrySection extends StatelessWidget {
  const FinancialEntrySection({
    super.key,
    required this.title,
    required this.icon,
    required this.entries,
    required this.onEdit,
    this.onAdd,
    this.onDelete,
    this.amountInCentsFor,
  });

  final String title;
  final IconData icon;
  final List<FinancialEntry> entries;
  final ValueChanged<FinancialEntry> onEdit;
  final VoidCallback? onAdd;
  final ValueChanged<FinancialEntry>? onDelete;
  final int Function(FinancialEntry entry)? amountInCentsFor;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final total = entries.fold(
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
              ...entries.map(
                (entry) => ListTile(
                  contentPadding: const EdgeInsets.only(left: 4, right: 0),
                  title: Text(entry.name),
                  subtitle: _subtitle(entry, currency),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        currency.format(
                          (amountInCentsFor?.call(entry) ??
                                  entry.amountInCents) /
                              100,
                        ),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      IconButton(
                        onPressed: () => onEdit(entry),
                        tooltip: 'Editar ${entry.name}',
                        icon: const Icon(Icons.edit_outlined),
                      ),
                      if (onDelete != null && entry.id.startsWith('custom-'))
                        IconButton(
                          onPressed: () => onDelete!(entry),
                          tooltip: 'Excluir ${entry.name}',
                          icon: const Icon(Icons.delete_outline),
                        ),
                    ],
                  ),
                  onTap: () => onEdit(entry),
                ),
              ),
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
      details.add('Recorrente');
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
