import 'package:finflow/controllers/app_update_controller.dart';
import 'package:finflow/controllers/financial_month_controller.dart';
import 'package:finflow/controllers/theme_controller.dart';
import 'package:finflow/features/auth/pages/auth_page.dart';
import 'package:finflow/features/settings/pages/settings_page.dart';
import 'package:finflow/models/app_update.dart';
import 'package:finflow/services/app_update_service.dart';
import 'package:finflow/shared/financial_month_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _FakeUpdateGateway implements AppUpdateGateway {
  @override
  Future<bool> isSupported() async => false;

  @override
  Future<InstalledAppVersion> getCurrentVersion() async =>
      const InstalledAppVersion(name: 'test', code: 1);

  @override
  Future<AppUpdateInfo?> fetchLatestRelease() async => null;

  @override
  Future<bool> canRequestPackageInstalls() async => false;

  @override
  Future<void> openInstallPermissionSettings() async {}

  @override
  Future<void> downloadAndInstall(AppUpdateInfo update) async {}
}

void main() {
  testWidgets('abre a autenticação diretamente em criar conta', (tester) async {
    final client = SupabaseClient(
      'https://example.supabase.co',
      'test-anon-key',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: AuthPage(
          client: client,
          initialCreateAccount: true,
        ),
      ),
    );

    expect(find.text('Criar conta FinFlow'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Criar conta'), findsOneWidget);
    expect(find.text('Já tenho uma conta'), findsOneWidget);

    await tester.tap(find.text('Já tenho uma conta'));
    await tester.pump();

    expect(find.text('Entrar no FinFlow'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Entrar'), findsOneWidget);
  });

  testWidgets('Conta pessoal oferece login e criação de outra conta', (
    tester,
  ) async {
    final controller = FinancialMonthController(MemoryFinancialMonthStore());
    await controller.initialize(now: DateTime(2026, 8, 24));
    addTearDown(controller.dispose);

    final themeController = ThemeController();
    addTearDown(themeController.dispose);

    final updateController = AppUpdateController(_FakeUpdateGateway());
    addTearDown(updateController.dispose);

    final client = SupabaseClient(
      'https://example.supabase.co',
      'test-anon-key',
    );

    var signInAnotherCalls = 0;
    var createAccountCalls = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: SettingsPage(
          controller: controller,
          appUpdateController: updateController,
          themeController: themeController,
          supabaseClient: client,
          onSignInAnotherAccount: () async {
            signInAnotherCalls++;
          },
          onCreateAccount: () async {
            createAccountCalls++;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Entrar em outra conta'), findsOneWidget);
    expect(find.text('Criar nova conta'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('account-sign-in-another')));
    await tester.pumpAndSettle();
    expect(find.text('Entrar em outra conta?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Continuar'));
    await tester.pumpAndSettle();
    expect(signInAnotherCalls, 1);

    await tester.tap(find.byKey(const ValueKey('account-create-new')));
    await tester.pumpAndSettle();
    expect(find.text('Criar nova conta?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Continuar'));
    await tester.pumpAndSettle();
    expect(createAccountCalls, 1);
  });
}
