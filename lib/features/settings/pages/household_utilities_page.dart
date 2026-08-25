import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../controllers/household_utility_controller.dart';
import '../../../models/household_utility_expense.dart';
import '../../../services/supabase_household_utility_store.dart';
import '../../../shared/household_utility_repository.dart';

class HouseholdUtilitiesPage extends StatefulWidget {
  const HouseholdUtilitiesPage({
    super.key,
    this.supabaseClient,
    this.userId,
    this.controller,
  });

  final SupabaseClient? supabaseClient;
  final String? userId;
  final HouseholdUtilityController? controller;

  @override
  State<HouseholdUtilitiesPage> createState() => _HouseholdUtilitiesPageState();
}

class _HouseholdUtilitiesPageState extends State<HouseholdUtilitiesPage> {
  late final HouseholdUtilityController _controller;
  late final bool _ownsController;
  final _currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? HouseholdUtilityController(_buildStore());
    unawaited(_controller.initialize());
  }

  HouseholdUtilityStore _buildStore() {
    final localStore = HiveHouseholdUtilityStore(userId: widget.userId);
    if (widget.supabaseClient != null && widget.userId != null) {
      return SupabaseHouseholdUtilityStore(
        client: widget.supabaseClient!,
        localStore: localStore,
      );
    }
    return localStore;
  }

  @override
  void dispose() {
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Despesas Água/Luz'),
          actions: [
            IconButton(
              tooltip: 'Sincronizar e atualizar',
              onPressed: () => unawaited(_controller.refresh()),
              icon: const Icon(Icons.refresh),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.water_drop_outlined), text: 'Água'),
              Tab(icon: Icon(Icons.bolt_outlined), text: 'Luz'),
            ],
          ),
        ),
        body: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Column(
                    children: [
                      Card(
                        margin: EdgeInsets.zero,
                        child: ListTile(
                          leading: const Icon(Icons.home_outlined),
                          title: const Text('Controle residencial independente'),
                          subtitle: const Text(
                            'Estes valores ficam somente nesta área. Eles não '
                            'entram em Total a pagar, Total disponível, '
                            'Sobra/Falta, faturas, despesas ou histórico financeiro.',
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _YearSelector(controller: _controller),
                      if (_controller.errorMessage != null) ...[
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Não foi possível sincronizar agora. Os valores '
                            'salvos neste aparelho continuam disponíveis.',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Expanded(
                  child: _controller.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : TabBarView(
                          children: [
                            _UtilityMonthList(
                              controller: _controller,
                              kind: HouseholdUtilityKind.water,
                              currency: _currency,
                              onEdit: _editAmount,
                            ),
                            _UtilityMonthList(
                              controller: _controller,
                              kind: HouseholdUtilityKind.electricity,
                              currency: _currency,
                              onEdit: _editAmount,
                            ),
                          ],
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _editAmount(int month, HouseholdUtilityKind kind) async {
    final current = _controller.amountFor(month, kind);
    final label = kind == HouseholdUtilityKind.water ? 'Água' : 'Luz';
    final monthName = _monthName(month);
    final textController = TextEditingController(
      text: current > 0 ? _decimalValue(current) : '',
    );

    final result = await showDialog<int>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(
          kind == HouseholdUtilityKind.water
              ? Icons.water_drop_outlined
              : Icons.bolt_outlined,
        ),
        title: Text('$label • $monthName/${_controller.selectedYear}'),
        content: SizedBox(
          width: 420,
          child: TextField(
            key: const ValueKey('household-utility-value-field'),
            controller: textController,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
            decoration: const InputDecoration(
              labelText: 'Valor da conta',
              prefixText: 'R\$ ',
              hintText: '0,00',
            ),
            onSubmitted: (_) {
              final cents = _parseCurrency(textController.text);
              if (cents != null) {
                Navigator.pop(dialogContext, cents);
              }
            },
          ),
        ),
        actions: [
          if (current > 0)
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, 0),
              child: const Text('Limpar valor'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            key: const ValueKey('household-utility-save'),
            onPressed: () {
              final cents = _parseCurrency(textController.text);
              if (cents == null) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(content: Text('Informe um valor válido.')),
                );
                return;
              }
              Navigator.pop(dialogContext, cents);
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    textController.dispose();

    if (result == null || !mounted) {
      return;
    }

    try {
      await _controller.setAmount(month, kind, result);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$label de $monthName atualizado.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível salvar este valor.'),
          ),
        );
      }
    }
  }

  int? _parseCurrency(String input) {
    var normalized = input.trim().replaceAll('R\$', '').replaceAll(' ', '');
    if (normalized.isEmpty) {
      return 0;
    }

    if (normalized.contains(',')) {
      normalized = normalized.replaceAll('.', '').replaceAll(',', '.');
    }
    final value = double.tryParse(normalized);
    if (value == null || value < 0) {
      return null;
    }
    return (value * 100).round();
  }

  String _decimalValue(int cents) {
    return NumberFormat('0.00', 'pt_BR').format(cents / 100);
  }

  String _monthName(int month) {
    final formatted = DateFormat('MMMM', 'pt_BR').format(DateTime(2026, month));
    return toBeginningOfSentenceCase(formatted);
  }
}

class _YearSelector extends StatelessWidget {
  const _YearSelector({required this.controller});

  final HouseholdUtilityController controller;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Row(
        children: [
          IconButton(
            key: const ValueKey('household-utility-previous-year'),
            tooltip: 'Ano anterior',
            onPressed: controller.selectedYear > 2000
                ? controller.goToPreviousYear
                : null,
            icon: const Icon(Icons.chevron_left),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  'Ano',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  '${controller.selectedYear}',
                  key: const ValueKey('household-utility-year'),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            key: const ValueKey('household-utility-next-year'),
            tooltip: 'Próximo ano',
            onPressed: controller.selectedYear < 2100
                ? controller.goToNextYear
                : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}

class _UtilityMonthList extends StatelessWidget {
  const _UtilityMonthList({
    required this.controller,
    required this.kind,
    required this.currency,
    required this.onEdit,
  });

  final HouseholdUtilityController controller;
  final HouseholdUtilityKind kind;
  final NumberFormat currency;
  final Future<void> Function(int month, HouseholdUtilityKind kind) onEdit;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      itemCount: 12,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final month = index + 1;
        final amount = controller.amountFor(month, kind);
        final monthText = DateFormat(
          'MMMM',
          'pt_BR',
        ).format(DateTime(2026, month));
        final monthName = toBeginningOfSentenceCase(monthText);
        final kindKey = kind == HouseholdUtilityKind.water ? 'water' : 'light';

        return Card(
          margin: EdgeInsets.zero,
          child: ListTile(
            key: ValueKey(
              'household-utility-$kindKey-${controller.selectedYear}-$month',
            ),
            leading: CircleAvatar(
              child: Icon(
                kind == HouseholdUtilityKind.water
                    ? Icons.water_drop_outlined
                    : Icons.bolt_outlined,
              ),
            ),
            title: Text(monthName),
            subtitle: Text('${controller.selectedYear}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  amount > 0 ? currency.format(amount / 100) : '—',
                  style: TextStyle(
                    fontWeight: amount > 0 ? FontWeight.bold : FontWeight.normal,
                    color: amount > 0
                        ? null
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.edit_outlined, size: 20),
              ],
            ),
            onTap: () => unawaited(onEdit(month, kind)),
          ),
        );
      },
    );
  }
}
