import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../shared/utility_expenses_repository.dart';

enum UtilityExpenseType { water, electricity }

class UtilityExpensesPage extends StatefulWidget {
  const UtilityExpensesPage({
    super.key,
    required this.storageScope,
    this.repository,
  });

  final String storageScope;
  final UtilityExpensesRepository? repository;

  @override
  State<UtilityExpensesPage> createState() => _UtilityExpensesPageState();
}

class _UtilityExpensesPageState extends State<UtilityExpensesPage> {
  late final UtilityExpensesRepository _repository;
  final _currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  final _monthFormat = DateFormat('MMMM', 'pt_BR');

  late int _year;
  UtilityExpenseType _type = UtilityExpenseType.water;
  bool _loading = true;
  List<UtilityExpenseMonth> _months = const [];

  @override
  void initState() {
    super.initState();
    _repository =
        widget.repository ?? UtilityExpensesRepository(scope: widget.storageScope);
    _year = DateTime.now().year;
    _loadYear();
  }

  Future<void> _loadYear() async {
    setState(() => _loading = true);
    final months = await _repository.loadYear(_year);
    if (!mounted) return;
    setState(() {
      _months = months;
      _loading = false;
    });
  }

  Future<void> _changeYear(int delta) async {
    setState(() => _year += delta);
    await _loadYear();
  }

  Future<void> _edit(UtilityExpenseMonth month) async {
    final current = _type == UtilityExpenseType.water
        ? month.waterInCents
        : month.electricityInCents;
    final value = await _ValueDialog.show(
      context,
      title:
          '${_type == UtilityExpenseType.water ? 'Água' : 'Luz'} • ${_monthLabel(month.month)}/$_year',
      initialValueInCents: current,
    );
    if (value == null) return;

    final updated = _type == UtilityExpenseType.water
        ? month.copyWith(waterInCents: value)
        : month.copyWith(electricityInCents: value);
    await _repository.save(updated);
    if (!mounted) return;
    final index = _months.indexWhere((item) => item.month == month.month);
    setState(() {
      final copy = [..._months];
      copy[index] = updated;
      _months = copy;
    });
  }

  String _monthLabel(int month) {
    final raw = _monthFormat.format(DateTime(2026, month));
    return '${raw[0].toUpperCase()}${raw.substring(1)}';
  }

  int _valueFor(UtilityExpenseMonth month) {
    return _type == UtilityExpenseType.water
        ? month.waterInCents
        : month.electricityInCents;
  }

  @override
  Widget build(BuildContext context) {
    final total = _months.fold<int>(0, (sum, item) => sum + _valueFor(item));
    final isWater = _type == UtilityExpenseType.water;

    return Scaffold(
      appBar: AppBar(title: const Text('Despesas Água/Luz')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Card(
            margin: EdgeInsets.zero,
            child: const ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('Controle separado do financeiro'),
              subtitle: Text(
                'Os valores de Água e Luz ficam somente nesta função e não '
                'entram no saldo, despesas, faturas ou totais do FinFlow.',
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Ano anterior',
                    onPressed: () => _changeYear(-1),
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Expanded(
                    child: Text(
                      '$_year',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Próximo ano',
                    onPressed: () => _changeYear(1),
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SegmentedButton<UtilityExpenseType>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(
                value: UtilityExpenseType.water,
                icon: Icon(Icons.water_drop_outlined),
                label: Text('Água'),
              ),
              ButtonSegment(
                value: UtilityExpenseType.electricity,
                icon: Icon(Icons.bolt_outlined),
                label: Text('Luz'),
              ),
            ],
            selected: {_type},
            onSelectionChanged: (value) {
              setState(() => _type = value.single);
            },
          ),
          const SizedBox(height: 16),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: CircularProgressIndicator()),
            )
          else ...[
            Card(
              margin: EdgeInsets.zero,
              child: Column(
                children: [
                  for (var index = 0; index < _months.length; index++) ...[
                    ListTile(
                      key: ValueKey('utility-${_type.name}-${_months[index].month}'),
                      leading: CircleAvatar(
                        child: Icon(
                          isWater
                              ? Icons.water_drop_outlined
                              : Icons.bolt_outlined,
                        ),
                      ),
                      title: Text(_monthLabel(_months[index].month)),
                      subtitle: Text('$_year'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _valueFor(_months[index]) == 0
                                ? '—'
                                : _currency.format(
                                    _valueFor(_months[index]) / 100,
                                  ),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                      onTap: () => _edit(_months[index]),
                    ),
                    if (index != _months.length - 1)
                      const Divider(height: 1),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            Card(
              margin: EdgeInsets.zero,
              child: ListTile(
                leading: Icon(
                  isWater ? Icons.water_drop_outlined : Icons.bolt_outlined,
                ),
                title: Text(
                  'Total de ${isWater ? 'Água' : 'Luz'} em $_year',
                ),
                trailing: Text(
                  _currency.format(total / 100),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ValueDialog extends StatefulWidget {
  const _ValueDialog({required this.title, required this.initialValueInCents});

  final String title;
  final int initialValueInCents;

  static Future<int?> show(
    BuildContext context, {
    required String title,
    required int initialValueInCents,
  }) {
    return showDialog<int>(
      context: context,
      builder: (context) => _ValueDialog(
        title: title,
        initialValueInCents: initialValueInCents,
      ),
    );
  }

  @override
  State<_ValueDialog> createState() => _ValueDialogState();
}

class _ValueDialogState extends State<_ValueDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.initialValueInCents == 0
          ? ''
          : (widget.initialValueInCents / 100).toStringAsFixed(2).replaceAll('.', ','),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int? _parse() {
    var value = _controller.text.trim().replaceAll('R\$', '').replaceAll(' ', '');
    if (value.isEmpty) return 0;
    if (value.contains(',') && value.contains('.')) {
      value = value.replaceAll('.', '').replaceAll(',', '.');
    } else {
      value = value.replaceAll(',', '.');
    }
    final number = double.tryParse(value);
    if (number == null || number < 0) return null;
    return (number * 100).round();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: const InputDecoration(
          labelText: 'Valor da conta',
          prefixText: 'R\$ ',
          hintText: '0,00',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            final value = _parse();
            if (value == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Informe um valor válido.')),
              );
              return;
            }
            Navigator.pop(context, value);
          },
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}
