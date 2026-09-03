enum FinancialEntryType {
  cardInvoice,
  expense,
  income,
  previousBalance,
  purchase,
  appSettings,
}

class FinancialEntry {
  final String id;
  final String name;
  final int amountInCents;
  final FinancialEntryType type;
  final bool isRecurring;
  final bool isActive;
  final bool isPaid;
  final DateTime? recurrenceEndMonth;
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
  final Map<String, Object?>? metadata;

  const FinancialEntry({
    required this.id,
    required this.name,
    required this.amountInCents,
    required this.type,
    this.isRecurring = false,
    this.isActive = true,
    this.isPaid = false,
    this.recurrenceEndMonth,
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
    this.metadata,
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
    Object? recurrenceEndMonth = _unset,
    String? relatedCardId,
    String? relatedCardName,
    String? cardBank,
    String? cardBrand,
    int? cardLimitInCents,
    int? cardColor,
    int? closingDay,
    Object? dueDay = _unset,
    DateTime? purchaseDate,
    int? installments,
    String? sourceReference,
    Object? metadata = _unset,
  }) {
    return FinancialEntry(
      id: id,
      name: name ?? this.name,
      amountInCents: amountInCents ?? this.amountInCents,
      type: type,
      isRecurring: isRecurring ?? this.isRecurring,
      isActive: isActive ?? this.isActive,
      isPaid: isPaid ?? this.isPaid,
      recurrenceEndMonth: identical(recurrenceEndMonth, _unset)
          ? this.recurrenceEndMonth
          : recurrenceEndMonth as DateTime?,
      relatedCardId: relatedCardId ?? this.relatedCardId,
      relatedCardName: relatedCardName ?? this.relatedCardName,
      cardBank: cardBank ?? this.cardBank,
      cardBrand: cardBrand ?? this.cardBrand,
      cardLimitInCents: cardLimitInCents ?? this.cardLimitInCents,
      cardColor: cardColor ?? this.cardColor,
      closingDay: closingDay ?? this.closingDay,
      dueDay: identical(dueDay, _unset) ? this.dueDay : dueDay as int?,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      installments: installments ?? this.installments,
      sourceReference: sourceReference ?? this.sourceReference,
      metadata: identical(metadata, _unset)
          ? this.metadata
          : metadata as Map<String, Object?>?,
    );
  }

  bool recursInto(DateTime targetMonth) {
    if (!isRecurring || !isActive) {
      return false;
    }

    final endMonth = recurrenceEndMonth;
    return endMonth == null ||
        !DateTime(
          targetMonth.year,
          targetMonth.month,
        ).isAfter(DateTime(endMonth.year, endMonth.month));
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
      'recurrenceEndMonth': recurrenceEndMonth?.toIso8601String(),
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
      'metadata': metadata,
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
      recurrenceEndMonth: _parseMonth(map['recurrenceEndMonth']),
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
      metadata: _parseMetadata(map['metadata']),
    );
  }

  static DateTime? _parseMonth(Object? value) {
    final parsed = _parseDate(value);
    return parsed == null ? null : DateTime(parsed.year, parsed.month);
  }

  static Map<String, Object?>? _parseMetadata(Object? value) {
    if (value is! Map) {
      return null;
    }
    return Map<String, Object?>.from(value);
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

const Object _unset = Object();
