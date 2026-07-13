import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../services/finance_service.dart';
import '../../../shared/mock_data.dart';
import '../widgets/credit_card_tile.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
      decimalDigits: 2,
    );

    final totalPurchases = FinanceService.totalPurchases();
    final purchasesCount = FinanceService.totalPurchasesCount();
    final mostUsedCard = FinanceService.mostUsedCard();
    final monthlyInstallments = FinanceService.estimatedMonthlyInstallments();

    return Scaffold(
      appBar: AppBar(title: const Text('FinFlow')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Boa tarde, Murilo 👋',
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 30),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Resumo financeiro',
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 10),
                  const Row(
                    children: [
                      Icon(Icons.circle, color: Colors.green, size: 28),
                      SizedBox(width: 12),
                      Text(
                        'Excelente',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'Total das compras cadastradas',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    currencyFormatter.format(totalPurchases),
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      _SummaryItem(
                        icon: Icons.shopping_bag_outlined,
                        title: 'Compras',
                        value: purchasesCount == 1
                            ? '1 compra'
                            : '$purchasesCount compras',
                      ),
                      _SummaryItem(
                        icon: Icons.credit_card,
                        title: 'Cartão mais usado',
                        value: mostUsedCard,
                      ),
                      _SummaryItem(
                        icon: Icons.calendar_month,
                        title: 'Parcelas mensais estimadas',
                        value: currencyFormatter.format(monthlyInstallments),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            'Meus Cartões',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: mockCards.length,
            itemBuilder: (context, index) {
              return CreditCardTile(card: mockCards[index]);
            },
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _SummaryItem({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(icon, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
