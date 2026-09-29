import '../models/financial_month.dart';
import '../services/sync_status_controller.dart';
import 'package:hive/hive.dart';

abstract class FinancialMonthStore {
  Future<void> prepare() async {}

  Future<FinancialMonth?> load(int year, int month);

  Future<void> save(FinancialMonth month);

  Future<void> deleteAll();

  Stream<FinancialMonth> get changes => const Stream.empty();

  SyncStatusController? get syncStatus => null;

  Future<void> syncNow() async {}

  Future<void> dispose() async {}
}

class HiveFinancialMonthStore extends FinancialMonthStore {
  static const boxName = 'financial_months';

  HiveFinancialMonthStore({this.userId});

  final String? userId;

  Box<dynamic> get _box => Hive.box<dynamic>(boxName);

  @override
  Future<FinancialMonth?> load(int year, int month) async {
    final key = _scopedKey(_key(year, month));
    final rawMonth = _box.get(key);

    if (rawMonth is! Map) {
      return null;
    }

    return FinancialMonth.fromMap(Map<dynamic, dynamic>.from(rawMonth));
  }

  @override
  Future<void> save(FinancialMonth month) async {
    await _box.put(_scopedKey(month.storageKey), month.toMap());
  }

  Future<void> migrateLegacyData() async {
    if (userId == null) {
      return;
    }

    final legacyKeys = _box.keys
        .map((key) => key.toString())
        .where((key) => RegExp(r'^\d{4}-\d{2}$').hasMatch(key))
        .toList();
    for (final key in legacyKeys) {
      final scopedKey = _scopedKey(key);
      if (!_box.containsKey(scopedKey)) {
        await _box.put(scopedKey, _box.get(key));
      }
      await _box.delete(key);
    }
  }

  @override
  Future<void> deleteAll() async {
    final prefix = userId == null ? null : '$userId/';
    final keys = _box.keys
        .where((key) => prefix == null || key.toString().startsWith(prefix))
        .toList();
    await _box.deleteAll(keys);
  }

  Future<void> delete(int year, int month) {
    return _box.delete(_scopedKey(_key(year, month)));
  }

  String _key(int year, int month) {
    return '$year-${month.toString().padLeft(2, '0')}';
  }

  String _scopedKey(String key) {
    return userId == null ? key : '$userId/$key';
  }
}

class MemoryFinancialMonthStore extends FinancialMonthStore {
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

  @override
  Future<void> deleteAll() async {
    _months.clear();
  }
}
