import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../controllers/financial_month_controller.dart';
import '../../../models/credit_card.dart';
import '../../../models/financial_entry.dart';
import '../../../utils/card_mapper.dart';
import '../../dashboard/widgets/credit_card_tile.dart';
import '../../finance/widgets/financial_entry_dialog.dart';
import '../widgets/card_editor_dialog.dart';

class CardsPage extends StatelessWidget {
  const CardsPage({super.key, required this.controller});

  final FinancialMonthController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final invoices =
            controller.currentMonth.entriesOfType(
              FinancialEntryType.cardInvoice,
            )..sort((first, second) {
              if (first.isActive != second.isActive) {
                return first.isActive ? -1 : 1;
              }
              return (first.closingDay ?? 32).compareTo(
                second.closingDay ?? 32,
              );
            });
        final monthLabel = _monthLabel(controller.currentMonth.date);

        return Scaffold(
          appBar: AppBar(
            title: Text('Cartões e faturas — $monthLabel'),
            actions: [
              IconButton(
                onPressed: () => _addCard(context),
                tooltip: 'Adicionar cartão',
                icon: const Icon(Icons.add_card_outlined),
              ),
            ],
          ),
          body: invoices.isEmpty
              ? _EmptyCards(onAdd: () => _addCard(context))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  itemCount: invoices.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return const Padding(
                        padding: EdgeInsets.only(bottom: 16),
                        child: Text(
                          'Os dados do cartão e o valor da fatura são '
                          'sincronizados entre seus aparelhos.',
                        ),
                      );
                    }

                    final invoice = invoices[index - 1];
                    final card = creditCardFromInvoice(invoice);

                    return CreditCardTile(
                      card: card,
                      invoiceMonth: controller.currentMonth.date,
                      invoiceInCents: controller.cardInvoiceTotalInCents(
                        invoice,
                      ),
                      automaticPurchasesInCents: controller
                          .purchaseInstallmentsForCardInMonth(
                            invoice,
                            controller.currentMonth.date,
                          ),
                      onEditInvoice: () => _editInvoice(context, invoice),
                      onEditCard: () => _editCard(context, invoice, card),
                    );
                  },
                ),
        );
      },
    );
  }

  Future<void> _addCard(BuildContext context) async {
    final draft = await CardEditorDialog.show(
      context,
      title: 'Adicionar cartão',
    );

    if (draft == null) {
      return;
    }

    await controller.addCardInvoice(
      name: draft.name,
      bank: draft.bank,
      brand: draft.brand,
      limitInCents: draft.limitInCents,
      closingDay: draft.closingDay,
      dueDay: draft.dueDay,
      color: draft.color,
      isActive: draft.isActive,
    );
  }

  Future<void> _editCard(
    BuildContext context,
    FinancialEntry invoice,
    CreditCard card,
  ) async {
    final draft = await CardEditorDialog.show(
      context,
      title: 'Editar cartão',
      initialCard: card,
    );

    if (draft == null) {
      return;
    }

    await controller.updateCardDetails(
      invoice.copyWith(
        name: draft.name,
        isActive: draft.isActive,
        cardBank: draft.bank,
        cardBrand: draft.brand,
        cardLimitInCents: draft.limitInCents,
        cardColor: draft.color,
        closingDay: draft.closingDay,
        dueDay: draft.dueDay,
      ),
    );
  }

  Future<void> _editInvoice(
    BuildContext context,
    FinancialEntry invoice,
  ) async {
    final month = controller.currentMonth.date;
    final automaticAmount = controller.purchaseInstallmentsForCardInMonth(
      invoice,
      month,
    );
    final draft = await FinancialEntryDialog.show(
      context,
      title: 'Editar fatura de ${_monthLabel(month)} • ${invoice.name}',
      initialName: invoice.name,
      initialAmountInCents: invoice.amountInCents + automaticAmount,
      initialRecurring: true,
      allowNameEditing: false,
      amountLabel: 'Total da fatura',
      amountHelperText: automaticAmount == 0
          ? null
          : 'O total já inclui as compras e parcelas deste mês.',
      minimumAmountInCents: automaticAmount,
    );

    if (draft == null) {
      return;
    }

    await controller.updateEntry(
      invoice.copyWith(amountInCents: draft.amountInCents - automaticAmount),
    );
  }

  String _monthLabel(DateTime month) {
    final formatted = DateFormat('MMMM/yyyy', 'pt_BR').format(month);
    return toBeginningOfSentenceCase(formatted);
  }
}

class _EmptyCards extends StatelessWidget {
  const _EmptyCards({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.credit_card_off_outlined, size: 56),
            const SizedBox(height: 16),
            Text(
              'Nenhum cartão neste mês',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Adicionar cartão'),
            ),
          ],
        ),
      ),
    );
  }
}
