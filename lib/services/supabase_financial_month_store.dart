import 'dart:async';

import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/financial_month.dart';
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

    if (_queue.isEmpty) {
      _status.markSynced();
    } else {
      _status.markPending(_queue.length);
    }

    _retryTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => unawaited(syncNow()),
    );
    unawaited(syncNow());
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

  Box<dynamic> get _queue => Hive.box<dynamic>(queueBoxName);

  @override
  Stream<FinancialMonth> get changes => _changes.stream;

  @override
  SyncStatusController get syncStatus => _status;

  @override
  Future<FinancialMonth?> load(int year, int month) async {
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
          !remoteMonth.clientUpdatedAt.isBefore(
            localMonth.clientUpdatedAt,
          )) {
        await localStore.save(remoteMonth);
        return remoteMonth;
      }

      await _queueMonth(localMonth);
      return localMonth;
    } catch (error) {
      if (!_isDisposed) {
        _status.markPending(
          _queue.length,
          error: error.toString(),
        );
      }
      return localMonth;
    }
  }

  @override
  Future<void> save(FinancialMonth month) async {
    await localStore.save(month);
    await _queueMonth(month);
  }

  Future<void> _queueMonth(FinancialMonth month) async {
    if (_isDisposed) {
      return;
    }

    await _queue.put(month.storageKey, month.toMap());
    _status.markPending(_queue.length);
    unawaited(syncNow());
  }

  @override
  Future<void> syncNow() async {
    if (_isDisposed || _isSyncing) {
      return;
    }

    if (_client.auth.currentUser?.id != _userId) {
      _status.markError('A sessão atual não corresponde aos dados locais.');
      return;
    }

    if (_queue.isEmpty) {
      _status.markSynced();
      return;
    }

    _isSyncing = true;
    _status.markSyncing(_queue.length);

    try {
      final keys = _queue.keys.map((key) => key.toString()).toList();

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
            'p_client_updated_at':
                month.clientUpdatedAt.toIso8601String(),
          },
        );

        if (_isDisposed) {
          return;
        }

        FinancialMonth? acceptedMonth;
        if (response is List &&
            response.isNotEmpty &&
            response.first is Map) {
          acceptedMonth = FinancialMonth.fromSupabaseRow(
            Map<String, dynamic>.from(response.first as Map),
          );
        } else {
          acceptedMonth = await _loadRemoteMonth(
            month.year,
            month.month,
          );
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
        _status.markPending(
          _queue.length,
          error: error.toString(),
        );
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

    return FinancialMonth.fromSupabaseRow(
      Map<String, dynamic>.from(row),
    );
  }

  Future<void> _handleRealtimeRecord(
    Map<String, dynamic> row,
  ) async {
    if (_isDisposed || row['user_id'] != _userId) {
      return;
    }

    final remoteMonth = FinancialMonth.fromSupabaseRow(row);
    final rawPending = _queue.get(remoteMonth.storageKey);

    if (rawPending is Map) {
      final pendingMonth = FinancialMonth.fromMap(
        Map<dynamic, dynamic>.from(rawPending),
      );
      if (pendingMonth.clientUpdatedAt.isAfter(
        remoteMonth.clientUpdatedAt,
      )) {
        return;
      }
      await _queue.delete(remoteMonth.storageKey);
    }

    final localMonth = await localStore.load(
      remoteMonth.year,
      remoteMonth.month,
    );
    if (_isDisposed ||
        (localMonth != null &&
            localMonth.clientUpdatedAt.isAfter(
              remoteMonth.clientUpdatedAt,
            ))) {
      return;
    }

    await localStore.save(remoteMonth);
    if (!_changes.isClosed) {
      _changes.add(remoteMonth);
    }

    if (!_isDisposed) {
      if (_queue.isEmpty) {
        _status.markSynced();
      } else {
        _status.markPending(_queue.length);
      }
    }
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
