import '../models/financial_month.dart';
import '../services/sync_status_controller.dart';
import 'package:hive/hive.dart';

abstract class FinancialMonthStore {
  Future<FinancialMonth?> load(int year, int month);

  Future<void> save(FinancialMonth month);

  Stream<FinancialMonth> get changes => const Stream.empty();

  SyncStatusController? get syncStatus => null;

  Future<void> syncNow() async {}

  Future<void> dispose() async {}
}

class HiveFinancialMonthStore implements FinancialMonthStore {
  static const boxName = 'financial_months';

  Box<dynamic> get _box => Hive.box<dynamic>(boxName);

  @override
  Future<FinancialMonth?> load(int year, int month) async {
    final key = _key(year, month);
    final rawMonth = _box.get(key);

    if (rawMonth is! Map) {
      return null;
    }

    return FinancialMonth.fromMap(Map<dynamic, dynamic>.from(rawMonth));
  }

  @override
  Future<void> save(FinancialMonth month) async {
    await _box.put(month.storageKey, month.toMap());
  }

  String _key(int year, int month) {
    return '$year-${month.toString().padLeft(2, '0')}';
  }
}

class MemoryFinancialMonthStore implements FinancialMonthStore {
  final Map<String, Map<String, Object?>> _months = {};

  @override
  Future<FinancialMonth?> load(int year, int month) async {
    final key = '$year-${month.toString().padLeft(2, '0')}';
    final rawMonth = _months[key];

    if (rawMonth == null) {
      return null;
    }

    return FinancialMonth.fromMap(Map<dynamic, dynamic>.from(rawMonth));
  }

  @override
  Future<void> save(FinancialMonth month) async {
    _months[month.storageKey] = month.toMap();
  }
}
