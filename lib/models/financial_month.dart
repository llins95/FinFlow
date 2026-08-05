import 'financial_entry.dart';

class FinancialMonth {
  final int year;
  final int month;
  final List<FinancialEntry> entries;

  FinancialMonth({
    required this.year,
    required this.month,
    required List<FinancialEntry> entries,
  }) : entries = List.unmodifiable(entries);

  DateTime get date => DateTime(year, month);

  String get storageKey =>
      '$year-${month.toString().padLeft(2, '0')}';

  List<FinancialEntry> entriesOfType(FinancialEntryType type) {
    return entries.where((entry) => entry.type == type).toList();
  }

  int get totalDebtInCents => entries
      .where((entry) => entry.isDebt)
      .fold(0, (total, entry) => total + entry.amountInCents);

  int get totalAvailableInCents => entries
      .where(
        (entry) =>
            entry.type == FinancialEntryType.income ||
            entry.type == FinancialEntryType.previousBalance,
      )
      .fold(0, (total, entry) => total + entry.amountInCents);

  int get balanceInCents => totalAvailableInCents - totalDebtInCents;

  FinancialMonth replaceEntry(FinancialEntry updatedEntry) {
    return FinancialMonth(
      year: year,
      month: month,
      entries: entries
          .map(
            (entry) => entry.id == updatedEntry.id ? updatedEntry : entry,
          )
          .toList(),
    );
  }

  FinancialMonth addEntry(FinancialEntry entry) {
    return FinancialMonth(
      year: year,
      month: month,
      entries: [...entries, entry],
    );
  }

  FinancialMonth removeEntry(String entryId) {
    return FinancialMonth(
      year: year,
      month: month,
      entries: entries.where((entry) => entry.id != entryId).toList(),
    );
  }

  FinancialMonth createNextMonth() {
    final nextDate = DateTime(year, month + 1);
    final recurringEntries = entries
        .where(
          (entry) =>
              entry.isRecurring &&
              entry.type != FinancialEntryType.previousBalance,
        )
        .map(
          (entry) => entry.type == FinancialEntryType.cardInvoice
              ? entry.copyWith(amountInCents: 0)
              : entry,
        )
        .toList();

    return FinancialMonth(
      year: nextDate.year,
      month: nextDate.month,
      entries: [
        FinancialEntry(
          id: 'previous-balance',
          name: 'Saldo do mês anterior',
          amountInCents: balanceInCents,
          type: FinancialEntryType.previousBalance,
        ),
        ...recurringEntries,
      ],
    );
  }

  Map<String, Object?> toMap() {
    return {
      'year': year,
      'month': month,
      'entries': entries.map((entry) => entry.toMap()).toList(),
    };
  }

  factory FinancialMonth.fromMap(Map<dynamic, dynamic> map) {
    final rawEntries = map['entries'] as List<dynamic>? ?? const [];

    return FinancialMonth(
      year: (map['year'] as num).toInt(),
      month: (map['month'] as num).toInt(),
      entries: rawEntries
          .map(
            (entry) => FinancialEntry.fromMap(
              Map<dynamic, dynamic>.from(entry as Map),
            ),
          )
          .toList(),
    );
  }
}
