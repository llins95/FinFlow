import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../services/finance_service.dart';
import '../../../shared/mock_data.dart';

class CalendarPage extends StatelessWidget {
  const CalendarPage({super.key});

  @override
  Widget build(BuildContext context) {
    final grouped = FinanceService.installmentsGroupedByMonth();

    final months = grouped.keys.toList()..sort();

    final currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    final monthFormatter = DateFormat('MMMM yyyy', 'pt_BR');

    return Scaffold(
      appBar: AppBar(title: const Text('Calendário Financeiro')),
      body: months.isEmpty
          ? const Center(child: Text('Nenhuma parcela cadastrada.'))
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: months.length,
              itemBuilder: (context, index) {
                final month = months[index];

                final installments = grouped[month]!;

                final totalMonth = FinanceService.totalForMonth(month);

                return Card(
                  margin: const EdgeInsets.only(bottom: 20),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          toBeginningOfSentenceCase(
                                monthFormatter.format(month),
                              ) ??
                              '',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 20),

                        ...installments.map((item) {
                          final card = mockCards.firstWhere(
                            (c) => c.id == item.cardId,
                          );

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 18),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: Color(card.color),
                                  child: Text('${item.installmentNumber}'),
                                ),

                                const SizedBox(width: 16),

                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.description,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),

                                      Text(
                                        '${item.installmentNumber}/${item.totalInstallments}',
                                      ),

                                      Text(
                                        card.name,
                                        style: const TextStyle(
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                Text(
                                  currency.format(item.amount),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),

                        const Divider(),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total do mês',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),

                            Text(
                              currency.format(totalMonth),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
