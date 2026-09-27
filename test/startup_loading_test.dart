import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:finflow/app/app.dart';
import 'package:finflow/controllers/financial_month_controller.dart';
import 'package:finflow/models/financial_month.dart';
import 'package:finflow/models/pix_settings.dart';
import 'package:finflow/services/supabase_financial_month_store.dart';
import 'package:finflow/services/sync_status_controller.dart';
import 'package:finflow/shared/app_preferences.dart';
import 'package:finflow/shared/financial_month_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  late Directory directory;
  late SupabaseClient client;
  late HiveFinancialMonthStore local;
  SupabaseFinancialMonthStore? store;
  late Future<http.Response> Function(http.Request) respond;
  late int requests;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('finflow-startup-');
    Hive.init(directory.path);
    await Hive.openBox<dynamic>(HiveFinancialMonthStore.boxName);
    await Hive.openBox<dynamic>(SupabaseFinancialMonthStore.queueBoxName);
    await Hive.openBox<dynamic>(AppPreferences.boxName);
    local = HiveFinancialMonthStore(userId: 'user-a');
    requests = 0;
    respond = (_) async => http.Response('[]', 200);
    client = SupabaseClient(
      'https://example.supabase.co',
      'test-key',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
      httpClient: MockClient((request) {
        requests++;
        return respond(request);
      }),
    );
    final claims = base64Url
        .encode(utf8.encode(jsonEncode({'sub': 'user-a', 'exp': 4102444800})))
        .replaceAll('=', '');
    await client.auth.recoverSession(
      jsonEncode({
        'access_token': 'e30.$claims.signature',
        'refresh_token': 'test-refresh',
        'token_type': 'bearer',
        'expires_in': 3600,
        'expires_at': 4102444800,
        'user': {
          'id': 'user-a',
          'aud': 'authenticated',
          'app_metadata': <String, dynamic>{},
          'user_metadata': <String, dynamic>{},
          'created_at': '2026-08-01T00:00:00Z',
        },
      }),
    );
  });

  tearDown(() async {
    await store?.dispose();
    store = null;
    await client.dispose();
    await Hive.close();
    await directory.delete(recursive: true);
  });

  SupabaseFinancialMonthStore createStore() {
    return store = SupabaseFinancialMonthStore(
      client: client,
      localStore: local,
      requestTimeout: const Duration(milliseconds: 40),
      retryDelay: const Duration(milliseconds: 100),
    );
  }

  test(
    'servidor sem resposta abre os meses salvos sem repetir a espera',
    () async {
      respond = (_) => Completer<http.Response>().future;
      await local.save(FinancialMonth(year: 2026, month: 8, entries: const []));
      await local.save(FinancialMonth(year: 2026, month: 9, entries: const []));
      await local.save(const PixSettings().toFinancialMonth());
      final controller = FinancialMonthController(createStore());
      await controller
          .initialize(now: DateTime(2026, 9, 27))
          .timeout(const Duration(seconds: 2));
      expect(controller.currentMonth.month, 9);
      expect(requests, 1);
      expect(store!.syncStatus.phase, SyncPhase.pending);
      await store!.syncNow();
      expect(requests, 1);
      controller.dispose();
    },
  );

  test('falha sem cache não cria nem enfileira meses financeiros', () async {
    respond = (_) => Completer<http.Response>().future;
    final controller = FinancialMonthController(createStore());
    await expectLater(controller.initialize(), throwsStateError);
    expect(controller.isInitialized, isFalse);
    expect(controller.isLoading, isFalse);
    expect(Hive.box<dynamic>(HiveFinancialMonthStore.boxName).isEmpty, isTrue);
    expect(
      Hive.box<dynamic>(SupabaseFinancialMonthStore.queueBoxName).isEmpty,
      isTrue,
    );
    controller.dispose();
  });

  test('resposta atrasada depois do timeout não altera o cache', () async {
    final pending = Completer<http.Response>();
    respond = (_) => pending.future;
    final cached = FinancialMonth(year: 2026, month: 8, entries: const []);
    await local.save(cached);
    final result = await createStore().load(2026, 8);
    expect(result!.clientUpdatedAt, cached.clientUpdatedAt);
    final reset = const PixSettings(
      dataResetId: 'late-reset',
    ).toFinancialMonth();
    pending.complete(
      http.Response(
        jsonEncode([
          {
            'year': reset.year,
            'month': reset.month,
            'entries': reset.entriesJson,
            'client_updated_at': reset.clientUpdatedAt.toIso8601String(),
          },
        ]),
        200,
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(await local.load(2026, 8), isNotNull);
    expect(AppPreferences.loadDataResetId('user-a'), isNull);
  });

  test(
    'ausência confirmada pelo servidor continua permitindo criar o mês',
    () async {
      expect(await createStore().load(2026, 8), isNull);
    },
  );

  test('reconexão verifica exclusão remota antes de reenviar a fila', () async {
    respond = (_) => Completer<http.Response>().future;
    final cached = FinancialMonth(year: 2026, month: 8, entries: const []);
    await local.save(cached);
    await Hive.box<dynamic>(
      SupabaseFinancialMonthStore.queueBoxName,
    ).put('user-a/2026-08', cached.toMap());
    await createStore().prepare();
    final reset = const PixSettings(
      dataResetId: 'remote-reset',
    ).toFinancialMonth();
    var uploads = 0;
    respond = (request) async {
      if (request.url.path.contains('/rpc/')) uploads++;
      return http.Response(
        jsonEncode([
          {
            'year': reset.year,
            'month': reset.month,
            'entries': reset.entriesJson,
            'client_updated_at': reset.clientUpdatedAt.toIso8601String(),
          },
        ]),
        200,
      );
    };
    await Future<void>.delayed(const Duration(milliseconds: 120));
    await store!.syncNow();
    expect(uploads, 0);
    expect(await local.load(2026, 8), isNull);
    expect(AppPreferences.loadDataResetId('user-a'), 'remote-reset');
  });

  testWidgets('erro ao construir armazenamento sai da tela de carregamento', (
    tester,
  ) async {
    await Hive.box<dynamic>(SupabaseFinancialMonthStore.queueBoxName).close();
    await tester.pumpWidget(FinFlowApp(supabaseClient: client));
    await tester.pumpAndSettle();
    expect(find.text('Não foi possível iniciar'), findsOneWidget);
    expect(find.text('Tentar novamente'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    await tester.tap(find.text('Tentar novamente'));
    await tester.pumpAndSettle();
    expect(find.text('Não foi possível iniciar'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
