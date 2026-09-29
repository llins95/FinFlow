import 'package:flutter/material.dart';

/// Seleciona todo o conteúdo numérico quando o campo recebe foco.
///
/// Isso permite substituir valores como `0,00`, dias e parcelas apenas
/// começando a digitar, tanto pelo toque quanto pela navegação por teclado.
class SelectAllOnFocusNode extends FocusNode {
  SelectAllOnFocusNode(this.controller) {
    addListener(_handleFocusChange);
  }

  final TextEditingController controller;

  void _handleFocusChange() {
    if (!hasFocus || controller.text.isEmpty) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!hasFocus || controller.text.isEmpty) {
        return;
      }
      controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: controller.text.length,
      );
    });
  }

  @override
  void dispose() {
    removeListener(_handleFocusChange);
    super.dispose();
  }
}
