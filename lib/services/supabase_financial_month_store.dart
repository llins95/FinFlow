import 'dart:async';

import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/financial_month.dart';
import '../models/pix_settings.dart';
import '../shared/app_preferences.dart';
import '../shared/financial_month_repository.dart';
import 'sync_status_controller.dart';

class SupabaseFinancialMonthStore implements FinancialMonthStore {
  SupabaseFinancialMonthStore({
    required SupabaseClient client,
    required this.localStore,
  }) : _client = client,
       _userId =
           client.auth.currentUser?.id ??
           (throw StateError('É necessário entrar antes de sincronizar.')) {
    _channel = _client
        .channel('financial-months-$_userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'financial_months',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: _userId,
          ),
          callback: (payload) {
            if (payload.newRecord.isNotEmpty) {
              unawaited(
                _handleRealtimeRecord(
                  Map<String, dynamic>.from(payload.newRecord),
                ),
              );
            }
          },
        )
        .subscribe();

    if (_queueCount == 0) {
      _status.markSynced();
    } else {
      _status.markPending(_queueCount);
    }

    _retryTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => unawaited(syncNow()),
    );
  }

  static const String queueBoxName = 'financial_month_sync_queue';

  final SupabaseClient _client;
  final FinancialMonthStore localStore;
  final String _userId;
  final SyncStatusController _status = SyncStatusController();
  final StreamController<FinancialMonth> _changes =
      StreamController<FinancialMonth>.broadcast();

  late final RealtimeChannel _channel;
  Timer? _retryTimer;
  bool _isSyncing = false;
  bool _isDisposed = false;
  Future<void>? _prepareFuture;

  Box<dynamic> get _queue => Hive.box<dynamic>(queueBoxName);
  Iterable<String> get _queueKeys => _queue.keys
      .map((key) => key.toString())
      .where((key) => key.startsWith('$_userId/'));
  int get _queueCount => _queueKeys.length;

  @override
  Stream<FinancialMonth> get changes => _changes.stream;

  @override
  SyncStatusController get syncStatus => _status;

  @override
  Future<void> prepare() {
    return _prepareFuture ??= _prepareForCurrentUser();
  }

  Future<void> _prepareForCurrentUser() async {
    final hiveStore = localStore;
    if (hiveStore is HiveFinancialMonthStore) {
      await hiveStore.migrateLegacyData();
    }
    await _migrateLegacyQueue();

    try {
      final resetMonth = await _loadRemoteMonth(
        PixSettings.storageYear,
        PixSettings.storageMonth,
      );
      final remoteResetId = PixSettings.fromFinancialMonth(
        resetMonth,
      ).dataResetId;
      final localResetId = AppPreferences.loadDataResetId(_userId);

      if (remoteResetId != null && remoteResetId != localResetId) {
        await localStore.deleteAll();
        await _deleteQueuedMonths();
        if (resetMonth != null) {
          await localStore.save(resetMonth);
        }
        await AppPreferences.saveDataResetId(_userId, remoteResetId);
      }
    } catch (error) {
      if (!_isDisposed) {
        _status.markPending(_queueCount, error: error.toString());
      }
    }

    if (!_isDisposed) {
      unawaited(syncNow());
    }
  }

  Future<void> _migrateLegacyQueue() async {
    final legacyKeys = _queue.keys
        .map((key) => key.toString())
        .where((key) => RegExp(r'^\d{4}-\d{2}$').hasMatch(key))
        .toList();
    for (final key in legacyKeys) {
      final scopedKey = '$_userId/$key';
      if (!_queue.containsKey(scopedKey)) {
        await _queue.put(scopedKey, _queue.get(key));
      }
      await _queue.delete(key);
    }
  }

  @override
  Future<FinancialMonth?> load(int year, int month) async {
    await prepare();
    final localMonth = await localStore.load(year, month);

    try {
      final remoteMonth = await _loadRemoteMonth(year, month);

      if (remoteMonth == null) {
        if (localMonth != null) {
          await _queueMonth(localMonth);
        }
        return localMonth;
      }

      if (localMonth == null ||
          !remoteMonth.clientUpdatedAt.isBefore(localMonth.clientUpdatedAt)) {
        await localStore.save(remoteMonth);
        return remoteMonth;
      }

      await _queueMonth(localMonth);
      return localMonth;
    } catch (error) {
      if (!_isDisposed) {
        _status.markPending(_queueCount, error: error.toString());
      }
      return localMonth;
    }
  }

  @override
  Future<void> save(FinancialMonth month) async {
    await prepare();
    await localStore.save(month);
    await _queueMonth(month);
  }

  Future<void> _queueMonth(FinancialMonth month) async {
    if (_isDisposed) {
      return;
    }

    await _queue.put('$_userId/${month.storageKey}', month.toMap());
    _status.markPending(_queueCount);
    unawaited(syncNow());
  }

  @override
  Future<void> syncNow() async {
    await prepare();
    if (_isDisposed || _isSyncing) {
      return;
    }

    if (_client.auth.currentUser?.id != _userId) {
      _status.markError('A sessão atual não corresponde aos dados locais.');
      return;
    }

    if (_queueCount == 0) {
      _status.markSynced();
      return;
    }

    _isSyncing = true;
    _status.markSyncing(_queueCount);

    try {
      final keys = _queueKeys.toList();

      for (final key in keys) {
        if (_isDisposed) {
          return;
        }

        final rawMonth = _queue.get(key);
        if (rawMonth is! Map) {
          await _queue.delete(key);
          continue;
        }

        final month = FinancialMonth.fromMap(
          Map<dynamic, dynamic>.from(rawMonth),
        );

        final response = await _client.rpc(
          'upsert_financial_month',
          params: {
            'p_year': month.year,
            'p_month': month.month,
            'p_entries': month.entriesJson,
            'p_client_updated_at': month.clientUpdatedAt.toIso8601String(),
          },
        );

        if (_isDisposed) {
          return;
        }

        FinancialMonth? acceptedMonth;
        if (response is List && response.isNotEmpty && response.first is Map) {
          acceptedMonth = FinancialMonth.fromSupabaseRow(
            Map<String, dynamic>.from(response.first as Map),
          );
        } else {
          acceptedMonth = await _loadRemoteMonth(month.year, month.month);
        }

        if (acceptedMonth == null) {
          throw StateError(
            'O Supabase não confirmou o mês ${month.storageKey}.',
          );
        }

        await localStore.save(acceptedMonth);
        await _queue.delete(key);
        if (!_changes.isClosed) {
          _changes.add(acceptedMonth);
        }
      }

      if (!_isDisposed) {
        _status.markSynced();
      }
    } catch (error) {
      if (!_isDisposed) {
        _status.markPending(_queueCount, error: error.toString());
      }
    } finally {
      _isSyncing = false;
    }
  }

  Future<FinancialMonth?> _loadRemoteMonth(int year, int month) async {
    final row = await _client
        .from('financial_months')
        .select('year, month, entries, client_updated_at')
        .eq('user_id', _userId)
        .eq('year', year)
        .eq('month', month)
        .maybeSingle();

    if (row == null) {
      return null;
    }

    return FinancialMonth.fromSupabaseRow(Map<String, dynamic>.from(row));
  }

  Future<void> _handleRealtimeRecord(Map<String, dynamic> row) async {
    if (_isDisposed || row['user_id'] != _userId) {
      return;
    }

    final remoteMonth = FinancialMonth.fromSupabaseRow(row);
    if (remoteMonth.year == PixSettings.storageYear &&
        remoteMonth.month == PixSettings.storageMonth) {
      await _handleRemoteSettingsMonth(remoteMonth);
      return;
    }
    final rawPending = _queue.get('$_userId/${remoteMonth.storageKey}');

    if (rawPending is Map) {
      final pendingMonth = FinancialMonth.fromMap(
        Map<dynamic, dynamic>.from(rawPending),
      );
      if (pendingMonth.clientUpdatedAt.isAfter(remoteMonth.clientUpdatedAt)) {
        return;
      }
      await _queue.delete('$_userId/${remoteMonth.storageKey}');
    }

    final localMonth = await localStore.load(
      remoteMonth.year,
      remoteMonth.month,
    );
    if (_isDisposed ||
        (localMonth != null &&
            localMonth.clientUpdatedAt.isAfter(remoteMonth.clientUpdatedAt))) {
      return;
    }

    await localStore.save(remoteMonth);
    if (!_changes.isClosed) {
      _changes.add(remoteMonth);
    }

    if (!_isDisposed) {
      if (_queueCount == 0) {
        _status.markSynced();
      } else {
        _status.markPending(_queueCount);
      }
    }
  }

  Future<void> _handleRemoteSettingsMonth(FinancialMonth remoteMonth) async {
    final remoteResetId = PixSettings.fromFinancialMonth(
      remoteMonth,
    ).dataResetId;
    final localResetId = AppPreferences.loadDataResetId(_userId);
    if (remoteResetId != null && remoteResetId != localResetId) {
      await localStore.deleteAll();
      await _deleteQueuedMonths();
      await AppPreferences.saveDataResetId(_userId, remoteResetId);
    }
    await localStore.save(remoteMonth);
    if (!_changes.isClosed) {
      _changes.add(remoteMonth);
    }
    if (!_isDisposed) {
      _status.markSynced();
    }
  }

  @override
  Future<void> deleteAll() async {
    await prepare();
    if (_client.auth.currentUser?.id != _userId) {
      throw StateError('A sessão atual não corresponde aos dados locais.');
    }

    final resetId = const Uuid().v4();
    final resetMonth = PixSettings(dataResetId: resetId).toFinancialMonth();
    Object? response;
    try {
      response = await _client.rpc(
        'reset_finflow_data',
        params: {
          'p_entries': resetMonth.entriesJson,
          'p_client_updated_at': resetMonth.clientUpdatedAt.toIso8601String(),
        },
      );
    } on PostgrestException catch (error) {
      if (error.code != 'PGRST202') {
        rethrow;
      }
      response = await _legacyRemoteReset(resetMonth);
    }
    if (response is! List || response.isEmpty || response.first is! Map) {
      throw StateError('O Supabase não confirmou a exclusão dos dados.');
    }

    final acceptedReset = FinancialMonth.fromSupabaseRow(
      Map<String, dynamic>.from(response.first as Map),
    );
    await localStore.deleteAll();
    await _deleteQueuedMonths();
    await localStore.save(acceptedReset);
    await AppPreferences.saveDataResetId(_userId, resetId);
    if (!_changes.isClosed) {
      _changes.add(acceptedReset);
    }
    _status.markSynced();
  }

  Future<Object?> _legacyRemoteReset(FinancialMonth resetMonth) async {
    await _client.from('financial_months').delete().eq('user_id', _userId);
    return _client.rpc(
      'upsert_financial_month',
      params: {
        'p_year': resetMonth.year,
        'p_month': resetMonth.month,
        'p_entries': resetMonth.entriesJson,
        'p_client_updated_at': resetMonth.clientUpdatedAt.toIso8601String(),
      },
    );
  }

  Future<void> _deleteQueuedMonths() async {
    await _queue.deleteAll(_queueKeys.toList());
  }

  @override
  Future<void> dispose() async {
    if (_isDisposed) {
      return;
    }

    _isDisposed = true;
    _retryTimer?.cancel();
    await _client.removeChannel(_channel);
    await _changes.close();
  }
}
