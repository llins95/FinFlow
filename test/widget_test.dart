import 'package:finflow/app/app.dart';
import 'package:finflow/controllers/financial_month_controller.dart';
import 'package:finflow/shared/financial_month_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('exibe o resumo financeiro de agosto de 2026', (tester) async {
    final controller = FinancialMonthController(MemoryFinancialMonthStore());
    await controller.initialize(now: DateTime(2026, 8, 5));

    await tester.pumpWidget(
      FinFlowApp(financialMonthController: controller),
    );
    await tester.pumpAndSettle();

    expect(find.text('FinFlow'), findsOneWidget);
    expect(find.text('Agosto 2026'), findsOneWidget);
    expect(find.text('Total a pagar'), findsOneWidget);
    expect(find.textContaining('5.759,27'), findsOneWidget);
    expect(find.textContaining('4.875,57'), findsOneWidget);
    expect(find.text('Falta'), findsOneWidget);
    expect(find.textContaining('883,70'), findsOneWidget);
  });
}
