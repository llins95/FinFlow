import 'package:flutter/material.dart';

import '../../../controllers/financial_month_controller.dart';
import '../../../models/financial_entry.dart';
import '../../../shared/mock_data.dart';
import '../../dashboard/widgets/credit_card_tile.dart';
import '../../finance/widgets/financial_entry_dialog.dart';

class CardsPage extends StatelessWidget {
  const CardsPage({super.key, required this.controller});

  final FinancialMonthController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final invoices = controller.currentMonth.entriesOfType(
          FinancialEntryType.cardInvoice,
        );

        return Scaffold(
          appBar: AppBar(title: const Text('Cartões e faturas')),
          body: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            itemCount: mockCards.length,
            itemBuilder: (context, index) {
              final card = mockCards[index];
              final matchingInvoices = invoices.where(
                (entry) => entry.relatedCardId == card.id,
              );
              final invoice = matchingInvoices.isEmpty
                  ? null
                  : matchingInvoices.first;

              return CreditCardTile(
                card: card,
                invoiceInCents: invoice?.amountInCents,
                onEditInvoice: invoice == null
                    ? null
                    : () => _editInvoice(context, invoice),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _editInvoice(
    BuildContext context,
    FinancialEntry invoice,
  ) async {
    final draft = await FinancialEntryDialog.show(
      context,
      title: 'Atualizar fatura ${invoice.name}',
      initialName: invoice.name,
      initialAmountInCents: invoice.amountInCents,
      initialRecurring: true,
      allowNameEditing: false,
    );

    if (draft == null) {
      return;
    }

    await controller.updateEntry(
      invoice.copyWith(amountInCents: draft.amountInCents),
    );
  }
}
