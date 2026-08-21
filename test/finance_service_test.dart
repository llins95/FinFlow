import 'package:finflow/models/credit_card.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const card = CreditCard(id: 'card', name: 'Card', bank: 'Bank', brand: 'Visa', limit: 1000, closingDay: 10, dueDay: 20, color: 0);

  test('compra antes do fechamento entra na fatura atual', () {
    expect(card.invoiceForPurchase(DateTime(2026, 8, 10)), DateTime(2026, 8, 20));
  });

  test('compra após fechamento entra na próxima fatura inclusive virada de ano', () {
    expect(card.invoiceForPurchase(DateTime(2026, 12, 11)), DateTime(2027, 1, 20));
  });
}
