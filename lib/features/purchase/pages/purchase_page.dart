import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../models/purchase.dart';
import '../../../shared/mock_data.dart';
import '../../../shared/purchase_repository.dart';

class PurchasePage extends StatefulWidget {
  const PurchasePage({super.key});

  @override
  State<PurchasePage> createState() => _PurchasePageState();
}

class _PurchasePageState extends State<PurchasePage> {
  final TextEditingController descriptionController = TextEditingController();

  final TextEditingController amountController = TextEditingController(
    text: '150,00',
  );

  final TextEditingController installmentsController = TextEditingController(
    text: '1',
  );

  final FocusNode amountFocusNode = FocusNode();

  final Uuid uuid = const Uuid();

  int selectedCardIndex = 0;
  int installments = 1;

  DateTime selectedPurchaseDate = DateTime.now();

  bool showSimulationResult = false;
  bool purchaseSaved = false;

  final NumberFormat currencyFormatter = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
    decimalDigits: 2,
  );

  final NumberFormat inputCurrencyFormatter = NumberFormat('#,##0.00', 'pt_BR');

  final DateFormat dateFormatter = DateFormat('dd/MM/yyyy', 'pt_BR');

  @override
  void initState() {
    super.initState();

    amountFocusNode.addListener(() {
      if (!amountFocusNode.hasFocus) {
        formatAmountField();
      }
    });
  }

  @override
  void dispose() {
    descriptionController.dispose();
    amountController.dispose();
    installmentsController.dispose();
    amountFocusNode.dispose();

    super.dispose();
  }

  double get purchaseAmount {
    var value = amountController.text.trim();

    value = value.replaceAll('R\$', '');
    value = value.replaceAll(' ', '');

    if (value.contains(',')) {
      value = value.replaceAll('.', '');
      value = value.replaceAll(',', '.');
    }

    return double.tryParse(value) ?? 0;
  }

  int get purchaseAmountInCents {
    return (purchaseAmount * 100).round();
  }

  List<int> get installmentAmountsInCents {
    if (installments <= 0) {
      return [];
    }

    final totalInCents = purchaseAmountInCents;
    final baseAmount = totalInCents ~/ installments;
    final remainder = totalInCents % installments;

    return List.generate(installments, (index) {
      if (index < remainder) {
        return baseAmount + 1;
      }

      return baseAmount;
    });
  }

  double amountFromCents(int valueInCents) {
    return valueInCents / 100;
  }

  void markFormAsChanged() {
    setState(() {
      showSimulationResult = false;
      purchaseSaved = false;
    });
  }

  void formatAmountField() {
    final amount = purchaseAmount;

    amountController.text = inputCurrencyFormatter.format(amount);

    amountController.selection = TextSelection.collapsed(
      offset: amountController.text.length,
    );
  }

  void updateInstallments(int value) {
    final safeValue = value.clamp(1, 99);

    installmentsController.text = safeValue.toString();

    installmentsController.selection = TextSelection.collapsed(
      offset: installmentsController.text.length,
    );

    setState(() {
      installments = safeValue;
      showSimulationResult = false;
      purchaseSaved = false;
    });
  }

  bool validateForm() {
    final description = descriptionController.text.trim();

    final typedInstallments = int.tryParse(installmentsController.text.trim());

    if (description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe uma descrição para a compra.')),
      );

      return false;
    }

    if (purchaseAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Informe um valor de compra maior que zero.'),
        ),
      );

      return false;
    }

    if (typedInstallments == null || typedInstallments < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Informe uma quantidade válida de parcelas.'),
        ),
      );

      return false;
    }

    return true;
  }

  void simulatePurchase() {
    formatAmountField();

    if (!validateForm()) {
      return;
    }

    final typedInstallments = int.parse(installmentsController.text.trim());

    final safeInstallments = typedInstallments.clamp(1, 99);

    installmentsController.text = safeInstallments.toString();

    FocusScope.of(context).unfocus();

    setState(() {
      installments = safeInstallments;
      showSimulationResult = true;
      purchaseSaved = false;
    });
  }

  Future<void> savePurchase() async {
    if (!validateForm()) {
      return;
    }

    if (purchaseSaved) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Esta compra já foi salva.')),
      );

      return;
    }

    final selectedCard = mockCards[selectedCardIndex];

    final purchase = Purchase(
      id: uuid.v4(),
      description: descriptionController.text.trim(),
      amount: purchaseAmount,
      cardId: selectedCard.id,
      installments: installments,
      purchaseDate: selectedPurchaseDate,
    );

    await PurchaseRepository.add(purchase);

    if (!mounted) {
      return;
    }

    setState(() {
      purchaseSaved = true;
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Compra salva com sucesso!')));
  }

  Future<void> selectPurchaseDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      locale: const Locale('pt', 'BR'),
      initialDate: selectedPurchaseDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'Selecione a data da compra',
      cancelText: 'Cancelar',
      confirmText: 'Confirmar',
      fieldLabelText: 'Data da compra',
      fieldHintText: 'dd/mm/aaaa',
    );

    if (selectedDate == null) {
      return;
    }

    setState(() {
      selectedPurchaseDate = selectedDate;
      showSimulationResult = false;
      purchaseSaved = false;
    });
  }

  DateTime addMonths(DateTime date, int monthsToAdd) {
    final totalMonths = date.month - 1 + monthsToAdd;

    final newYear = date.year + totalMonths ~/ 12;
    final newMonth = totalMonths % 12 + 1;

    final lastDayOfNewMonth = DateTime(newYear, newMonth + 1, 0).day;

    final safeDay = date.day > lastDayOfNewMonth ? lastDayOfNewMonth : date.day;

    return DateTime(newYear, newMonth, safeDay);
  }

  List<DateTime> buildInstallmentDates(DateTime firstInvoiceDate) {
    return List.generate(installments, (index) {
      return addMonths(firstInvoiceDate, index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectedCard = mockCards[selectedCardIndex];

    final firstInvoiceDate = selectedCard.invoiceForPurchase(
      selectedPurchaseDate,
    );

    final daysToPay = selectedCard.daysToPay(selectedPurchaseDate);

    final goesToNextInvoice =
        selectedPurchaseDate.day > selectedCard.closingDay;

    final installmentDates = buildInstallmentDates(firstInvoiceDate);

    final installmentAmounts = installmentAmountsInCents;

    return Scaffold(
      appBar: AppBar(title: const Text('Simular compra')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          DropdownButtonFormField<int>(
            initialValue: selectedCardIndex,
            decoration: const InputDecoration(
              labelText: 'Cartão',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.credit_card),
            ),
            items: List.generate(mockCards.length, (index) {
              final card = mockCards[index];

              return DropdownMenuItem<int>(
                value: index,
                child: Text(card.name),
              );
            }),
            onChanged: (value) {
              if (value == null) {
                return;
              }

              setState(() {
                selectedCardIndex = value;
                showSimulationResult = false;
                purchaseSaved = false;
              });
            },
          ),
          const SizedBox(height: 20),
          TextField(
            controller: descriptionController,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Descrição da compra',
              hintText: 'Ex.: Smart TV Samsung',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.shopping_bag_outlined),
            ),
            onChanged: (_) {
              markFormAsChanged();
            },
          ),
          const SizedBox(height: 20),
          TextField(
            controller: amountController,
            focusNode: amountFocusNode,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.next,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
            ],
            decoration: const InputDecoration(
              labelText: 'Valor da compra',
              hintText: '0,00',
              prefixText: 'R\$ ',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.attach_money),
            ),
            onChanged: (_) {
              markFormAsChanged();
            },
            onSubmitted: (_) {
              formatAmountField();
              FocusScope.of(context).unfocus();
            },
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: installmentsController,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(2),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Quantidade de parcelas',
                    hintText: '1',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_view_month),
                    suffixText: 'x',
                  ),
                  onChanged: (value) {
                    final parsedValue = int.tryParse(value);

                    if (parsedValue == null || parsedValue < 1) {
                      setState(() {
                        showSimulationResult = false;
                        purchaseSaved = false;
                      });

                      return;
                    }

                    setState(() {
                      installments = parsedValue.clamp(1, 99);

                      showSimulationResult = false;
                      purchaseSaved = false;
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 150,
                child: DropdownButtonFormField<int>(
                  initialValue: installments <= 24 ? installments : null,
                  decoration: const InputDecoration(
                    labelText: 'Seleção rápida',
                    border: OutlineInputBorder(),
                  ),
                  hint: const Text('Escolher'),
                  items: List.generate(24, (index) {
                    final value = index + 1;

                    return DropdownMenuItem<int>(
                      value: value,
                      child: Text(value == 1 ? 'À vista' : '${value}x'),
                    );
                  }),
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }

                    updateInstallments(value);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: selectPurchaseDate,
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Data da compra',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.calendar_month),
              ),
              child: Text(
                dateFormatter.format(selectedPurchaseDate),
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: simulatePurchase,
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Próximo'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
            ),
          ),
          if (showSimulationResult) ...[
            const SizedBox(height: 28),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Resultado da simulação',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Descrição',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      descriptionController.text.trim(),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Valor da compra',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      currencyFormatter.format(purchaseAmount),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Parcelamento',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      installments == 1 ? 'À vista' : '$installments parcelas',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Cartão selecionado',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      selectedCard.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Data da compra',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      dateFormatter.format(selectedPurchaseDate),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Vencimento da primeira parcela',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      dateFormatter.format(firstInvoiceDate),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Prazo até o primeiro pagamento',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$daysToPay dias',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: goesToNextInvoice
                            ? Colors.green.withValues(alpha: 0.15)
                            : Colors.orange.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            goesToNextInvoice
                                ? Icons.check_circle
                                : Icons.warning_amber_rounded,
                            color: goesToNextInvoice
                                ? Colors.green
                                : Colors.orange,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              goesToNextInvoice
                                  ? 'A primeira parcela entrará '
                                        'na próxima fatura.'
                                  : 'A primeira parcela entrará '
                                        'na fatura atual.',
                              style: TextStyle(
                                color: goesToNextInvoice
                                    ? Colors.green
                                    : Colors.orange,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Cronograma das parcelas',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      installments == 1
                          ? 'Pagamento em uma única fatura.'
                          : 'Veja o vencimento e o valor '
                                'de cada parcela.',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 20),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: installments,
                      separatorBuilder: (context, index) {
                        return const Divider(height: 24);
                      },
                      itemBuilder: (context, index) {
                        final installmentNumber = index + 1;

                        final installmentDate = installmentDates[index];

                        final installmentValue = amountFromCents(
                          installmentAmounts[index],
                        );

                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            child: Text('$installmentNumber'),
                          ),
                          title: Text(
                            '$installmentNumber/'
                            '$installments',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'Vencimento: '
                            '${dateFormatter.format(installmentDate)}',
                          ),
                          trailing: Text(
                            currencyFormatter.format(installmentValue),
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: purchaseSaved ? null : savePurchase,
              icon: Icon(purchaseSaved ? Icons.check : Icons.save),
              label: Text(purchaseSaved ? 'Compra salva' : 'Salvar compra'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
