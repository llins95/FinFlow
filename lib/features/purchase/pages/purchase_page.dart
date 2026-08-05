import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../controllers/financial_month_controller.dart';
import '../../../models/financial_entry.dart';
import '../../../services/finance_service.dart';
import '../../../utils/card_mapper.dart';
import '../../../utils/money_parser.dart';

class PurchasePage extends StatefulWidget {
  const PurchasePage({
    super.key,
    required this.controller,
  });

  final FinancialMonthController controller;

  @override
  State<PurchasePage> createState() => _PurchasePageState();
}

class _PurchasePageState extends State<PurchasePage> {
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController(text: '150,00');
  final _installmentsController = TextEditingController(text: '1');
  final _amountFocusNode = FocusNode();

  final _currency = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
    decimalDigits: 2,
  );
  final _inputCurrency = NumberFormat('#,##0.00', 'pt_BR');
  final _dateFormat = DateFormat('dd/MM/yyyy', 'pt_BR');

  String? _selectedCardId;
  int _installments = 1;
  late DateTime _purchaseDate;
  bool _showSimulation = false;
  bool _purchaseSaved = false;

  int get _amountInCents =>
      MoneyParser.parseToCents(_amountController.text) ?? 0;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _purchaseDate = today.isBefore(FinancialMonthController.firstMonth)
        ? FinancialMonthController.firstMonth
        : DateTime(today.year, today.month, today.day);
    _amountFocusNode.addListener(() {
      if (!_amountFocusNode.hasFocus) {
        _formatAmount();
      }
    });
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _installmentsController.dispose();
    _amountFocusNode.dispose();
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

  void _markChanged() {
    setState(() {
      _showSimulation = false;
      _purchaseSaved = false;
    });
  }

  void _formatAmount() {
    _amountController.text = _inputCurrency.format(_amountInCents / 100);
    _amountController.selection = TextSelection.collapsed(
      offset: _amountController.text.length,
    );
  }

  bool _validate(List<FinancialEntry> cards) {
    if (cards.isEmpty) {
      _showMessage('Cadastre ou ative um cartão antes de salvar a compra.');
      return false;
    }
    if (_descriptionController.text.trim().isEmpty) {
      _showMessage('Informe uma descrição para a compra.');
      return false;
    }
    if (_amountInCents <= 0) {
      _showMessage('Informe um valor de compra maior que zero.');
      return false;
    }

    final typedInstallments = int.tryParse(
      _installmentsController.text.trim(),
    );
    if (typedInstallments == null || typedInstallments < 1) {
      _showMessage('Informe uma quantidade válida de parcelas.');
      return false;
    }
    return true;
  }

  void _simulate(List<FinancialEntry> cards) {
    _formatAmount();
    if (!_validate(cards)) {
      return;
    }

    final typedInstallments = int.parse(
      _installmentsController.text.trim(),
    );
    final safeInstallments = typedInstallments.clamp(1, 99);
    _installmentsController.text = safeInstallments.toString();
    FocusScope.of(context).unfocus();

    setState(() {
      _installments = safeInstallments;
      _showSimulation = true;
      _purchaseSaved = false;
    });
  }

  Future<void> _save(List<FinancialEntry> cards) async {
    if (!_validate(cards)) {
      return;
    }
    if (_purchaseSaved) {
      _showMessage('Esta compra já foi salva.');
      return;
    }

    await widget.controller.addPurchase(
      description: _descriptionController.text.trim(),
      amountInCents: _amountInCents,
      installments: _installments,
      purchaseDate: _purchaseDate,
      cardInvoice: _selectedCard(cards),
    );

    if (!mounted) {
      return;
    }
    setState(() => _purchaseSaved = true);
    _showMessage('Compra salva e incluída na sincronização.');
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      locale: const Locale('pt', 'BR'),
      initialDate: _purchaseDate,
      firstDate: FinancialMonthController.firstMonth,
      lastDate: DateTime(2100, 12, 31),
      helpText: 'Selecione a data da compra',
      cancelText: 'Cancelar',
      confirmText: 'Confirmar',
    );
    if (date == null) {
      return;
    }

    setState(() {
      _purchaseDate = date;
      _showSimulation = false;
      _purchaseSaved = false;
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  List<int> _installmentAmounts() {
    final base = _amountInCents ~/ _installments;
    final remainder = _amountInCents % _installments;
    return List.generate(
      _installments,
      (index) => base + (index < remainder ? 1 : 0),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final cards = widget.controller.activeCardInvoices;
        if (cards.isEmpty) {
          return const _NoCardsForPurchase();
        }

        final selectedInvoice = _selectedCard(cards);
        final selectedCard = creditCardFromInvoice(selectedInvoice);
        final selectedId = selectedInvoice.relatedCardId ?? selectedInvoice.id;
        _selectedCardId ??= selectedId;

        final firstInvoiceDate = selectedCard.invoiceForPurchase(_purchaseDate);
        final installmentDates = List<DateTime>.generate(
          _installments,
          (index) => FinanceService.addMonths(firstInvoiceDate, index),
        );
        final installmentAmounts = _installmentAmounts();

        return Scaffold(
          appBar: AppBar(title: const Text('Simular compra')),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              DropdownButtonFormField<String>(
                initialValue: selectedId,
                decoration: const InputDecoration(
                  labelText: 'Cartão',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.credit_card),
                ),
                items: [
                  for (final invoice in cards)
                    DropdownMenuItem<String>(
                      value: invoice.relatedCardId ?? invoice.id,
                      child: Text(invoice.name),
                    ),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedCardId = value;
                    _showSimulation = false;
                    _purchaseSaved = false;
                  });
                },
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _descriptionController,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Descrição da compra',
                  hintText: 'Ex.: Smart TV Samsung',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.shopping_bag_outlined),
                ),
                onChanged: (_) => _markChanged(),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _amountController,
                focusNode: _amountFocusNode,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Valor da compra',
                  prefixText: 'R\$ ',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                ),
                onChanged: (_) => _markChanged(),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _installmentsController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(2),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Parcelas',
                        suffixText: 'x',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_view_month),
                      ),
                      onChanged: (value) {
                        final parsed = int.tryParse(value);
                        setState(() {
                          if (parsed != null && parsed > 0) {
                            _installments = parsed.clamp(1, 99);
                          }
                          _showSimulation = false;
                          _purchaseSaved = false;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 150,
                    child: DropdownButtonFormField<int>(
                      initialValue: _installments <= 24
                          ? _installments
                          : null,
                      decoration: const InputDecoration(
                        labelText: 'Seleção rápida',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        for (var value = 1; value <= 24; value++)
                          DropdownMenuItem(
                            value: value,
                            child: Text(value == 1 ? 'À vista' : '${value}x'),
                          ),
                      ],
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }
                        _installmentsController.text = value.toString();
                        setState(() {
                          _installments = value;
                          _showSimulation = false;
                          _purchaseSaved = false;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _selectDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Data da compra',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_month),
                  ),
                  child: Text(_dateFormat.format(_purchaseDate)),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () => _simulate(cards),
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Simular parcelas'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                ),
              ),
              if (_showSimulation) ...[
                const SizedBox(height: 24),
                _SimulationResult(
                  description: _descriptionController.text.trim(),
                  cardName: selectedCard.name,
                  purchaseAmount: _currency.format(_amountInCents / 100),
                  purchaseDate: _dateFormat.format(_purchaseDate),
                  firstInvoiceDate: _dateFormat.format(firstInvoiceDate),
                  daysToPay: selectedCard.daysToPay(_purchaseDate),
                  installmentDates: installmentDates,
                  installmentAmounts: installmentAmounts,
                  currency: _currency,
                  dateFormat: _dateFormat,
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: _purchaseSaved ? null : () => _save(cards),
                  icon: Icon(
                    _purchaseSaved ? Icons.check_circle : Icons.save_outlined,
                  ),
                  label: Text(
                    _purchaseSaved ? 'Compra salva' : 'Salvar compra',
                  ),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _SimulationResult extends StatelessWidget {
  const _SimulationResult({
    required this.description,
    required this.cardName,
    required this.purchaseAmount,
    required this.purchaseDate,
    required this.firstInvoiceDate,
    required this.daysToPay,
    required this.installmentDates,
    required this.installmentAmounts,
    required this.currency,
    required this.dateFormat,
  });

  final String description;
  final String cardName;
  final String purchaseAmount;
  final String purchaseDate;
  final String firstInvoiceDate;
  final int daysToPay;
  final List<DateTime> installmentDates;
  final List<int> installmentAmounts;
  final NumberFormat currency;
  final DateFormat dateFormat;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resultado da simulação',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(description, style: Theme.of(context).textTheme.titleMedium),
            Text('$cardName • compra em $purchaseDate'),
            const SizedBox(height: 12),
            Text(
              purchaseAmount,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Primeiro vencimento: $firstInvoiceDate '
              '($daysToPay dias para pagar)',
            ),
            const Divider(height: 28),
            for (var index = 0; index < installmentDates.length; index++)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(child: Text('${index + 1}')),
                title: Text(
                  '${index + 1}/${installmentDates.length} • '
                  '${dateFormat.format(installmentDates[index])}',
                ),
                trailing: Text(
                  currency.format(installmentAmounts[index] / 100),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NoCardsForPurchase extends StatelessWidget {
  const _NoCardsForPurchase();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Simular compra')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Cadastre ou ative um cartão na aba Cartões antes de registrar '
            'uma compra.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
