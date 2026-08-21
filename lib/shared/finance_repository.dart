import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../models/financial_entry.dart';

class FinanceRepository {
  static Box get entriesBox => Hive.box('financial_entries');
  static Box get paymentsBox => Hive.box('invoice_payments');
  static Box get settingsBox => Hive.box('settings');

  static List<FinancialEntry> get entries => entriesBox.values
      .map((value) => FinancialEntry.fromMap(Map<dynamic, dynamic>.from(value as Map)))
      .toList()..sort((a, b) => b.dueDate.compareTo(a.dueDate));

  static Future<void> saveEntry(FinancialEntry entry) => entriesBox.put(entry.id, entry.toMap());
  static Future<void> removeEntry(String id) => entriesBox.delete(id);

  static Future<void> createEntries({
    required String description,
    required int amountInCents,
    required EntryType type,
    required DateTime firstDate,
    DateTime? repeatUntil,
  }) async {
    final recurrenceId = repeatUntil == null ? null : const Uuid().v4();
    var date = firstDate;
    do {
      final entry = FinancialEntry(
        id: const Uuid().v4(), description: description, amountInCents: amountInCents,
        type: type, dueDate: date, recurrenceId: recurrenceId,
      );
      await saveEntry(entry);
      if (repeatUntil == null) break;
      date = addMonths(date, 1);
    } while (!date.isAfter(DateTime(repeatUntil.year, repeatUntil.month, repeatUntil.day)));
  }

  static String invoiceKey(String cardId, DateTime month) =>
      '$cardId-${month.year}-${month.month.toString().padLeft(2, '0')}';
  static bool isInvoicePaid(String cardId, DateTime month) =>
      paymentsBox.get(invoiceKey(cardId, month), defaultValue: false) as bool;
  static Future<void> setInvoicePaid(String cardId, DateTime month, bool paid) =>
      paymentsBox.put(invoiceKey(cardId, month), paid);

  static DateTime addMonths(DateTime date, int count) {
    final total = date.year * 12 + date.month - 1 + count;
    final year = total ~/ 12;
    final month = total % 12 + 1;
    final day = date.day.clamp(1, DateTime(year, month + 1, 0).day);
    return DateTime(year, month, day);
  }
}
