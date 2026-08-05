import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../models/credit_card.dart';
import '../../../utils/money_parser.dart';

class CardEditorDraft {
  final String name;
  final String bank;
  final String brand;
  final int limitInCents;
  final int closingDay;
  final int dueDay;
  final int color;
  final bool isActive;

  const CardEditorDraft({
    required this.name,
    required this.bank,
    required this.brand,
    required this.limitInCents,
    required this.closingDay,
    required this.dueDay,
    required this.color,
    required this.isActive,
  });
}

class CardEditorDialog extends StatefulWidget {
  const CardEditorDialog({
    super.key,
    required this.title,
    this.initialCard,
  });

  final String title;
  final CreditCard? initialCard;

  static const colors = <int>[
    0xFF21C25E,
    0xFF8A05BE,
    0xFFF58220,
    0xFFFFD700,
    0xFF009EE3,
    0xFFE30613,
    0xFF00D7FF,
    0xFF455A64,
  ];

  static Future<CardEditorDraft?> show(
    BuildContext context, {
    required String title,
    CreditCard? initialCard,
  }) {
    return showDialog<CardEditorDraft>(
      context: context,
      builder: (context) => CardEditorDialog(
        title: title,
        initialCard: initialCard,
      ),
    );
  }

  @override
  State<CardEditorDialog> createState() => _CardEditorDialogState();
}

class _CardEditorDialogState extends State<CardEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _bankController;
  late final TextEditingController _brandController;
  late final TextEditingController _limitController;
  late final TextEditingController _closingDayController;
  late final TextEditingController _dueDayController;
  late int _selectedColor;
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    final card = widget.initialCard;
    final formatter = NumberFormat('#,##0.00', 'pt_BR');

    _nameController = TextEditingController(text: card?.name ?? '');
    _bankController = TextEditingController(text: card?.bank ?? '');
    _brandController = TextEditingController(text: card?.brand ?? '');
    _limitController = TextEditingController(
      text: card == null ? '' : formatter.format(card.limit),
    );
    _closingDayController = TextEditingController(
      text: card?.closingDay.toString() ?? '',
    );
    _dueDayController = TextEditingController(
      text: card?.dueDay.toString() ?? '',
    );
    _selectedColor = card?.color ?? CardEditorDialog.colors.first;
    _isActive = card?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bankController.dispose();
    _brandController.dispose();
    _limitController.dispose();
    _closingDayController.dispose();
    _dueDayController.dispose();
    super.dispose();
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    Navigator.of(context).pop(
      CardEditorDraft(
        name: _nameController.text.trim(),
        bank: _bankController.text.trim(),
        brand: _brandController.text.trim(),
        limitInCents: MoneyParser.parseToCents(_limitController.text)!,
        closingDay: int.parse(_closingDayController.text),
        dueDay: int.parse(_dueDayController.text),
        color: _selectedColor,
        isActive: _isActive,
      ),
    );
  }

  String? _requiredText(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Campo obrigatório.';
    }
    return null;
  }

  String? _validateMoney(String? value) {
    final amount = MoneyParser.parseToCents(value ?? '');
    if (amount == null || amount < 0) {
      return 'Informe um limite válido.';
    }
    return null;
  }

  String? _validateDay(String? value) {
    final day = int.tryParse(value ?? '');
    if (day == null || day < 1 || day > 31) {
      return 'Use um dia entre 1 e 31.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Nome do cartão',
                    border: OutlineInputBorder(),
                  ),
                  validator: _requiredText,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _bankController,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Banco',
                          border: OutlineInputBorder(),
                        ),
                        validator: _requiredText,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _brandController,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Bandeira',
                          border: OutlineInputBorder(),
                        ),
                        validator: _requiredText,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _limitController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Limite',
                    prefixText: 'R\$ ',
                    border: OutlineInputBorder(),
                  ),
                  validator: _validateMoney,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _closingDayController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: const InputDecoration(
                          labelText: 'Dia de fechamento',
                          border: OutlineInputBorder(),
                        ),
                        validator: _validateDay,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _dueDayController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: const InputDecoration(
                          labelText: 'Dia de vencimento',
                          border: OutlineInputBorder(),
                        ),
                        validator: _validateDay,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Cor do cartão',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: CardEditorDialog.colors.map((color) {
                    final selected = color == _selectedColor;
                    return Semantics(
                      label: selected ? 'Cor selecionada' : 'Selecionar cor',
                      button: true,
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => setState(() => _selectedColor = color),
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: Color(color),
                          child: selected
                              ? const Icon(Icons.check, color: Colors.white)
                              : null,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _isActive,
                  title: const Text('Cartão ativo'),
                  subtitle: const Text(
                    'Cartões inativos não são copiados para o próximo mês.',
                  ),
                  onChanged: (value) => setState(() => _isActive = value),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _save, child: const Text('Salvar')),
      ],
    );
  }
}
