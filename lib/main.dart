import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'models/purchase.dart';
import 'models/purchase_adapter.dart';
import 'services/supabase_financial_month_store.dart';
import 'shared/financial_month_repository.dart';
import 'shared/supabase_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(PurchaseAdapter());
  }

  await Hive.openBox<Purchase>('purchases');
  await Hive.openBox<dynamic>(HiveFinancialMonthStore.boxName);
  await Hive.openBox<dynamic>(SupabaseFinancialMonthStore.queueBoxName);

  SupabaseClient? supabaseClient;
  if (SupabaseConfig.isConfigured) {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.publishableKey,
    );
    supabaseClient = Supabase.instance.client;
  }

  runApp(FinFlowApp(supabaseClient: supabaseClient));
}
