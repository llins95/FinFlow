import 'dart:async';

import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/household_utility_expense.dart';
import '../shared/household_utility_repository.dart';

class SupabaseHouseholdUtilityStore implements HouseholdUtilityStore {
  SupabaseHouseholdUtilityStore({
    required SupabaseClient client,
    required this.localStore,
  }) : _client = client,
       _userId =
           client.auth.currentUser?.id ??
           (throw StateError('É necessário entrar antes de sincronizar.'));

  static const String queueBoxName = 'household_utility_sync_queue';

  final SupabaseClient _client;
  final HouseholdUtilityStore localStore;
  final String _userId;

  Box<dynamic>? _queue;
  Future<void>? _prepareFuture;
  bool _isSyncing = false;
  String? _lastSyncError;

  String? get lastSyncError => _lastSyncError;

  @override
  Future<void> prepare() {
    return _prepareFuture ??= _prepareForCurrentUser();
  }

  Future<void> _prepareForCurrentUser() async {
    await localStore.prepare();
    _queue = Hive.isBoxOpen(queueBoxName)
        ? Hive.box<dynamic>(queueBoxName)
        : await Hive.openBox<dynamic>(queueBoxName);

    try {
      await _mergeRemoteIntoLocal();
      _lastSyncError = null;
    } catch (error) {
      _lastSyncError = error.toString();
    }
  }

  @override
  Future<List<HouseholdUtilityExpense>> loadAll() async {
    await prepare();
    return localStore.loadAll();
  }

  @override
  Future<void> save(HouseholdUtilityExpense expense) async {
    await prepare();
    await localStore.save(expense);
    await _queueExpense(expense);
    unawaited(syncNow());
  }

  Future<void> _queueExpense(HouseholdUtilityExpense expense) async {
    await _queue!.put('$_userId/${expense.storageKey}', expense.toMap());
  }

  Iterable<String> get _queueKeys => _queue!.keys
      .map((key) => key.toString())
      .where((key) => key.startsWith('$_userId/'));

  @override
  Future<void> syncNow() async {
    await prepare();
    if (_isSyncing || _client.auth.currentUser?.id != _userId) {
      return;
    }

    _isSyncing = true;
    try {
      final keys = _queueKeys.toList();
      for (final key in keys) {
        final raw = _queue!.get(key);
        if (raw is! Map) {
          await _queue!.delete(key);
          continue;
        }

        final expense = HouseholdUtilityExpense.fromMap(
          Map<dynamic, dynamic>.from(raw),
        );
        final response = await _client.rpc(
          'upsert_household_utility_expense',
          params: {
            'p_year': expense.year,
            'p_month': expense.month,
            'p_water_in_cents': expense.waterInCents,
            'p_electricity_in_cents': expense.electricityInCents,
            'p_client_updated_at': expense.clientUpdatedAt.toIso8601String(),
          },
        );

        HouseholdUtilityExpense accepted = expense;
        if (response is List && response.isNotEmpty && response.first is Map) {
          accepted = HouseholdUtilityExpense.fromSupabaseRow(
            Map<String, dynamic>.from(response.first as Map),
          );
        }
        await localStore.save(accepted);
        await _queue!.delete(key);
      }
      _lastSyncError = null;
    } catch (error) {
      _lastSyncError = error.toString();
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _mergeRemoteIntoLocal() async {
    final localRecords = await localStore.loadAll();
    final localByKey = {
      for (final expense in localRecords) expense.storageKey: expense,
    };

    final rows = await _client
        .from('household_utility_expenses')
        .select(
          'year, month, water_in_cents, electricity_in_cents, client_updated_at',
        )
        .eq('user_id', _userId);

    final remoteKeys = <String>{};
    for (final rawRow in rows) {
      final remote = HouseholdUtilityExpense.fromSupabaseRow(
        Map<String, dynamic>.from(rawRow),
      );
      remoteKeys.add(remote.storageKey);
      final local = localByKey[remote.storageKey];

      if (local == null ||
          !remote.clientUpdatedAt.isBefore(local.clientUpdatedAt)) {
        await localStore.save(remote);
      } else {
        await _queueExpense(local);
      }
    }

    for (final local in localRecords) {
      if (!remoteKeys.contains(local.storageKey)) {
        await _queueExpense(local);
      }
    }
  }

  @override
  Future<void> deleteAll() async {
    await prepare();
    await _client
        .from('household_utility_expenses')
        .delete()
        .eq('user_id', _userId);
    await localStore.deleteAll();
    await _queue!.deleteAll(_queueKeys.toList());
  }
}
