import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/purchase.dart';
import '../../../shared/mock_data.dart';
import '../../../shared/purchase_repository.dart';

class EditPurchasePage extends StatefulWidget {
  final Purchase purchase;

  const EditPurchasePage({super.key, required this.purchase});

  @override
  State<EditPurchasePage> createState() => _EditPurchasePageState();
}

class _EditPurchasePageState extends State<EditPurchasePage> {
  late TextEditingController descriptionController;
  late TextEditingController amountController;
  late TextEditingController installmentsController;

  late int selectedCardIndex;
  late DateTime selectedDate;

  final currencyFormatter = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
  );

  @override
  void initState() {
    super.initState();

    descriptionController = TextEditingController(
      text: widget.purchase.description,
    );

    amountController = TextEditingController(
      text: widget.purchase.amount.toStringAsFixed(2).replaceAll('.', ','),
    );

    installmentsController = TextEditingController(
      text: widget.purchase.installments.toString(),
    );

    selectedDate = widget.purchase.purchaseDate;

    selectedCardIndex = mockCards.indexWhere(
      (card) => card.id == widget.purchase.cardId,
    );

    if (selectedCardIndex == -1) {
      selectedCardIndex = 0;
    }
  }

  @override
  void dispose() {
    descriptionController.dispose();
    amountController.dispose();
    installmentsController.dispose();

    super.dispose();
  }

  Future<void> selectDate() async {
    final date = await showDatePicker(
      context: context,
      locale: const Locale('pt', 'BR'),
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (date == null) {
      return;
    }

    setState(() {
      selectedDate = date;
    });
  }

  Future<void> savePurchase() async {
    final value = amountController.text
        .replaceAll('.', '')
        .replaceAll(',', '.');

    final amount = double.tryParse(value) ?? 0;

    final installments = int.tryParse(installmentsController.text) ?? 1;

    final updatedPurchase = Purchase(
      id: widget.purchase.id,
      description: descriptionController.text,
      amount: amount,
      cardId: mockCards[selectedCardIndex].id,
      installments: installments,
      purchaseDate: selectedDate,
    );

    await PurchaseRepository.update(updatedPurchase);

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editar compra')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            controller: descriptionController,
            decoration: const InputDecoration(
              labelText: 'Descrição',
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 20),

          TextField(
            controller: amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Valor',
              prefixText: 'R\$ ',
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 20),

          TextField(
            controller: installmentsController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Parcelas',
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 20),

          DropdownButtonFormField<int>(
            initialValue: selectedCardIndex,
            decoration: const InputDecoration(
              labelText: 'Cartão',
              border: OutlineInputBorder(),
            ),
            items: List.generate(mockCards.length, (index) {
              return DropdownMenuItem(
                value: index,
                child: Text(mockCards[index].name),
              );
            }),
            onChanged: (value) {
              if (value == null) {
                return;
              }

              setState(() {
                selectedCardIndex = value;
              });
            },
          ),

          const SizedBox(height: 20),

          FilledButton.icon(
            onPressed: selectDate,
            icon: const Icon(Icons.calendar_month),
            label: Text(DateFormat('dd/MM/yyyy').format(selectedDate)),
          ),

          const SizedBox(height: 30),

          FilledButton.icon(
            onPressed: savePurchase,
            icon: const Icon(Icons.save),
            label: const Text('Salvar alterações'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
            ),
          ),
        ],
      ),
    );
  }
}
