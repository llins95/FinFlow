import 'package:hive/hive.dart';

import '../models/purchase.dart';

class PurchaseRepository {
  static Box<Purchase> get _box => Hive.box<Purchase>('purchases');

  static List<Purchase> get purchases => _box.values.toList();

  static Future<void> add(Purchase purchase) async {
    await _box.put(purchase.id, purchase);
  }

  static Future<void> remove(String id) async {
    await _box.delete(id);
  }

  static Future<void> update(Purchase purchase) async {
    await _box.put(purchase.id, purchase);
  }
}
