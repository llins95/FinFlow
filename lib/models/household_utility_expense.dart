enum HouseholdUtilityKind { water, electricity }

class HouseholdUtilityExpense {
  HouseholdUtilityExpense({
    required this.year,
    required this.month,
    this.waterInCents = 0,
    this.electricityInCents = 0,
    DateTime? clientUpdatedAt,
  }) : clientUpdatedAt = (clientUpdatedAt ?? DateTime.now()).toUtc();

  final int year;
  final int month;
  final int waterInCents;
  final int electricityInCents;
  final DateTime clientUpdatedAt;

  String get storageKey => '$year-${month.toString().padLeft(2, '0')}';

  bool get isEmpty => waterInCents == 0 && electricityInCents == 0;

  int amountFor(HouseholdUtilityKind kind) {
    return switch (kind) {
      HouseholdUtilityKind.water => waterInCents,
      HouseholdUtilityKind.electricity => electricityInCents,
    };
  }

  HouseholdUtilityExpense withAmount(
    HouseholdUtilityKind kind,
    int amountInCents,
  ) {
    final now = DateTime.now().toUtc();
    final nextUpdatedAt = now.isAfter(clientUpdatedAt)
        ? now
        : clientUpdatedAt.add(const Duration(microseconds: 1));

    return HouseholdUtilityExpense(
      year: year,
      month: month,
      waterInCents: kind == HouseholdUtilityKind.water
          ? amountInCents
          : waterInCents,
      electricityInCents: kind == HouseholdUtilityKind.electricity
          ? amountInCents
          : electricityInCents,
      clientUpdatedAt: nextUpdatedAt,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'year': year,
      'month': month,
      'waterInCents': waterInCents,
      'electricityInCents': electricityInCents,
      'clientUpdatedAt': clientUpdatedAt.toIso8601String(),
    };
  }

  factory HouseholdUtilityExpense.fromMap(Map<dynamic, dynamic> map) {
    return HouseholdUtilityExpense(
      year: (map['year'] as num).toInt(),
      month: (map['month'] as num).toInt(),
      waterInCents: ((map['waterInCents'] ?? map['water_in_cents'] ?? 0) as num)
          .toInt(),
      electricityInCents:
          ((map['electricityInCents'] ?? map['electricity_in_cents'] ?? 0)
                  as num)
              .toInt(),
      clientUpdatedAt: _parseTimestamp(
        map['clientUpdatedAt'] ?? map['client_updated_at'],
      ),
    );
  }

  factory HouseholdUtilityExpense.fromSupabaseRow(
    Map<String, dynamic> row,
  ) {
    return HouseholdUtilityExpense.fromMap(row);
  }

  static DateTime _parseTimestamp(Object? value) {
    if (value is DateTime) {
      return value.toUtc();
    }
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) {
        return parsed.toUtc();
      }
    }
    return DateTime.now().toUtc();
  }
}
