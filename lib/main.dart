import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app/app.dart';
import 'models/purchase.dart';
import 'models/purchase_adapter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(PurchaseAdapter());
  }

  await Hive.openBox<Purchase>('purchases');

  runApp(const FinFlowApp());
}
