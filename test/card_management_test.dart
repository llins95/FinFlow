import 'package:finflow/controllers/financial_month_controller.dart';
import 'package:finflow/models/financial_entry.dart';
import 'package:finflow/models/financial_month.dart';
import 'package:finflow/shared/financial_month_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('gerenciamento de cartões', () {
    test('preserva todos os dados editáveis ao serializar', () {
      const entry = FinancialEntry(
        id: 'invoice-demo',
        name: 'Cartão de teste',
        amountInCents: 12345,
        type: FinancialEntryType.cardInvoice,
        isRecurring: true,
        isActive: false,
        relatedCardId: 'demo',
        cardBank: 'Banco de teste',
        cardBrand: 'Bandeira de teste',
        cardLimitInCents: 250000,
        cardColor: 0xFF455A64,
        closingDay: 8,
        dueDay: 15,
      );

      final restored = FinancialEntry.fromMap(entry.toMap());

      expect(restored.name, 'Cartão de teste');
      expect(restored.isActive, isFalse);
      expect(restored.cardBank, 'Banco de teste');
      expect(restored.cardBrand, 'Bandeira de teste');
      expect(restored.cardLimitInCents, 250000);
      expect(restored.cardColor, 0xFF455A64);
      expect(restored.closingDay, 8);
      expect(restored.dueDay, 15);
    });

    test('mantém compatibilidade com cartões salvos anteriormente', () {
      final restored = FinancialEntry.fromMap({
        'id': 'invoice-legacy',
        'name': 'Cartão antigo',
        'amountInCents': 0,
        'type': 'cardInvoice',
        'isRecurring': true,
        'relatedCardId': 'legacy',
      });

      expect(restored.isActive, isTrue);
      expect(restored.cardBank, isNull);
      expect(restored.cardLimitInCents, isNull);
    });

    test('não copia um cartão inativo para o próximo mês', () {
      final currentMonth = FinancialMonth(
        year: 2026,
        month: 8,
        entries: const [
          FinancialEntry(
            id: 'invoice-active',
            name: 'Cartão ativo',
            amountInCents: 1000,
            type: FinancialEntryType.cardInvoice,
            isRecurring: true,
          ),
          FinancialEntry(
            id: 'invoice-inactive',
            name: 'Cartão inativo',
            amountInCents: 2000,
            type: FinancialEntryType.cardInvoice,
            isRecurring: true,
            isActive: false,
          ),
        ],
      );

      final nextMonth = currentMonth.createNextMonth();

      expect(
        nextMonth.entries.any((entry) => entry.id == 'invoice-active'),
        isTrue,
      );
      expect(
        nextMonth.entries.any((entry) => entry.id == 'invoice-inactive'),
        isFalse,
      );
      expect(currentMonth.totalDebtInCents, 3000);
    });

    test('adiciona e persiste um cartão novo', () async {
      final store = MemoryFinancialMonthStore();
      await store.save(FinancialMonth(year: 2026, month: 8, entries: const []));
      final controller = FinancialMonthController(store);
      await controller.initialize(now: DateTime(2026, 8, 5));

      await controller.addCardInvoice(
        name: 'Cartão novo',
        bank: 'Banco novo',
        brand: 'Bandeira nova',
        limitInCents: 180000,
        closingDay: 5,
        dueDay: 12,
        color: 0xFF009EE3,
      );

      final reloaded = await store.load(2026, 8);
      final savedCard = reloaded!.entries.single;
      expect(savedCard.type, FinancialEntryType.cardInvoice);
      expect(savedCard.cardBank, 'Banco novo');
      expect(savedCard.cardLimitInCents, 180000);
      expect(savedCard.amountInCents, 0);

      controller.dispose();
    });

    test('propaga o limite editado para os meses já carregados', () async {
      final store = MemoryFinancialMonthStore();
      await store.save(
        FinancialMonth(
          year: 2026,
          month: 8,
          entries: const [
            FinancialEntry(
              id: 'card-demo',
              name: 'Cartão de teste',
              amountInCents: 2500,
              type: FinancialEntryType.cardInvoice,
              isRecurring: true,
              relatedCardId: 'demo',
              cardLimitInCents: 100000,
              closingDay: 5,
              dueDay: 10,
            ),
          ],
        ),
      );
      final controller = FinancialMonthController(store);
      await controller.initialize(now: DateTime(2026, 10, 5));
      addTearDown(controller.dispose);
      expect(await controller.goToMonth(2026, 8), isTrue);

      final augustCard = controller.activeCardInvoices.single;
      await controller.updateCardDetails(
        augustCard.copyWith(cardLimitInCents: 350000),
      );

      for (var month = 8; month <= 10; month++) {
        final saved = await store.load(2026, month);
        final card = saved!
            .entriesOfType(FinancialEntryType.cardInvoice)
            .single;
        expect(card.cardLimitInCents, 350000);
        expect(card.amountInCents, month == 8 ? 2500 : 0);
      }
    });
  });
}
