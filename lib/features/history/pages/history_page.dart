import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../controllers/financial_month_controller.dart';
import '../../../models/financial_month.dart';
import '../../../models/purchase_record.dart';
import '../../../shared/balance_details_dialog.dart';
import '../widgets/purchase_delete_confirmation.dart';
import 'edit_purchase_page.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({
    super.key,
    required this.controller,
    required this.onOpenMonth,
  });

  final FinancialMonthController controller;
  final Future<void> Function(FinancialMonth month) onOpenMonth;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Histórico'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.calendar_view_month), text: 'Meses'),
              Tab(icon: Icon(Icons.shopping_bag_outlined), text: 'Compras'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _FinancialMonthHistory(
              controller: controller,
              onOpenMonth: onOpenMonth,
            ),
            _PurchaseHistoryPage(controller: controller),
          ],
        ),
      ),
    );
  }
}

class _FinancialMonthHistory extends StatelessWidget {
  const _FinancialMonthHistory({
    required this.controller,
    required this.onOpenMonth,
  });

  final FinancialMonthController controller;
  final Future<void> Function(FinancialMonth month) onOpenMonth;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final months = controller.availableMonths;

        if (months.isEmpty) {
          return const _EmptyFinancialHistory();
        }

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Resumo mensal',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Consulte os meses já criados e abra qualquer período para editar.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            for (final month in months)
              _FinancialMonthCard(
                controller: controller,
                month: month,
                totalPendingInCents: controller.totalPendingInCentsForMonth(
                  month,
                ),
                balanceInCents: controller.balanceInCentsForMonth(month),
                isCurrent:
                    month.storageKey == controller.currentMonth.storageKey,
                onOpen: () => onOpenMonth(month),
              ),
          ],
        );
      },
    );
  }
}

class _FinancialMonthCard extends StatelessWidget {
  const _FinancialMonthCard({
    required this.controller,
    required this.month,
    required this.totalPendingInCents,
    required this.balanceInCents,
    required this.isCurrent,
    required this.onOpen,
  });

  final FinancialMonthController controller;
  final FinancialMonth month;
  final int totalPendingInCents;
  final int balanceInCents;
  final bool isCurrent;
  final Future<void> Function() onOpen;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final monthFormatter = DateFormat('MMMM yyyy', 'pt_BR');
    final monthLabel = toBeginningOfSentenceCase(
      monthFormatter.format(month.date),
    );
    final hasSurplus = balanceInCents >= 0;
    final balanceColor = hasSurplus ? Colors.green : Colors.redAccent;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(child: const Icon(Icons.calendar_month_outlined)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        monthLabel,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        isCurrent ? 'Mês aberto no momento' : 'Mês salvo',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: balanceColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    hasSurplus ? 'Sobra' : 'Falta',
                    style: TextStyle(
                      color: balanceColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth >= 560
                    ? (constraints.maxWidth - 24) / 3
                    : constraints.maxWidth;

                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _HistoryValue(
                      width: width,
                      label: 'A pagar',
                      value: currency.format(totalPendingInCents / 100),
                    ),
                    _HistoryValue(
                      width: width,
                      label: 'Disponível',
                      value: currency.format(month.totalAvailableInCents / 100),
                    ),
                    _HistoryValue(
                      key: ValueKey('history-balance-details-${month.storageKey}'),
                      width: width,
                      label: hasSurplus ? 'Sobra' : 'Falta',
                      value: currency.format(balanceInCents.abs() / 100),
                      color: balanceColor,
                      onTap: () => BalanceDetailsDialog.show(
                        context,
                        controller: controller,
                        month: month,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.tonalIcon(
                onPressed: isCurrent
                    ? null
                    : () async {
                        await onOpen();
                      },
                icon: const Icon(Icons.open_in_new),
                label: Text(isCurrent ? 'Mês atual' : 'Abrir mês'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryValue extends StatelessWidget {
  const _HistoryValue({
    super.key,
    required this.width,
    required this.label,
    required this.value,
    this.color,
    this.onTap,
  });

  final double width;
  final String label;
  final String value;
  final Color? color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Material(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        value,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onTap != null)
                  Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyFinancialHistory extends StatelessWidget {
  const _EmptyFinancialHistory();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Os meses financeiros criados aparecerão aqui.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _PurchaseHistoryPage extends StatelessWidget {
  _PurchaseHistoryPage({required this.controller});

  final FinancialMonthController controller;

  final NumberFormat currencyFormatter = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
    decimalDigits: 2,
  );

  final DateFormat dateFormatter = DateFormat('dd/MM/yyyy', 'pt_BR');

  Future<void> openEditPurchasePage(
    BuildContext context,
    PurchaseRecord record,
  ) async {
    final result = await Navigator.push<PurchaseEditResult>(
      context,
      MaterialPageRoute(
        builder: (context) {
          return EditPurchasePage(controller: controller, record: record);
        },
      ),
    );

    if (result == null || !context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result == PurchaseEditResult.deleted
              ? 'Compra "${record.entry.name}" excluída.'
              : 'Compra atualizada com sucesso!',
        ),
      ),
    );
  }

  Future<void> confirmDeletePurchase(
    BuildContext context,
    PurchaseRecord record,
  ) async {
    if (!await showPurchaseDeleteConfirmation(context, record)) {
      return;
    }

    await controller.removePurchase(record);

    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Compra "${record.entry.name}" excluída.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final purchases = controller.purchaseRecords;
        if (purchases.isEmpty) {
          return const _EmptyPurchaseHistory();
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: purchases.length,
          itemBuilder: (context, index) {
            final record = purchases[index];
            final purchase = record.entry;
            final cardName =
                purchase.relatedCardName ?? 'Cartão não encontrado';

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                leading: CircleAvatar(
                  backgroundColor: Color(purchase.cardColor ?? 0xFF455A64),
                  child: const Icon(
                    Icons.shopping_bag_outlined,
                    color: Colors.white,
                  ),
                ),
                title: Text(
                  purchase.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  '$cardName\n${dateFormatter.format(record.purchaseDate)}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          currencyFormatter.format(
                            purchase.amountInCents / 100,
                          ),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          (purchase.installments ?? 1) == 1
                              ? 'À vista'
                              : '${purchase.installments}x',
                        ),
                      ],
                    ),
                    IconButton(
                      key: ValueKey('delete-purchase-${purchase.id}'),
                      onPressed: () => confirmDeletePurchase(context, record),
                      tooltip: 'Excluir ${purchase.name}',
                      icon: Icon(
                        Icons.delete_outline,
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ),
                onTap: () => openEditPurchasePage(context, record),
                onLongPress: () => confirmDeletePurchase(context, record),
              ),
            );
          },
        );
      },
    );
  }
}

class _EmptyPurchaseHistory extends StatelessWidget {
  const _EmptyPurchaseHistory();

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
