import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../utils/money_parser.dart';

class FinancialEntryDraft {
  final String name;
  final int amountInCents;
  final bool isRecurring;

  const FinancialEntryDraft({
    required this.name,
    required this.amountInCents,
    required this.isRecurring,
  });
}

class FinancialEntryDialog extends StatefulWidget {
  const FinancialEntryDialog({
    super.key,
    required this.title,
    this.initialName = '',
    this.initialAmountInCents = 0,
    this.initialRecurring = false,
    this.allowNameEditing = true,
    this.showRecurringOption = false,
    this.allowNegative = false,
  });

  final String title;
  final String initialName;
  final int initialAmountInCents;
  final bool initialRecurring;
  final bool allowNameEditing;
  final bool showRecurringOption;
  final bool allowNegative;

  static Future<FinancialEntryDraft?> show(
    BuildContext context, {
    required String title,
    String initialName = '',
    int initialAmountInCents = 0,
    bool initialRecurring = false,
    bool allowNameEditing = true,
    bool showRecurringOption = false,
    bool allowNegative = false,
  }) {
    return showDialog<FinancialEntryDraft>(
      context: context,
      builder: (context) => FinancialEntryDialog(
        title: title,
        initialName: initialName,
        initialAmountInCents: initialAmountInCents,
        initialRecurring: initialRecurring,
        allowNameEditing: allowNameEditing,
        showRecurringOption: showRecurringOption,
        allowNegative: allowNegative,
      ),
    );
  }

  @override
  State<FinancialEntryDialog> createState() => _FinancialEntryDialogState();
}

class _FinancialEntryDialogState extends State<FinancialEntryDialog> {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController nameController;
  late final TextEditingController amountController;
  late bool isRecurring;

  @override
  void initState() {
    super.initState();
    final formatter = NumberFormat('#,##0.00', 'pt_BR');
    nameController = TextEditingController(text: widget.initialName);
    amountController = TextEditingController(
      text: formatter.format(widget.initialAmountInCents / 100),
    );
    isRecurring = widget.initialRecurring;
  }

  @override
  void dispose() {
    nameController.dispose();
    amountController.dispose();
    super.dispose();
  }

  void save() {
    if (!(formKey.currentState?.validate() ?? false)) {
      return;
    }

    final amountInCents = MoneyParser.parseToCents(amountController.text)!;
    Navigator.of(context).pop(
      FinancialEntryDraft(
        name: nameController.text.trim(),
        amountInCents: amountInCents,
        isRecurring: isRecurring,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 420,
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                enabled: widget.allowNameEditing,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Descrição',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Informe uma descrição.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: amountController,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9,.-]')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Valor',
                  prefixText: 'R\$ ',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final parsed = MoneyParser.parseToCents(value ?? '');
                  if (parsed == null) {
                    return 'Informe um valor válido.';
                  }
                  if (!widget.allowNegative && parsed < 0) {
                    return 'Use um valor igual ou maior que zero.';
                  }
                  return null;
                },
                onFieldSubmitted: (_) => save(),
              ),
              if (widget.showRecurringOption) ...[
                const SizedBox(height: 8),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: isRecurring,
                  title: const Text('Repetir nos próximos meses'),
                  onChanged: (value) {
                    setState(() {
                      isRecurring = value ?? false;
                    });
                  },
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: save, child: const Text('Salvar')),
      ],
    );
  }
}
