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
  final bool isActive;
  final String? relatedCardId;
  final String? cardBank;
  final String? cardBrand;
  final int? cardLimitInCents;
  final int? cardColor;
  final int? closingDay;
  final int? dueDay;

  const FinancialEntry({
    required this.id,
    required this.name,
    required this.amountInCents,
    required this.type,
    this.isRecurring = false,
    this.isActive = true,
    this.relatedCardId,
    this.cardBank,
    this.cardBrand,
    this.cardLimitInCents,
    this.cardColor,
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
    bool? isActive,
    String? cardBank,
    String? cardBrand,
    int? cardLimitInCents,
    int? cardColor,
    int? closingDay,
    int? dueDay,
  }) {
    return FinancialEntry(
      id: id,
      name: name ?? this.name,
      amountInCents: amountInCents ?? this.amountInCents,
      type: type,
      isRecurring: isRecurring ?? this.isRecurring,
      isActive: isActive ?? this.isActive,
      relatedCardId: relatedCardId,
      cardBank: cardBank ?? this.cardBank,
      cardBrand: cardBrand ?? this.cardBrand,
      cardLimitInCents: cardLimitInCents ?? this.cardLimitInCents,
      cardColor: cardColor ?? this.cardColor,
      closingDay: closingDay ?? this.closingDay,
      dueDay: dueDay ?? this.dueDay,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'amountInCents': amountInCents,
      'type': type.name,
      'isRecurring': isRecurring,
      'isActive': isActive,
      'relatedCardId': relatedCardId,
      'cardBank': cardBank,
      'cardBrand': cardBrand,
      'cardLimitInCents': cardLimitInCents,
      'cardColor': cardColor,
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
      isActive: map['isActive'] as bool? ?? true,
      relatedCardId: map['relatedCardId'] as String?,
      cardBank: map['cardBank'] as String?,
      cardBrand: map['cardBrand'] as String?,
      cardLimitInCents: (map['cardLimitInCents'] as num?)?.toInt(),
      cardColor: (map['cardColor'] as num?)?.toInt(),
      closingDay: (map['closingDay'] as num?)?.toInt(),
      dueDay: (map['dueDay'] as num?)?.toInt(),
    );
  }
}
