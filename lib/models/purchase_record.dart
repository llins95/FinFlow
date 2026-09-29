import 'financial_entry.dart';
import 'financial_month.dart';

class PurchaseRecord {
  const PurchaseRecord({
    required this.month,
    required this.entry,
  });

  final FinancialMonth month;
  final FinancialEntry entry;

  DateTime get purchaseDate =>
      entry.purchaseDate ?? DateTime(month.year, month.month);
}
