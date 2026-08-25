import 'package:hive/hive.dart';

import '../models/household_utility_expense.dart';

abstract class HouseholdUtilityStore {
  Future<void> prepare() async {}

  Future<List<HouseholdUtilityExpense>> loadAll();

  Future<void> save(HouseholdUtilityExpense expense);

  Future<void> deleteAll();

  Future<void> syncNow() async {}

  Future<void> dispose() async {}
}

class HiveHouseholdUtilityStore implements HouseholdUtilityStore {
  HiveHouseholdUtilityStore({this.userId});

  static const String boxName = 'household_utility_expenses';

  final String? userId;
  Box<dynamic>? _box;

  @override
  Future<void> prepare() async {
    if (_box != null) {
      return;
    }
    _box = Hive.isBoxOpen(boxName)
        ? Hive.box<dynamic>(boxName)
        : await Hive.openBox<dynamic>(boxName);
  }

  @override
  Future<List<HouseholdUtilityExpense>> loadAll() async {
    await prepare();
    final result = <HouseholdUtilityExpense>[];
    final prefix = userId == null ? null : '$userId/';

    for (final key in _box!.keys) {
      final keyText = key.toString();
      if (prefix != null && !keyText.startsWith(prefix)) {
        continue;
      }
      if (prefix == null && keyText.contains('/')) {
        continue;
      }
      final raw = _box!.get(key);
      if (raw is Map) {
        result.add(
          HouseholdUtilityExpense.fromMap(Map<dynamic, dynamic>.from(raw)),
        );
      }
    }

    result.sort((a, b) {
      final yearCompare = a.year.compareTo(b.year);
      if (yearCompare != 0) {
        return yearCompare;
      }
      return a.month.compareTo(b.month);
    });
    return result;
  }

  @override
  Future<void> save(HouseholdUtilityExpense expense) async {
    await prepare();
    await _box!.put(_scopedKey(expense.storageKey), expense.toMap());
  }

  @override
  Future<void> deleteAll() async {
    await prepare();
    final prefix = userId == null ? null : '$userId/';
    final keys = _box!.keys.where((key) {
      final text = key.toString();
      if (prefix == null) {
        return !text.contains('/');
      }
      return text.startsWith(prefix);
    }).toList();
    await _box!.deleteAll(keys);
  }

  String _scopedKey(String key) {
    return userId == null ? key : '$userId/$key';
  }

  static Future<void> clearForUser(String? userId) async {
    final store = HiveHouseholdUtilityStore(userId: userId);
    await store.deleteAll();
  }
}

class MemoryHouseholdUtilityStore implements HouseholdUtilityStore {
  final Map<String, Map<String, Object?>> _records = {};

  @override
  Future<List<HouseholdUtilityExpense>> loadAll() async {
    return _records.values
        .map(
          (raw) => HouseholdUtilityExpense.fromMap(
            Map<dynamic, dynamic>.from(raw),
          ),
        )
        .toList();
  }

  @override
  Future<void> save(HouseholdUtilityExpense expense) async {
    _records[expense.storageKey] = expense.toMap();
  }

  @override
  Future<void> deleteAll() async {
    _records.clear();
  }
}
