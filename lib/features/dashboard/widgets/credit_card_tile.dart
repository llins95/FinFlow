import 'package:flutter/material.dart';

import '../../../models/credit_card.dart';

class CreditCardTile extends StatelessWidget {
  final CreditCard card;

  const CreditCardTile({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 18),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(radius: 18, backgroundColor: Color(card.color)),

                const SizedBox(width: 12),

                Expanded(
                  child: Text(
                    card.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                Text(card.brand, style: TextStyle(color: Colors.grey.shade400)),
              ],
            ),

            const SizedBox(height: 14),

            const Text("Limite", style: TextStyle(color: Colors.grey)),

            Text(
              "R\$ ${card.limit.toStringAsFixed(0)}",
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _Info(titulo: "Fecha", valor: card.closingDay.toString()),

                _Info(titulo: "Vence", valor: card.dueDay.toString()),

                _Info(
                  titulo: "Melhor dia",
                  valor: card.bestPurchaseDay.toString(),
                ),
              ],
            ),
            const SizedBox(height: 20),

            const Divider(),

            const SizedBox(height: 10),

            Text("Próxima fatura", style: TextStyle(color: Colors.grey)),

            const SizedBox(height: 8),

            Text(
              "${card.nextInvoiceDate().day.toString().padLeft(2, '0')}/"
              "${card.nextInvoiceDate().month.toString().padLeft(2, '0')}/"
              "${card.nextInvoiceDate().year}",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            Text("Restam ${card.daysUntilInvoice()} dias"),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: card.purchaseGoesToNextInvoice()
                    ? Colors.green.withValues(alpha: 0.15)
                    : Colors.orange.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                card.purchaseAdvice(),
                style: TextStyle(
                  color: card.purchaseGoesToNextInvoice()
                      ? Colors.green
                      : Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(card.purchaseAdvice()),
          ],
        ),
      ),
    );
  }
}

class _Info extends StatelessWidget {
  final String titulo;
  final String valor;

  const _Info({required this.titulo, required this.valor});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(titulo, style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 4),
        Text(
          valor,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
