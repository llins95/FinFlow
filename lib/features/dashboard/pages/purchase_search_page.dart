import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/purchase_record.dart';
import '../../../services/finance_service.dart';

Future<void> showPurchaseSearch(
  BuildContext context,
  Iterable<PurchaseRecord> purchases,
) async {
  await showSearch<void>(
    context: context,
    delegate: PurchaseSearchDelegate(purchases: purchases),
  );
}

class PurchaseSearchDelegate extends SearchDelegate<void> {
  PurchaseSearchDelegate({required Iterable<PurchaseRecord> purchases})
    : purchases = List.unmodifiable(purchases),
      super(searchFieldLabel: 'Compra ou mês');

  final List<PurchaseRecord> purchases;
  final NumberFormat _currency = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
    decimalDigits: 2,
  );
  final DateFormat _date = DateFormat('dd/MM/yyyy', 'pt_BR');
  final DateFormat _month = DateFormat('MMMM yyyy', 'pt_BR');

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          onPressed: () => query = '',
          tooltip: 'Limpar busca',
          icon: const Icon(Icons.close),
        ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      onPressed: () => close(context, null),
      tooltip: 'Voltar',
      icon: const Icon(Icons.arrow_back),
    );
  }

  @override
  Widget buildResults(BuildContext context) => _buildContent(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildContent(context);

  Widget _buildContent(BuildContext context) {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) {
      return const _SearchHint();
    }

    final results = FinanceService.searchPurchases(purchases, trimmedQuery);
    if (results.isEmpty) {
      return _EmptySearch(query: trimmedQuery);
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      itemCount: results.length,
      itemBuilder: (context, index) => _PurchaseResultCard(
        result: results[index],
        currency: _currency,
        date: _date,
        month: _month,
      ),
    );
  }
}

class _SearchHint extends StatelessWidget {
  const _SearchHint();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.manage_search, size: 64),
            SizedBox(height: 16),
            Text(
              'Busque pelo nome da compra ou por um mês',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Exemplos: supermercado, setembro 2026 ou 09/2026. '
              'O resultado mostra todas as parcelas e os meses de vencimento.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptySearch extends StatelessWidget {
  const _EmptySearch({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off, size: 64),
            const SizedBox(height: 16),
            Text(
              'Nenhuma compra encontrada para “$query”.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _PurchaseResultCard extends StatelessWidget {
  const _PurchaseResultCard({
    required this.result,
    required this.currency,
    required this.date,
    required this.month,
  });

  final PurchaseSearchResult result;
  final NumberFormat currency;
  final DateFormat date;
  final DateFormat month;

  @override
  Widget build(BuildContext context) {
    final purchase = result.record.entry;
    final installments = result.installments;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        initiallyExpanded: true,
        leading: CircleAvatar(
          backgroundColor: Color(purchase.cardColor ?? 0xFF455A64),
          foregroundColor: Colors.white,
          child: const Icon(Icons.shopping_bag_outlined),
        ),
        title: Text(
          purchase.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${purchase.relatedCardName ?? 'Cartão não encontrado'} • '
          '${date.format(result.record.purchaseDate)}\n'
          '${currency.format(purchase.amountInCents / 100)} • '
          '${installments.length == 1 ? 'à vista' : '${installments.length} parcelas'}',
        ),
        children: [
          const Divider(height: 1),
          for (final installment in installments)
            ColoredBox(
              color: result.installmentMatches(installment)
                  ? colorScheme.primaryContainer.withValues(alpha: 0.45)
                  : Colors.transparent,
              child: ListTile(
                leading: CircleAvatar(
                  radius: 20,
                  child: Text('${installment.installmentNumber}'),
                ),
                title: Text(
                  '${installment.installmentNumber}/'
                  '${installment.totalInstallments} • '
                  '${toBeginningOfSentenceCase(month.format(installment.dueDate))}',
                ),
                subtitle: Text(
                  'Vencimento em ${date.format(installment.dueDate)}',
                ),
                trailing: Text(
                  currency.format(installment.amountInCents / 100),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
