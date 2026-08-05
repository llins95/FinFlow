enum FinancialEntryType {
  cardInvoice,
  expense,
  income,
  previousBalance,
}

class FinancialEntry {
  final String id;
  final String name;
  final int amountInCents;
  final FinancialEntryType type;
  final bool isRecurring;
  final String? relatedCardId;
  final int? closingDay;
  final int? dueDay;

  const FinancialEntry({
    required this.id,
    required this.name,
    required this.amountInCents,
    required this.type,
    this.isRecurring = false,
    this.relatedCardId,
    this.closingDay,
    this.dueDay,
  });

  bool get isDebt =>
      type == FinancialEntryType.cardInvoice ||
      type == FinancialEntryType.expense;

  FinancialEntry copyWith({
    String? name,
    int? amountInCents,
    bool? isRecurring,
  }) {
    return FinancialEntry(
      id: id,
      name: name ?? this.name,
      amountInCents: amountInCents ?? this.amountInCents,
      type: type,
      isRecurring: isRecurring ?? this.isRecurring,
      relatedCardId: relatedCardId,
      closingDay: closingDay,
      dueDay: dueDay,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'amountInCents': amountInCents,
      'type': type.name,
      'isRecurring': isRecurring,
      'relatedCardId': relatedCardId,
      'closingDay': closingDay,
      'dueDay': dueDay,
    };
  }

  factory FinancialEntry.fromMap(Map<dynamic, dynamic> map) {
    final typeName = map['type'] as String?;
    final type = FinancialEntryType.values.firstWhere(
      (item) => item.name == typeName,
      orElse: () => FinancialEntryType.expense,
    );

    return FinancialEntry(
      id: map['id'] as String,
      name: map['name'] as String,
      amountInCents: (map['amountInCents'] as num).toInt(),
      type: type,
      isRecurring: map['isRecurring'] as bool? ?? false,
      relatedCardId: map['relatedCardId'] as String?,
      closingDay: (map['closingDay'] as num?)?.toInt(),
      dueDay: (map['dueDay'] as num?)?.toInt(),
    );
  }
}
