import 'package:hive/hive.dart';

class UtilityExpenseMonth {
  const UtilityExpenseMonth({
    required this.year,
    required this.month,
    this.waterInCents = 0,
    this.electricityInCents = 0,
  });

  final int year;
  final int month;
  final int waterInCents;
  final int electricityInCents;

  UtilityExpenseMonth copyWith({int? waterInCents, int? electricityInCents}) {
    return UtilityExpenseMonth(
      year: year,
      month: month,
      waterInCents: waterInCents ?? this.waterInCents,
      electricityInCents: electricityInCents ?? this.electricityInCents,
    );
  }

  Map<String, Object?> toMap() => {
    'year': year,
    'month': month,
    'waterInCents': waterInCents,
    'electricityInCents': electricityInCents,
  };

  factory UtilityExpenseMonth.fromMap(Map<dynamic, dynamic> map) {
    return UtilityExpenseMonth(
      year: (map['year'] as num).toInt(),
      month: (map['month'] as num).toInt(),
      waterInCents: (map['waterInCents'] as num?)?.toInt() ?? 0,
      electricityInCents: (map['electricityInCents'] as num?)?.toInt() ?? 0,
    );
  }
}

class UtilityExpensesRepository {
  UtilityExpensesRepository({required this.scope});

  static const boxName = 'utility_expenses';
  final String scope;

  Future<Box<dynamic>> _box() async {
    if (Hive.isBoxOpen(boxName)) return Hive.box<dynamic>(boxName);
    return Hive.openBox<dynamic>(boxName);
  }

  String _key(int year, int month) => '$scope:$year-${month.toString().padLeft(2, '0')}';

  Future<UtilityExpenseMonth> load(int year, int month) async {
    final box = await _box();
    final raw = box.get(_key(year, month));
    if (raw is Map) return UtilityExpenseMonth.fromMap(raw);
    return UtilityExpenseMonth(year: year, month: month);
  }

  Future<List<UtilityExpenseMonth>> loadYear(int year) async {
    final values = <UtilityExpenseMonth>[];
    for (var month = 1; month <= 12; month++) {
      values.add(await load(year, month));
    }
    return values;
  }

  Future<void> save(UtilityExpenseMonth value) async {
    final box = await _box();
    await box.put(_key(value.year, value.month), value.toMap());
  }
}
