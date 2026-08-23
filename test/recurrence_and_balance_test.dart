import 'dart:async';

import 'package:finflow/controllers/financial_month_controller.dart';
import 'package:finflow/models/financial_entry.dart';
import 'package:finflow/models/financial_month.dart';
import 'package:finflow/models/pix_key.dart';
import 'package:finflow/models/pix_settings.dart';
import 'package:finflow/shared/financial_month_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('recorrência com término', () {
    test('gera até o mês final inclusivo e não duplica o lançamento', () async {
      final store = MemoryFinancialMonthStore();
      await store.save(FinancialMonth(year: 2026, month: 8, entries: const []));
      final controller = FinancialMonthController(store);
      addTearDown(controller.dispose);
      await controller.initialize(now: DateTime(2026, 8, 5));

      await controller.addEntry(
        name: 'Receita mensal',
        amountInCents: 125000,
        type: FinancialEntryType.income,
        isRecurring: true,
        recurrenceEndMonth: DateTime(2026, 12),
      );

      for (var month = 8; month <= 12; month++) {
        final saved = await store.load(2026, month);
        expect(
          saved!.entries.where((entry) => entry.name == 'Receita mensal'),
          hasLength(1),
          reason: 'o mês $month deve ter uma única ocorrência',
        );
      }

      expect(await controller.goToMonth(2026, 12), isTrue);
      await controller.goToNextMonth();
      expect(
        controller.currentMonth.entries.any(
          (entry) => entry.name == 'Receita mensal',
        ),
        isFalse,
      );
    });

    test('preserva o término ao serializar e lê dados antigos', () {
      final entry = FinancialEntry(
        id: 'income-test',
        name: 'Receita',
        amountInCents: 1000,
        type: FinancialEntryType.income,
        isRecurring: true,
        recurrenceEndMonth: DateTime(2026, 12),
      );

      final restored = FinancialEntry.fromMap(entry.toMap());
      final legacy = FinancialEntry.fromMap({
        'id': 'income-legacy',
        'name': 'Receita antiga',
        'amountInCents': 1000,
        'type': 'income',
        'isRecurring': true,
      });

      expect(restored.recurrenceEndMonth, DateTime(2026, 12));
      expect(restored.recursInto(DateTime(2026, 12)), isTrue);
      expect(restored.recursInto(DateTime(2027, 1)), isFalse);
      expect(legacy.recurrenceEndMonth, isNull);
      expect(legacy.recursInto(DateTime(2030, 1)), isTrue);
    });
  });

  test('saldo anterior inclui parcelas automáticas e é idempotente', () async {
    final store = MemoryFinancialMonthStore();
    await store.save(
      FinancialMonth(
        year: 2026,
        month: 8,
        entries: const [
          FinancialEntry(
            id: 'income-test',
            name: 'Receita',
            amountInCents: 100000,
            type: FinancialEntryType.income,
          ),
          FinancialEntry(
            id: 'card-test',
            name: 'Cartão',
            amountInCents: 0,
            type: FinancialEntryType.cardInvoice,
            isRecurring: true,
            relatedCardId: 'test',
            closingDay: 31,
            dueDay: 10,
          ),
        ],
      ),
    );
    final controller = FinancialMonthController(store);
    addTearDown(controller.dispose);
    await controller.initialize(now: DateTime(2026, 8, 5));

    await controller.addPurchase(
      description: 'Compra em agosto',
      amountInCents: 20000,
      installments: 1,
      purchaseDate: DateTime(2026, 8, 5),
      cardInvoice: controller.activeCardInvoices.single,
    );
    await controller.goToNextMonth();

    expect(await controller.carryPreviousMonthBalance(), isTrue);
    expect(await controller.carryPreviousMonthBalance(), isTrue);

    final transfers = controller.currentMonth.entriesOfType(
      FinancialEntryType.previousBalance,
    );
    expect(transfers, hasLength(1));
    expect(transfers.single.amountInCents, 80000);
    expect(transfers.single.sourceReference, 'previous-balance:2026-08');
    expect(transfers.single.name, contains('Agosto/2026'));
  });

  test(
    'apaga lançamentos e configurações Pix, mantendo estado funcional',
    () async {
      final store = MemoryFinancialMonthStore();
      await store.save(
        FinancialMonth(
          year: 2026,
          month: 8,
          entries: const [
            FinancialEntry(
              id: 'expense-test',
              name: 'Despesa',
              amountInCents: 1000,
              type: FinancialEntryType.expense,
            ),
          ],
        ),
      );
      final controller = FinancialMonthController(store);
      addTearDown(controller.dispose);
      await controller.initialize(now: DateTime(2026, 8, 5));
      await controller.addPixKey(
        type: PixKeyType.email,
        value: 'pix@example.com',
        title: 'Principal',
      );

      await controller.deleteAllData();

      expect(controller.isInitialized, isTrue);
      expect(controller.currentMonth.entries, isEmpty);
      expect(controller.pixKeys, isEmpty);
      expect(await store.load(2026, 8), isNull);
    },
  );

  test('aplica em memória um reset recebido de outro dispositivo', () async {
    final store = _EmittingMemoryStore();
    addTearDown(store.dispose);
    await store.save(
      FinancialMonth(
        year: 2026,
        month: 8,
        entries: const [
          FinancialEntry(
            id: 'income-test',
            name: 'Receita',
            amountInCents: 1000,
            type: FinancialEntryType.income,
          ),
        ],
      ),
    );
    final controller = FinancialMonthController(store);
    addTearDown(controller.dispose);
    await controller.initialize(now: DateTime(2026, 8, 5));

    store.emit(
      const PixSettings(dataResetId: 'remote-reset').toFinancialMonth(),
    );
    await Future<void>.delayed(Duration.zero);

    expect(controller.currentMonth.entries, isEmpty);
    expect(controller.pixSettings.dataResetId, 'remote-reset');
  });
}

class _EmittingMemoryStore extends MemoryFinancialMonthStore {
  final StreamController<FinancialMonth> _controller =
      StreamController<FinancialMonth>.broadcast();

  @override
  Stream<FinancialMonth> get changes => _controller.stream;

  void emit(FinancialMonth month) => _controller.add(month);

  @override
  Future<void> dispose() => _controller.close();
}
