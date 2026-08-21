import 'package:hive/hive.dart';

import '../models/purchase.dart';

class PurchaseRepository {
  static Box<Purchase> get box => Hive.box<Purchase>('purchases');

  static List<Purchase> get purchases => box.values.toList();

  static Future<void> add(Purchase purchase) async {
    await box.put(purchase.id, purchase);
  }

  static Future<void> remove(String id) async {
    await box.delete(id);
  }

  static Future<void> update(Purchase purchase) async {
    await box.put(purchase.id, purchase);
  }
}
