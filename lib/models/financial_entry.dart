enum FinancialEntryType {
  cardInvoice,
  expense,
  income,
  previousBalance,
  purchase,
}

class FinancialEntry {
  final String id;
  final String name;
  final int amountInCents;
  final FinancialEntryType type;
  final bool isRecurring;
  final bool isActive;
  final bool isPaid;
  final String? relatedCardId;
  final String? relatedCardName;
  final String? cardBank;
  final String? cardBrand;
  final int? cardLimitInCents;
  final int? cardColor;
  final int? closingDay;
  final int? dueDay;
  final DateTime? purchaseDate;
  final int? installments;
  final String? sourceReference;

  const FinancialEntry({
    required this.id,
    required this.name,
    required this.amountInCents,
    required this.type,
    this.isRecurring = false,
    this.isActive = true,
    this.isPaid = false,
    this.relatedCardId,
    this.relatedCardName,
    this.cardBank,
    this.cardBrand,
    this.cardLimitInCents,
    this.cardColor,
    this.closingDay,
    this.dueDay,
    this.purchaseDate,
    this.installments,
    this.sourceReference,
  });

  bool get isDebt =>
      type == FinancialEntryType.cardInvoice ||
      type == FinancialEntryType.expense;

  FinancialEntry copyWith({
    String? name,
    int? amountInCents,
    bool? isRecurring,
    bool? isActive,
    bool? isPaid,
    String? relatedCardId,
    String? relatedCardName,
    String? cardBank,
    String? cardBrand,
    int? cardLimitInCents,
    int? cardColor,
    int? closingDay,
    int? dueDay,
    DateTime? purchaseDate,
    int? installments,
    String? sourceReference,
  }) {
    return FinancialEntry(
      id: id,
      name: name ?? this.name,
      amountInCents: amountInCents ?? this.amountInCents,
      type: type,
      isRecurring: isRecurring ?? this.isRecurring,
      isActive: isActive ?? this.isActive,
      isPaid: isPaid ?? this.isPaid,
      relatedCardId: relatedCardId ?? this.relatedCardId,
      relatedCardName: relatedCardName ?? this.relatedCardName,
      cardBank: cardBank ?? this.cardBank,
      cardBrand: cardBrand ?? this.cardBrand,
      cardLimitInCents: cardLimitInCents ?? this.cardLimitInCents,
      cardColor: cardColor ?? this.cardColor,
      closingDay: closingDay ?? this.closingDay,
      dueDay: dueDay ?? this.dueDay,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      installments: installments ?? this.installments,
      sourceReference: sourceReference ?? this.sourceReference,
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
      'isPaid': isPaid,
      'relatedCardId': relatedCardId,
      'relatedCardName': relatedCardName,
      'cardBank': cardBank,
      'cardBrand': cardBrand,
      'cardLimitInCents': cardLimitInCents,
      'cardColor': cardColor,
      'closingDay': closingDay,
      'dueDay': dueDay,
      'purchaseDate': purchaseDate?.toIso8601String(),
      'installments': installments,
      'sourceReference': sourceReference,
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
      isPaid: map['isPaid'] as bool? ?? false,
      relatedCardId: map['relatedCardId'] as String?,
      relatedCardName: map['relatedCardName'] as String?,
      cardBank: map['cardBank'] as String?,
      cardBrand: map['cardBrand'] as String?,
      cardLimitInCents: (map['cardLimitInCents'] as num?)?.toInt(),
      cardColor: (map['cardColor'] as num?)?.toInt(),
      closingDay: (map['closingDay'] as num?)?.toInt(),
      dueDay: (map['dueDay'] as num?)?.toInt(),
      purchaseDate: _parseDate(map['purchaseDate']),
      installments: (map['installments'] as num?)?.toInt(),
      sourceReference: map['sourceReference'] as String?,
    );
  }

  static DateTime? _parseDate(Object? value) {
    if (value is DateTime) {
      return DateTime(value.year, value.month, value.day);
    }
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) {
        return DateTime(parsed.year, parsed.month, parsed.day);
      }
    }
    return null;
  }
}
