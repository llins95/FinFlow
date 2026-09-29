import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/purchase_record.dart';

Future<bool> showPurchaseDeleteConfirmation(
  BuildContext context,
  PurchaseRecord record,
) async {
  final purchase = record.entry;
  final cardName = purchase.relatedCardName ?? 'Cartão não encontrado';
  final currency = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
    decimalDigits: 2,
  );
  final date = DateFormat('dd/MM/yyyy', 'pt_BR');

  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      final colorScheme = Theme.of(dialogContext).colorScheme;

      return AlertDialog(
        title: const Text('Excluir compra?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'A compra será removida do histórico e deixará de contar '
              'em todas as parcelas das faturas.',
            ),
            const SizedBox(height: 20),
            Text(
              purchase.name,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              currency.format(purchase.amountInCents / 100),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Cartão: $cardName'),
            const SizedBox(height: 4),
            Text('Data: ${date.format(record.purchaseDate)}'),
            const SizedBox(height: 4),
            Text(
              (purchase.installments ?? 1) == 1
                  ? 'Pagamento à vista'
                  : '${purchase.installments} parcelas',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Excluir'),
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.error,
              foregroundColor: colorScheme.onError,
            ),
          ),
        ],
      );
    },
  );

  return result ?? false;
}
