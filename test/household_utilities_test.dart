import 'package:finflow/controllers/household_utility_controller.dart';
import 'package:finflow/features/settings/pages/household_utilities_page.dart';
import 'package:finflow/models/household_utility_expense.dart';
import 'package:finflow/shared/household_utility_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('pt_BR');
  });

  Widget app(HouseholdUtilityController controller) {
    return MaterialApp(
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: HouseholdUtilitiesPage(controller: controller),
    );
  }

  testWidgets('água e luz ficam separadas por mês e ano', (tester) async {
    final controller = HouseholdUtilityController(
      MemoryHouseholdUtilityStore(),
      initialYear: 2026,
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(app(controller));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('household-utility-water-2026-1')),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('household-utility-value-field')),
      '289,96',
    );
    await tester.tap(
      find.byKey(const ValueKey('household-utility-save')),
    );
    await tester.pumpAndSettle();

    expect(controller.amountFor(1, HouseholdUtilityKind.water), 28996);
    expect(controller.amountFor(1, HouseholdUtilityKind.electricity), 0);
    expect(find.text('R\$ 289,96'), findsOneWidget);

    await tester.tap(find.text('Luz'));
    await tester.pumpAndSettle();
    expect(find.text('R\$ 289,96'), findsNothing);

    await tester.tap(
      find.byKey(const ValueKey('household-utility-light-2026-1')),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('household-utility-value-field')),
      '361,26',
    );
    await tester.tap(
      find.byKey(const ValueKey('household-utility-save')),
    );
    await tester.pumpAndSettle();

    expect(controller.amountFor(1, HouseholdUtilityKind.water), 28996);
    expect(controller.amountFor(1, HouseholdUtilityKind.electricity), 36126);
  });

  testWidgets('permite navegar para anos anteriores como na planilha', (
    tester,
  ) async {
    final controller = HouseholdUtilityController(
      MemoryHouseholdUtilityStore(),
      initialYear: 2026,
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(app(controller));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('household-utility-previous-year')),
    );
    await tester.pump();
    expect(find.text('2025'), findsWidgets);

    await tester.tap(
      find.byKey(const ValueKey('household-utility-previous-year')),
    );
    await tester.pump();
    expect(find.text('2024'), findsWidgets);
  });
}
