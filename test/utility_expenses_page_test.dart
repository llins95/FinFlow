import 'package:finflow/features/settings/pages/utility_expenses_page.dart';
import 'package:finflow/shared/utility_expenses_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeUtilityExpensesRepository extends UtilityExpensesRepository {
  _FakeUtilityExpensesRepository() : super(scope: 'test');

  final Map<String, UtilityExpenseMonth> values = {};

  @override
  Future<List<UtilityExpenseMonth>> loadYear(int year) async {
    return List.generate(
      12,
      (index) => values['$year-${index + 1}'] ??
          UtilityExpenseMonth(year: year, month: index + 1),
    );
  }

  @override
  Future<void> save(UtilityExpenseMonth value) async {
    values['${value.year}-${value.month}'] = value;
  }
}

void main() {
  Widget app(Widget home) => MaterialApp(
        locale: const Locale('pt', 'BR'),
        supportedLocales: const [Locale('pt', 'BR')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: home,
      );

  testWidgets('mostra Água e Luz separados por mês e ano', (tester) async {
    final repository = _FakeUtilityExpensesRepository();
    repository.values['2026-1'] = const UtilityExpenseMonth(
      year: 2026,
      month: 1,
      waterInCents: 12550,
      electricityInCents: 28990,
    );

    await tester.pumpWidget(
      app(
        UtilityExpensesPage(
          storageScope: 'test',
          repository: repository,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Despesas Água/Luz'), findsOneWidget);
    expect(find.text('2026'), findsWidgets);
    expect(find.text('Água'), findsWidgets);
    expect(find.text('Luz'), findsWidgets);
    expect(find.text('R\$ 125,50'), findsOneWidget);

    await tester.tap(find.text('Luz').first);
    await tester.pumpAndSettle();

    expect(find.text('R\$ 289,90'), findsOneWidget);
  });
}
