import 'package:finflow/models/financial_entry.dart';
import 'package:finflow/models/financial_month.dart';
import 'package:finflow/models/purchase_record.dart';
import 'package:finflow/services/finance_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('busca de compras e parcelas', () {
    final purchase = FinancialEntry(
      id: 'purchase-search-demo',
      name: 'Café São Braz',
      amountInCents: 10001,
      type: FinancialEntryType.purchase,
      relatedCardId: 'card-search-demo',
      relatedCardName: 'Cartão de teste',
      cardColor: 0xFF455A64,
      closingDay: 3,
      dueDay: 10,
      purchaseDate: DateTime(2026, 8, 2),
      installments: 3,
    );
    final record = PurchaseRecord(
      month: FinancialMonth(year: 2026, month: 8, entries: [purchase]),
      entry: purchase,
    );

    test('encontra uma compra ignorando acentos', () {
      final results = FinanceService.searchPurchases([record], 'cafe');

      expect(results, hasLength(1));
      expect(results.single.installments, hasLength(3));
      expect(results.single.installments.map((item) => item.dueDate), [
        DateTime(2026, 8, 10),
        DateTime(2026, 9, 10),
        DateTime(2026, 10, 10),
      ]);
    });

    test('encontra o mês e mantém toda a sequência de parcelas', () {
      final results = FinanceService.searchPurchases([record], 'setembro 2026');

      expect(results, hasLength(1));
      expect(results.single.installments, hasLength(3));
      expect(results.single.matchingInstallmentNumbers, {2});
      expect(results.single.matchedByMonth, isTrue);
    });

    test('aceita mês no formato numérico', () {
      final results = FinanceService.searchPurchases([record], '09/2026');

      expect(results, hasLength(1));
      expect(results.single.matchingInstallmentNumbers, {2});
    });

    test('não retorna compra fora da pesquisa', () {
      expect(
        FinanceService.searchPurchases([record], 'dezembro 2027'),
        isEmpty,
      );
    });
  });
}
