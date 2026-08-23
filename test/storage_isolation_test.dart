import 'dart:io';

import 'package:finflow/models/financial_entry.dart';
import 'package:finflow/models/financial_month.dart';
import 'package:finflow/shared/financial_month_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  late Directory hiveDirectory;

  setUpAll(() async {
    hiveDirectory = await Directory.systemTemp.createTemp(
      'finflow-storage-isolation-',
    );
    Hive.init(hiveDirectory.path);
    await Hive.openBox<dynamic>(HiveFinancialMonthStore.boxName);
  });

  setUp(() async {
    await Hive.box<dynamic>(HiveFinancialMonthStore.boxName).clear();
  });

  tearDownAll(() async {
    await Hive.close();
    await hiveDirectory.delete(recursive: true);
  });

  test('separa os meses locais por usuário', () async {
    final firstUser = HiveFinancialMonthStore(userId: 'user-a');
    final secondUser = HiveFinancialMonthStore(userId: 'user-b');
    await firstUser.save(_month('expense-a'));

    expect(await secondUser.load(2026, 8), isNull);

    await secondUser.save(_month('expense-b'));
    expect((await firstUser.load(2026, 8))!.entries.single.id, 'expense-a');
    expect((await secondUser.load(2026, 8))!.entries.single.id, 'expense-b');

    await firstUser.deleteAll();
    expect(await firstUser.load(2026, 8), isNull);
    expect((await secondUser.load(2026, 8))!.entries.single.id, 'expense-b');
  });

  test('migra a chave antiga somente para o usuário autenticado', () async {
    final box = Hive.box<dynamic>(HiveFinancialMonthStore.boxName);
    await box.put('2026-08', _month('legacy').toMap());
    final store = HiveFinancialMonthStore(userId: 'user-a');

    await store.migrateLegacyData();

    expect(box.containsKey('2026-08'), isFalse);
    expect(box.containsKey('user-a/2026-08'), isTrue);
    expect((await store.load(2026, 8))!.entries.single.id, 'legacy');
  });
}

FinancialMonth _month(String entryId) {
  return FinancialMonth(
    year: 2026,
    month: 8,
    entries: [
      FinancialEntry(
        id: entryId,
        name: 'Despesa de teste',
        amountInCents: 1000,
        type: FinancialEntryType.expense,
      ),
    ],
  );
}
