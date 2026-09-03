import 'package:finflow/utils/select_all_on_focus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('seleciona todo o número quando o campo recebe foco', (
    tester,
  ) async {
    final controller = TextEditingController(text: '0,00');
    final focusNode = SelectAllOnFocusNode(controller);
    addTearDown(() {
      focusNode.dispose();
      controller.dispose();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TextField(controller: controller, focusNode: focusNode),
        ),
      ),
    );

    await tester.tap(find.byType(TextField));
    await tester.pump();

    expect(
      controller.selection,
      const TextSelection(baseOffset: 0, extentOffset: 4),
    );
  });

  testWidgets('também seleciona valores inteiros por teclado', (tester) async {
    final firstController = TextEditingController(text: '10');
    final secondController = TextEditingController(text: '1');
    final firstFocus = SelectAllOnFocusNode(firstController);
    final secondFocus = SelectAllOnFocusNode(secondController);
    addTearDown(() {
      firstFocus.dispose();
      secondFocus.dispose();
      firstController.dispose();
      secondController.dispose();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              TextField(controller: firstController, focusNode: firstFocus),
              TextField(controller: secondController, focusNode: secondFocus),
            ],
          ),
        ),
      ),
    );

    firstFocus.requestFocus();
    await tester.pump();
    expect(
      firstController.selection,
      const TextSelection(baseOffset: 0, extentOffset: 2),
    );

    secondFocus.requestFocus();
    await tester.pump();
    expect(
      secondController.selection,
      const TextSelection(baseOffset: 0, extentOffset: 1),
    );
  });
}
