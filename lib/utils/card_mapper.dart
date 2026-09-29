import '../models/credit_card.dart';
import '../models/financial_entry.dart';
import '../shared/mock_data.dart';

CreditCard creditCardFromInvoice(FinancialEntry invoice) {
  CreditCard? fallback;
  for (final card in mockCards) {
    if (card.id == invoice.relatedCardId) {
      fallback = card;
      break;
    }
  }

  return CreditCard(
    id: invoice.relatedCardId ?? invoice.id,
    name: invoice.name,
    bank: invoice.cardBank ?? fallback?.bank ?? invoice.name,
    brand: invoice.cardBrand ?? fallback?.brand ?? 'Não informada',
    limit:
        (invoice.cardLimitInCents ??
            ((fallback?.limit ?? 0) * 100).round()) /
        100,
    closingDay: invoice.closingDay ?? fallback?.closingDay ?? 1,
    dueDay: invoice.dueDay ?? fallback?.dueDay ?? 1,
    color: invoice.cardColor ?? fallback?.color ?? 0xFF455A64,
    isActive: invoice.isActive,
  );
}
