import 'package:finflow/models/notification_purchase_candidate.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('aceita espaço não separável no valor da Carteira do Google', () {
    final candidate = NotificationPurchaseParser.tryParse({
      'id': 'wallet-notification-nbsp',
      'sourcePackage': 'com.google.android.apps.walletnfcrel',
      'title': 'Pagamento aprovado',
      'text': 'R\$\u00A042,35 em Mercado Exemplo',
      'postedAt': DateTime(2026, 8, 24, 10).millisecondsSinceEpoch,
    });

    expect(candidate, isNotNull);
    expect(candidate!.amountInCents, 4235);
    expect(candidate.description, 'Mercado Exemplo');
  });
}
