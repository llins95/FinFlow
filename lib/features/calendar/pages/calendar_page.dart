import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../controllers/financial_month_controller.dart';
import '../../../services/finance_service.dart';

class CalendarPage extends StatelessWidget {
  const CalendarPage({
    super.key,
    required this.controller,
  });

  final FinancialMonthController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final purchases = controller.purchaseRecords;
        final grouped = FinanceService.installmentsGroupedByMonth(purchases);
        final months = grouped.keys.toList()..sort();
        final currency = NumberFormat.currency(
          locale: 'pt_BR',
          symbol: 'R\$',
        );
        final monthFormatter = DateFormat('MMMM yyyy', 'pt_BR');

        return Scaffold(
          appBar: AppBar(title: const Text('Parcelas')),
          body: months.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Nenhuma parcela cadastrada. As compras salvas '
                      'aparecerão aqui automaticamente.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: months.length,
                  itemBuilder: (context, index) {
                    final month = months[index];
                    final installments = grouped[month]!;
                    final totalInCents =
                        FinanceService.totalForMonthInCents(
                          month,
                          purchases,
                        );

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
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),
                            for (final installment in installments)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: Color(
                                        installment.cardColor,
                                      ),
                                      foregroundColor: Colors.white,
                                      child: Text(
                                        '${installment.installmentNumber}',
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            installment.description,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            '${installment.installmentNumber}/'
                                            '${installment.totalInstallments}'
                                            ' • ${installment.cardName}',
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      currency.format(installment.amount),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            const Divider(),
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Total do mês',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  currency.format(totalInCents / 100),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
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
      },
    );
  }
}
