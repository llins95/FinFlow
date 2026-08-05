import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/credit_card.dart';

class CreditCardTile extends StatelessWidget {
  const CreditCardTile({
    super.key,
    required this.card,
    this.invoiceInCents,
    this.onEditInvoice,
  });

  final CreditCard card;
  final int? invoiceInCents;
  final VoidCallback? onEditInvoice;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

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
                      Text(
                        card.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
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
                    icon: const Icon(Icons.edit_outlined),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              'Fatura do mês',
              style: TextStyle(color: Colors.grey.shade400),
            ),
            const SizedBox(height: 4),
            Text(
              invoiceInCents == null
                  ? 'Não cadastrada'
                  : currency.format(invoiceInCents! / 100),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
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
