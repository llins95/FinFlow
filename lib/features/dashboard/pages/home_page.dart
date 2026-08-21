import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

import '../../../models/financial_entry.dart';
import '../../../services/finance_service.dart';
import '../../../shared/finance_repository.dart';
import '../../../shared/mock_data.dart';
import '../../../shared/purchase_repository.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('FinFlow'), actions: [IconButton(tooltip: 'Pesquisar', icon: const Icon(Icons.search), onPressed: () => showSearch(context: context, delegate: _FinanceSearch()))]),
      body: ValueListenableBuilder<Box>(valueListenable: PurchaseRepository.box.listenable(), builder: (context, _, __) =>
        ValueListenableBuilder<Box>(valueListenable: FinanceRepository.entriesBox.listenable(), builder: (context, _, __) =>
          ValueListenableBuilder<Box>(valueListenable: FinanceRepository.paymentsBox.listenable(), builder: (context, _, __) => const _DashboardBody()))),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody();
  static final money = NumberFormat.simpleCurrency(locale: 'pt_BR');

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final month = DateTime(now.year, now.month);
    final entries = FinanceRepository.entries.where((e) => e.dueDate.year == now.year && e.dueDate.month == now.month).toList();
    final incomes = entries.where((e) => e.type == EntryType.income).fold<int>(0, (s, e) => s + e.amountInCents);
    final expenses = entries.where((e) => e.type == EntryType.expense).fold<int>(0, (s, e) => s + e.amountInCents);
    final pendingExpenses = entries.where((e) => e.type == EntryType.expense && !e.paid).fold<int>(0, (s, e) => s + e.amountInCents);
    final installments = FinanceService.installmentsGroupedByMonth()[month] ?? [];
    final invoices = <String, int>{};
    for (final item in installments) { invoices.update(item.cardId, (v) => v + item.amountInCents, ifAbsent: () => item.amountInCents); }
    final pendingInvoices = invoices.entries.where((e) => !FinanceRepository.isInvoicePaid(e.key, month)).fold<int>(0, (s, e) => s + e.value);
    final paid = expenses - pendingExpenses + invoices.values.fold<int>(0, (s, v) => s + v) - pendingInvoices;
    final totalPending = pendingExpenses + pendingInvoices;
    final balance = incomes - expenses - invoices.values.fold<int>(0, (s, v) => s + v);

    return ListView(padding: const EdgeInsets.all(16), children: [
      Text(DateFormat('MMMM yyyy', 'pt_BR').format(now), style: Theme.of(context).textTheme.headlineSmall),
      ..._alerts(now, month, entries, invoices).map((message) => Card(
        color: Theme.of(context).colorScheme.secondaryContainer,
        child: ListTile(leading: const Icon(Icons.notifications_active_outlined), title: Text(message)),
      )),
      const SizedBox(height: 12),
      Wrap(spacing: 12, runSpacing: 12, children: [
        _Metric('TOTAL A PAGAR', totalPending, Icons.pending_actions, Colors.orange),
        _Metric('Receitas', incomes, Icons.trending_up, Colors.green),
        _Metric('Despesas', expenses, Icons.trending_down, Colors.red),
        _Metric('Faturas', invoices.values.fold(0, (s, v) => s + v), Icons.credit_card, Colors.blue),
        _Metric('Valores pagos', paid, Icons.check_circle, Colors.green),
        _Metric('Saldo', balance, Icons.account_balance_wallet, balance >= 0 ? Colors.teal : Colors.red),
      ]),
      const SizedBox(height: 24),
      Text('Despesas', style: Theme.of(context).textTheme.titleLarge),
      ...entries.where((e) => e.type == EntryType.expense).map((e) => Card(child: ListTile(title: Text(e.description), subtitle: Text(DateFormat('dd/MM').format(e.dueDate)), trailing: FilledButton.tonal(onPressed: () => FinanceRepository.saveEntry(e.copyWith(paid: !e.paid)), child: Text(e.paid ? 'PAGO' : money.format(e.amount))))),
      const SizedBox(height: 16),
      Text('Faturas dos cartões', style: Theme.of(context).textTheme.titleLarge),
      ...invoices.entries.map((invoice) { final card = mockCards.firstWhere((c) => c.id == invoice.key); final isPaid = FinanceRepository.isInvoicePaid(card.id, month); return Card(child: ListTile(title: Text(card.name), subtitle: Text('${installments.where((i) => i.cardId == card.id).length} parcela(s)'), trailing: FilledButton.tonal(onPressed: () => FinanceRepository.setInvoicePaid(card.id, month, !isPaid), child: Text(isPaid ? 'PAGO' : money.format(invoice.value / 100))))); }),
    ]);
  }

  List<String> _alerts(DateTime now, DateTime month, List<FinancialEntry> entries, Map<String, int> invoices) {
    final alerts = <String>[];
    for (final card in mockCards.where((c) => invoices.containsKey(c.id) && !FinanceRepository.isInvoicePaid(c.id, month))) {
      if (now.day == card.closingDay) alerts.add('A fatura ${card.name} fecha hoje.');
      if (now.day + 1 == card.dueDay) alerts.add('A fatura ${card.name} vence amanhã.');
    }
    for (final expense in entries.where((e) => e.type == EntryType.expense && !e.paid)) {
      final today = DateTime(now.year, now.month, now.day);
      if (expense.dueDate.difference(today).inDays == 1) alerts.add('${expense.description} vence amanhã.');
    }
    return alerts;
  }
}

class _Metric extends StatelessWidget {
  final String label; final int cents; final IconData icon; final Color color;
  const _Metric(this.label, this.cents, this.icon, this.color);
  @override Widget build(BuildContext context) => Card(child: SizedBox(width: 190, child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: color), const SizedBox(height: 8), Text(label), Text(_DashboardBody.money.format(cents / 100), style: Theme.of(context).textTheme.titleLarge)]))));
}

class _FinanceSearch extends SearchDelegate<void> {
  @override List<Widget>? buildActions(BuildContext context) => [IconButton(onPressed: () => query = '', icon: const Icon(Icons.clear))];
  @override Widget? buildLeading(BuildContext context) => BackButton(onPressed: () => close(context, null));
  @override Widget buildResults(BuildContext context) => buildSuggestions(context);
  @override Widget buildSuggestions(BuildContext context) {
    final q = query.toLowerCase().trim();
    final purchases = PurchaseRepository.purchases.where((p) => p.description.toLowerCase().contains(q));
    final entries = FinanceRepository.entries.where((e) => e.description.toLowerCase().contains(q));
    return ListView(children: [
      ...purchases.map((p) { final card = mockCards.where((c) => c.id == p.cardId).firstOrNull; final schedule = FinanceService.scheduledInstallments().where((i) => i.purchaseId == p.id).toList(); return ListTile(leading: const Icon(Icons.shopping_bag), title: Text(p.description), subtitle: Text('${card?.name ?? 'Cartão removido'} • ${p.installments}x • ${schedule.map((i) => DateFormat('MM/yyyy').format(i.dueDate)).join(', ')}'), trailing: Text(_DashboardBody.money.format(p.amount))); }),
      ...entries.map((e) => ListTile(leading: Icon(e.type == EntryType.income ? Icons.trending_up : Icons.trending_down), title: Text(e.description), subtitle: Text(DateFormat('dd/MM/yyyy').format(e.dueDate)), trailing: Text(_DashboardBody.money.format(e.amount)))),
    ]);
  }
}
