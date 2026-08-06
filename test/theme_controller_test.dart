import 'package:finflow/controllers/theme_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('altera e persiste claro, escuro e padrão do sistema', () async {
    final persisted = <ThemeMode>[];
    final controller = ThemeController(
      persist: (mode) async => persisted.add(mode),
    );
    addTearDown(controller.dispose);

    expect(controller.mode, ThemeMode.system);

    await controller.setMode(ThemeMode.light);
    expect(controller.mode, ThemeMode.light);

    await controller.setMode(ThemeMode.dark);
    expect(controller.mode, ThemeMode.dark);

    await controller.setMode(ThemeMode.system);
    expect(controller.mode, ThemeMode.system);
    expect(persisted, [ThemeMode.light, ThemeMode.dark, ThemeMode.system]);
  });

  test('restaura o modo salvo com fallback para o sistema', () {
    expect(ThemeController.fromStorage('light'), ThemeMode.light);
    expect(ThemeController.fromStorage('dark'), ThemeMode.dark);
    expect(ThemeController.fromStorage('system'), ThemeMode.system);
    expect(ThemeController.fromStorage('valor-inválido'), ThemeMode.system);
  });
}
