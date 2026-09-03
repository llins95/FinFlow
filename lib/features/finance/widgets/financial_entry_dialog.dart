import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../utils/money_parser.dart';
import '../../../utils/select_all_on_focus.dart';

class FinancialEntryDraft {
  final String name;
  final int amountInCents;
  final bool isRecurring;
  final int? dueDay;
  final DateTime? recurrenceEndMonth;

  const FinancialEntryDraft({
    required this.name,
    required this.amountInCents,
    required this.isRecurring,
    this.dueDay,
    this.recurrenceEndMonth,
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
    this.showDueDay = false,
    this.initialDueDay,
    this.allowNegative = false,
    this.recurrenceStartMonth,
    this.initialRecurrenceEndMonth,
    this.amountLabel = 'Valor',
    this.amountHelperText,
    this.minimumAmountInCents,
  });

  final String title;
  final String initialName;
  final int initialAmountInCents;
  final bool initialRecurring;
  final bool allowNameEditing;
  final bool showRecurringOption;
  final bool showDueDay;
  final int? initialDueDay;
  final bool allowNegative;
  final DateTime? recurrenceStartMonth;
  final DateTime? initialRecurrenceEndMonth;
  final String amountLabel;
  final String? amountHelperText;
  final int? minimumAmountInCents;

  static Future<FinancialEntryDraft?> show(
    BuildContext context, {
    required String title,
    String initialName = '',
    int initialAmountInCents = 0,
    bool initialRecurring = false,
    bool allowNameEditing = true,
    bool showRecurringOption = false,
    bool showDueDay = false,
    int? initialDueDay,
    bool allowNegative = false,
    DateTime? recurrenceStartMonth,
    DateTime? initialRecurrenceEndMonth,
    String amountLabel = 'Valor',
    String? amountHelperText,
    int? minimumAmountInCents,
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
        showDueDay: showDueDay,
        initialDueDay: initialDueDay,
        allowNegative: allowNegative,
        recurrenceStartMonth: recurrenceStartMonth,
        initialRecurrenceEndMonth: initialRecurrenceEndMonth,
        amountLabel: amountLabel,
        amountHelperText: amountHelperText,
        minimumAmountInCents: minimumAmountInCents,
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
  late final TextEditingController dueDayController;
  late final SelectAllOnFocusNode amountFocusNode;
  late final SelectAllOnFocusNode dueDayFocusNode;
  late bool isRecurring;
  DateTime? recurrenceEndMonth;

  @override
  void initState() {
    super.initState();
    final formatter = NumberFormat('#,##0.00', 'pt_BR');
    nameController = TextEditingController(text: widget.initialName);
    amountController = TextEditingController(
      text: formatter.format(widget.initialAmountInCents / 100),
    );
    dueDayController = TextEditingController(
      text: widget.initialDueDay?.toString() ?? '',
    );
    amountFocusNode = SelectAllOnFocusNode(amountController);
    dueDayFocusNode = SelectAllOnFocusNode(dueDayController);
    isRecurring = widget.initialRecurring;
    recurrenceEndMonth = widget.initialRecurrenceEndMonth;
  }

  @override
  void dispose() {
    amountFocusNode.dispose();
    dueDayFocusNode.dispose();
    nameController.dispose();
    amountController.dispose();
    dueDayController.dispose();
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
        dueDay: int.tryParse(dueDayController.text),
        recurrenceEndMonth: isRecurring ? recurrenceEndMonth : null,
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
                focusNode: amountFocusNode,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9,.-]')),
                ],
                decoration: InputDecoration(
                  labelText: widget.amountLabel,
                  prefixText: 'R\$ ',
                  helperText: widget.amountHelperText,
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  final parsed = MoneyParser.parseToCents(value ?? '');
                  if (parsed == null) {
                    return 'Informe um valor válido.';
                  }
                  if (!widget.allowNegative && parsed < 0) {
                    return 'Use um valor igual ou maior que zero.';
                  }
                  final minimum = widget.minimumAmountInCents;
                  if (minimum != null && parsed < minimum) {
                    final formatter = NumberFormat.currency(
                      locale: 'pt_BR',
                      symbol: 'R\$',
                    );
                    return 'O total não pode ser menor que '
                        '${formatter.format(minimum / 100)}.';
                  }
                  return null;
                },
                onFieldSubmitted: (_) => save(),
              ),
              if (widget.showDueDay) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: dueDayController,
                  focusNode: dueDayFocusNode,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(2),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Dia de vencimento (opcional)',
                    hintText: 'Ex.: 10',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return null;
                    }
                    final day = int.tryParse(value);
                    if (day == null || day < 1 || day > 31) {
                      return 'Use um dia entre 1 e 31.';
                    }
                    return null;
                  },
                ),
              ],
              if (widget.showRecurringOption) ...[
                const SizedBox(height: 8),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: isRecurring,
                  title: const Text('Repetir nos próximos meses'),
                  onChanged: (value) {
                    setState(() {
                      isRecurring = value ?? false;
                      if (!isRecurring) {
                        recurrenceEndMonth = null;
                      }
                    });
                  },
                ),
                if (isRecurring)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.event_repeat_outlined),
                    title: const Text('Repetir até'),
                    subtitle: Text(
                      recurrenceEndMonth == null
                          ? 'Sem data final'
                          : DateFormat(
                              'MMMM/yyyy',
                              'pt_BR',
                            ).format(recurrenceEndMonth!),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _selectRecurrenceEndMonth,
                  ),
                if (isRecurring && recurrenceEndMonth != null)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        setState(() {
                          recurrenceEndMonth = null;
                        });
                      },
                      child: const Text('Sem data final'),
                    ),
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

  Future<void> _selectRecurrenceEndMonth() async {
    final start = widget.recurrenceStartMonth ?? DateTime.now();
    final firstMonth = DateTime(start.year, start.month);
    final initial = recurrenceEndMonth ?? DateTime(start.year, start.month + 1);
    final selected = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(firstMonth) ? firstMonth : initial,
      firstDate: firstMonth,
      lastDate: DateTime(2099, 12, 31),
      helpText: 'Selecione o último mês da repetição',
      fieldLabelText: 'Último mês',
    );
    if (selected != null && mounted) {
      setState(() {
        recurrenceEndMonth = DateTime(selected.year, selected.month);
      });
    }
  }
}
