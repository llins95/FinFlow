import 'package:finflow/models/notification_purchase_candidate.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NotificationPurchaseParser', () {
    test('extrai valor e estabelecimento de um alerta em reais', () {
      final candidate = NotificationPurchaseParser.tryParse({
        'id': 'wallet-notification-demo-1',
        'sourcePackage': 'com.google.android.apps.walletnfcrel',
        'title': 'Pagamento aprovado',
        'text': 'R\$ 42,35 em Mercado Exemplo',
        'postedAt': DateTime(2026, 8, 5, 14, 30)
            .toUtc()
            .millisecondsSinceEpoch,
      });

      expect(candidate, isNotNull);
      expect(candidate!.amountInCents, 4235);
      expect(candidate.description, 'Mercado Exemplo');
      expect(candidate.id, 'wallet-notification-demo-1');
    });

    test('entende milhar e a frase você pagou', () {
      final candidate = NotificationPurchaseParser.tryParse({
        'id': 'wallet-notification-demo-2',
        'sourcePackage': 'com.google.android.apps.walletnfcrel',
        'title': 'Carteira do Google',
        'text': 'Você pagou R\$ 1.234,56 para Loja de Teste',
        'postedAt': DateTime(2026, 8, 5).millisecondsSinceEpoch,
      });

      expect(candidate, isNotNull);
      expect(candidate!.amountInCents, 123456);
      expect(candidate.description, 'Loja de Teste');
    });

    test('ignora notificações sem valor em reais', () {
      final candidate = NotificationPurchaseParser.tryParse({
        'id': 'wallet-notification-demo-3',
        'sourcePackage': 'com.google.android.apps.walletnfcrel',
        'title': 'Cartão adicionado',
        'text': 'Seu cartão está pronto para pagamentos',
        'postedAt': DateTime(2026, 8, 5).millisecondsSinceEpoch,
      });

      expect(candidate, isNull);
    });
  });
}
