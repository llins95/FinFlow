import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/credit_card.dart';

class CreditCardTile extends StatelessWidget {
  const CreditCardTile({
    super.key,
    required this.card,
    required this.invoiceMonth,
    this.invoiceInCents,
    this.automaticPurchasesInCents = 0,
    this.onEditInvoice,
    this.onEditCard,
  });

  final CreditCard card;
  final DateTime invoiceMonth;
  final int? invoiceInCents;
  final int automaticPurchasesInCents;
  final VoidCallback? onEditInvoice;
  final VoidCallback? onEditCard;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final monthLabel = toBeginningOfSentenceCase(
      DateFormat('MMMM/yyyy', 'pt_BR').format(invoiceMonth),
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Color(card.color),
                  child: const Icon(Icons.credit_card, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              card.name,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          if (!card.isActive) ...[
                            const SizedBox(width: 8),
                            const Chip(
                              visualDensity: VisualDensity.compact,
                              label: Text('Inativo'),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        '${card.bank} • ${card.brand}',
                        style: TextStyle(color: Colors.grey.shade400),
                      ),
                    ],
                  ),
                ),
                if (onEditInvoice != null)
                  IconButton(
                    onPressed: onEditInvoice,
                    tooltip: 'Editar fatura',
                    icon: const Icon(Icons.price_change_outlined),
                  ),
                if (onEditCard != null)
                  IconButton(
                    onPressed: onEditCard,
                    tooltip: 'Editar cartão',
                    icon: const Icon(Icons.edit_outlined),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              'Fatura de $monthLabel',
              style: TextStyle(color: Colors.grey.shade400),
            ),
            const SizedBox(height: 4),
            Text(
              invoiceInCents == null
                  ? 'Não cadastrada'
                  : currency.format(invoiceInCents! / 100),
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            if (automaticPurchasesInCents > 0) ...[
              const SizedBox(height: 6),
              Text(
                'Inclui ${currency.format(automaticPurchasesInCents / 100)} '
                'em compras adicionadas',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Wrap(
              spacing: 24,
              runSpacing: 12,
              children: [
                _Info(label: 'Limite', value: currency.format(card.limit)),
                _Info(label: 'Fecha', value: 'Dia ${card.closingDay}'),
                _Info(label: 'Vence', value: 'Dia ${card.dueDay}'),
                _Info(
                  label: 'Melhor dia',
                  value: 'Dia ${card.bestPurchaseDay}',
                ),
              ],
            ),
            if (!card.isActive) ...[
              const SizedBox(height: 14),
              Text(
                'Este cartão permanece no mês atual, mas não será copiado '
                'para o próximo.',
                style: TextStyle(color: Colors.grey.shade400),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Info extends StatelessWidget {
  const _Info({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey.shade400)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}
