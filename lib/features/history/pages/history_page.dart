import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/purchase.dart';
import '../../../shared/mock_data.dart';
import '../../../shared/purchase_repository.dart';
import 'edit_purchase_page.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final NumberFormat currencyFormatter = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
    decimalDigits: 2,
  );

  final DateFormat dateFormatter = DateFormat('dd/MM/yyyy', 'pt_BR');

  Future<void> openEditPurchasePage(Purchase purchase) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) {
          return EditPurchasePage(purchase: purchase);
        },
      ),
    );

    if (result != true || !mounted) {
      return;
    }

    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Compra atualizada com sucesso!')),
    );
  }

  Future<void> confirmDeletePurchase(Purchase purchase) async {
    final matchingCards = mockCards.where((card) => card.id == purchase.cardId);

    final cardName = matchingCards.isEmpty
        ? 'Cartão não encontrado'
        : matchingCards.first.name;

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Excluir compra?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Esta ação removerá a compra do histórico.'),
              const SizedBox(height: 20),
              Text(
                purchase.description,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                currencyFormatter.format(purchase.amount),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text('Cartão: $cardName'),
              const SizedBox(height: 4),
              Text('Data: ${dateFormatter.format(purchase.purchaseDate)}'),
              const SizedBox(height: 4),
              Text(
                purchase.installments == 1
                    ? 'Pagamento à vista'
                    : '${purchase.installments} parcelas',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancelar'),
            ),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              icon: const Icon(Icons.delete_outline),
              label: const Text('Excluir'),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) {
      return;
    }

    await PurchaseRepository.remove(purchase.id);

    if (!mounted) {
      return;
    }

    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Compra "${purchase.description}" excluída.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final purchases = PurchaseRepository.purchases;

    return Scaffold(
      appBar: AppBar(title: const Text('Histórico')),
      body: purchases.isEmpty
          ? const _EmptyHistory()
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: purchases.length,
              itemBuilder: (context, index) {
                final purchase = purchases[index];

                final matchingCards = mockCards.where(
                  (card) => card.id == purchase.cardId,
                );

                final card = matchingCards.isEmpty ? null : matchingCards.first;

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: card == null
                          ? Colors.grey
                          : Color(card.color),
                      child: const Icon(
                        Icons.shopping_bag_outlined,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(
                      purchase.description,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${card?.name ?? 'Cartão não encontrado'}\n'
                      '${dateFormatter.format(purchase.purchaseDate)}',
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          currencyFormatter.format(purchase.amount),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          purchase.installments == 1
                              ? 'À vista'
                              : '${purchase.installments}x',
                        ),
                      ],
                    ),
                    onTap: () {
                      openEditPurchasePage(purchase);
                    },
                    onLongPress: () {
                      confirmDeletePurchase(purchase);
                    },
                  ),
                );
              },
            ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 72,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 18),
            const Text(
              'Nenhuma compra cadastrada.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'As compras salvas aparecerão aqui.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
