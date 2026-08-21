import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

import '../../../services/finance_service.dart';
import '../../../shared/finance_repository.dart';
import '../../../shared/mock_data.dart';
import '../../../shared/purchase_repository.dart';

class CardsPage extends StatelessWidget {
  const CardsPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Cartões e faturas')),
    body: ValueListenableBuilder<Box>(valueListenable: PurchaseRepository.box.listenable(), builder: (context, _, __) {
      final now = DateTime.now();
      final month = DateTime(now.year, now.month);
      final schedule = FinanceService.installmentsGroupedByMonth()[month] ?? [];
      return ListView.builder(padding: const EdgeInsets.all(12), itemCount: mockCards.length, itemBuilder: (context, index) {
        final card = mockCards[index];
        final items = schedule.where((item) => item.cardId == card.id).toList();
        final cents = items.fold<int>(0, (sum, item) => sum + item.amountInCents);
        final paid = FinanceRepository.isInvoicePaid(card.id, month);
        return Card(child: ExpansionTile(
          leading: CircleAvatar(backgroundColor: Color(card.color), child: const Icon(Icons.credit_card, color: Colors.white)),
          title: Text(card.name),
          subtitle: Text('Fecha dia ${card.closingDay} • Vence dia ${card.dueDay}'),
          trailing: Text(paid ? 'PAGO' : NumberFormat.simpleCurrency(locale: 'pt_BR').format(cents / 100), style: const TextStyle(fontWeight: FontWeight.bold)),
          children: items.isEmpty ? [const ListTile(title: Text('Sem compras nesta fatura.'))] : items.map((item) => ListTile(title: Text(item.description), subtitle: Text('${item.installmentNumber}/${item.totalInstallments}'), trailing: Text(NumberFormat.simpleCurrency(locale: 'pt_BR').format(item.amount)))).toList(),
        ));
      });
    }),
  );
}
