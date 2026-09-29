import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../controllers/financial_month_controller.dart';
import '../../../models/financial_entry.dart';
import '../../../models/purchase_record.dart';
import '../../../utils/money_parser.dart';
import '../../../utils/select_all_on_focus.dart';
import '../widgets/purchase_delete_confirmation.dart';

enum PurchaseEditResult { updated, deleted }

class EditPurchasePage extends StatefulWidget {
  const EditPurchasePage({
    super.key,
    required this.controller,
    required this.record,
  });

  final FinancialMonthController controller;
  final PurchaseRecord record;

  @override
  State<EditPurchasePage> createState() => _EditPurchasePageState();
}

class _EditPurchasePageState extends State<EditPurchasePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _descriptionController;
  late final TextEditingController _amountController;
  late final TextEditingController _installmentsController;
  late final SelectAllOnFocusNode _amountFocusNode;
  late final SelectAllOnFocusNode _installmentsFocusNode;
  late String _selectedCardId;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    final purchase = widget.record.entry;
    final formatter = NumberFormat('#,##0.00', 'pt_BR');

    _descriptionController = TextEditingController(text: purchase.name);
    _amountController = TextEditingController(
      text: formatter.format(purchase.amountInCents / 100),
    );
    _installmentsController = TextEditingController(
      text: (purchase.installments ?? 1).toString(),
    );
    _amountFocusNode = SelectAllOnFocusNode(_amountController);
    _installmentsFocusNode = SelectAllOnFocusNode(_installmentsController);
    _selectedDate = widget.record.purchaseDate;
    _selectedCardId = purchase.relatedCardId ?? '';
  }

  @override
  void dispose() {
    _amountFocusNode.dispose();
    _installmentsFocusNode.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    _installmentsController.dispose();
    super.dispose();
  }

  FinancialEntry _selectedCard(List<FinancialEntry> cards) {
    for (final card in cards) {
      if ((card.relatedCardId ?? card.id) == _selectedCardId) {
        return card;
      }
    }
    return cards.first;
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      locale: const Locale('pt', 'BR'),
      initialDate: _selectedDate,
      firstDate: FinancialMonthController.firstMonth,
      lastDate: DateTime(2100, 12, 31),
    );
    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  Future<void> _save(List<FinancialEntry> cards) async {
    if (!(_formKey.currentState?.validate() ?? false) || cards.isEmpty) {
      return;
    }

    await widget.controller.updatePurchase(
      record: widget.record,
      description: _descriptionController.text.trim(),
      amountInCents: MoneyParser.parseToCents(_amountController.text)!,
      installments: int.parse(_installmentsController.text),
      purchaseDate: _selectedDate,
      cardInvoice: _selectedCard(cards),
    );

    if (mounted) {
      Navigator.pop(context, PurchaseEditResult.updated);
    }
  }

  Future<void> _delete() async {
    if (!await showPurchaseDeleteConfirmation(context, widget.record)) {
      return;
    }

    await widget.controller.removePurchase(widget.record);
    if (mounted) {
      Navigator.pop(context, PurchaseEditResult.deleted);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cards = widget.controller.purchaseCardOptions;
    if (cards.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Editar compra')),
        body: const Center(
          child: Text('Nenhum cartão disponível para esta compra.'),
        ),
      );
    }

    if (!cards.any(
      (card) => (card.relatedCardId ?? card.id) == _selectedCardId,
    )) {
      _selectedCardId = cards.first.relatedCardId ?? cards.first.id;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Editar compra')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _descriptionController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Descrição',
                border: OutlineInputBorder(),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Informe uma descrição.'
                  : null,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _amountController,
              focusNode: _amountFocusNode,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
              ],
              decoration: const InputDecoration(
                labelText: 'Valor',
                prefixText: 'R\$ ',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                final amount = MoneyParser.parseToCents(value ?? '');
                return amount == null || amount <= 0
                    ? 'Informe um valor maior que zero.'
                    : null;
              },
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _installmentsController,
              focusNode: _installmentsFocusNode,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(2),
              ],
              decoration: const InputDecoration(
                labelText: 'Parcelas',
                suffixText: 'x',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                final installments = int.tryParse(value ?? '');
                return installments == null ||
                        installments < 1 ||
                        installments > 99
                    ? 'Use um valor entre 1 e 99.'
                    : null;
              },
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              initialValue: _selectedCardId,
              decoration: const InputDecoration(
                labelText: 'Cartão',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final card in cards)
                  DropdownMenuItem(
                    value: card.relatedCardId ?? card.id,
                    child: Text(card.name),
                  ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedCardId = value);
                }
              },
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: _selectDate,
              icon: const Icon(Icons.calendar_month),
              label: Text(
                DateFormat('dd/MM/yyyy', 'pt_BR').format(_selectedDate),
              ),
            ),
            const SizedBox(height: 30),
            FilledButton.icon(
              onPressed: () => _save(cards),
              icon: const Icon(Icons.save),
              label: const Text('Salvar alterações'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              key: const ValueKey('delete-purchase-from-edit'),
              onPressed: _delete,
              icon: const Icon(Icons.delete_outline),
              label: const Text('Excluir compra'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
