import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

import '../../../models/financial_entry.dart';
import '../../../shared/finance_repository.dart';

class EntriesPage extends StatelessWidget {
  const EntriesPage({super.key});

  Future<void> _edit(BuildContext context, {FinancialEntry? entry, EntryType type = EntryType.expense}) async {
    final description = TextEditingController(text: entry?.description ?? '');
    final amount = TextEditingController(text: entry == null ? '' : entry.amount.toStringAsFixed(2).replaceAll('.', ','));
    var date = entry?.dueDate ?? DateTime.now();
    var recurring = false;
    DateTime? until;
    final result = await showDialog<bool>(context: context, builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: Text(entry == null ? (type == EntryType.income ? 'Adicionar receita' : 'Adicionar despesa') : 'Editar lançamento'),
        content: SizedBox(width: 420, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: description, autofocus: true, decoration: const InputDecoration(labelText: 'Descrição')),
          const SizedBox(height: 12),
          TextField(controller: amount, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Valor', prefixText: 'R\$ ')),
          const SizedBox(height: 12),
          ListTile(title: const Text('Data'), subtitle: Text(DateFormat('dd/MM/yyyy').format(date)), trailing: const Icon(Icons.calendar_month), onTap: () async {
            final picked = await showDatePicker(context: context, firstDate: DateTime(2020), lastDate: DateTime(2100), initialDate: date);
            if (picked != null) setDialogState(() => date = picked);
          }),
          if (entry == null) SwitchListTile(value: recurring, title: const Text('Repetir mensalmente'), onChanged: (v) => setDialogState(() { recurring = v; until = v ? FinanceRepository.addMonths(date, 1) : null; })),
          if (recurring) ListTile(title: const Text('Repetir até'), subtitle: Text(until == null ? 'Selecione' : DateFormat('MM/yyyy').format(until!)), trailing: const Icon(Icons.event), onTap: () async {
            final picked = await showDatePicker(context: context, firstDate: date, lastDate: DateTime(2100), initialDate: until ?? date);
            if (picked != null) setDialogState(() => until = picked);
          }),
        ]))),
        actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Salvar'))],
      ),
    ));
    if (result != true) return;
    final parsed = double.tryParse(amount.text.replaceAll('.', '').replaceAll(',', '.')) ?? 0;
    if (description.text.trim().isEmpty || parsed <= 0 || (recurring && until == null)) return;
    if (entry != null) {
      await FinanceRepository.saveEntry(entry.copyWith(description: description.text.trim(), amountInCents: (parsed * 100).round(), dueDate: date));
    } else {
      await FinanceRepository.createEntries(description: description.text.trim(), amountInCents: (parsed * 100).round(), type: type, firstDate: date, repeatUntil: recurring ? until : null);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Receitas e despesas'), actions: [
      IconButton(tooltip: 'Adicionar receita', onPressed: () => _edit(context, type: EntryType.income), icon: const Icon(Icons.add_card)),
      IconButton(tooltip: 'Adicionar despesa', onPressed: () => _edit(context), icon: const Icon(Icons.remove_circle_outline)),
    ]),
    body: ValueListenableBuilder<Box>(valueListenable: FinanceRepository.entriesBox.listenable(), builder: (context, _, __) {
      final entries = FinanceRepository.entries;
      if (entries.isEmpty) return const Center(child: Text('Nenhuma receita ou despesa cadastrada.'));
      return ListView.builder(padding: const EdgeInsets.all(12), itemCount: entries.length, itemBuilder: (context, i) {
        final item = entries[i];
        return Card(child: ListTile(
          leading: Icon(item.type == EntryType.income ? Icons.arrow_downward : Icons.arrow_upward, color: item.type == EntryType.income ? Colors.green : Colors.red),
          title: Text(item.description),
          subtitle: Text('${DateFormat('dd/MM/yyyy').format(item.dueDate)} • ${item.paid ? 'PAGO' : item.type == EntryType.expense ? 'PENDENTE' : 'RECEBIDO'}'),
          trailing: Text(NumberFormat.simpleCurrency(locale: 'pt_BR').format(item.amount), style: const TextStyle(fontWeight: FontWeight.bold)),
          onTap: () => _edit(context, entry: item),
          onLongPress: () => FinanceRepository.removeEntry(item.id),
        ));
      });
    }),
  );
}
