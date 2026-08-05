import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/financial_entry.dart';
import '../models/financial_month.dart';
import '../services/sync_status_controller.dart';
import '../shared/financial_month_repository.dart';
import '../shared/initial_financial_data.dart';

class FinancialMonthController extends ChangeNotifier {
  FinancialMonthController(this._store) {
    _remoteSubscription = _store.changes.listen(_handleRemoteMonth);
  }

  static final DateTime firstMonth = DateTime(2026, 8);

  final FinancialMonthStore _store;
  late final StreamSubscription<FinancialMonth> _remoteSubscription;

  FinancialMonth? _currentMonth;
  bool _isLoading = false;
  bool _isDisposed = false;

  FinancialMonth get currentMonth {
    final month = _currentMonth;
    if (month == null) {
      throw StateError('O mês financeiro ainda não foi carregado.');
    }
    return month;
  }

  bool get isInitialized => _currentMonth != null;
  bool get isLoading => _isLoading;
  SyncStatusController? get syncStatus => _store.syncStatus;

  bool get canGoToPreviousMonth =>
      isInitialized && currentMonth.date.isAfter(firstMonth);

  Future<void> initialize({DateTime? now}) async {
    if (_isLoading || isInitialized) {
      return;
    }

    _setLoading(true);

    try {
      var initialMonth = await _store.load(
        firstMonth.year,
        firstMonth.month,
      );

      if (initialMonth == null) {
        initialMonth = buildInitialFinancialMonth();
        await _store.save(initialMonth);
      }

      final requestedDate = now ?? DateTime.now();
      final requestedMonth = DateTime(
        requestedDate.year,
        requestedDate.month,
      );
      final targetMonth = requestedMonth.isBefore(firstMonth)
          ? firstMonth
          : requestedMonth;

      var month = initialMonth;
      while (month.date.isBefore(targetMonth)) {
        final nextDate = DateTime(month.year, month.month + 1);
        final storedNextMonth = await _store.load(
          nextDate.year,
          nextDate.month,
        );
        month = storedNextMonth ?? month.createNextMonth();
        if (storedNextMonth == null) {
          await _store.save(month);
        }
      }

      _currentMonth = month;
      unawaited(_store.syncNow());
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> goToPreviousMonth() async {
    if (!canGoToPreviousMonth || _isLoading) {
      return false;
    }

    final previousDate = DateTime(
      currentMonth.year,
      currentMonth.month - 1,
    );
    final previousMonth = await _store.load(
      previousDate.year,
      previousDate.month,
    );

    if (previousMonth == null) {
      return false;
    }

    _currentMonth = previousMonth;
    notifyListeners();
    return true;
  }

  Future<void> goToNextMonth() async {
    if (_isLoading) {
      return;
    }

    final nextDate = DateTime(currentMonth.year, currentMonth.month + 1);
    final nextMonth =
        await _store.load(nextDate.year, nextDate.month) ??
        currentMonth.createNextMonth();

    await _store.save(nextMonth);
    _currentMonth = nextMonth;
    notifyListeners();
  }

  Future<void> updateEntry(FinancialEntry entry) async {
    _currentMonth = currentMonth.replaceEntry(entry);
    notifyListeners();
    await _store.save(currentMonth);
  }

  Future<void> addEntry({
    required String name,
    required int amountInCents,
    required FinancialEntryType type,
    bool isRecurring = false,
  }) async {
    final entry = FinancialEntry(
      id: 'custom-${DateTime.now().microsecondsSinceEpoch}',
      name: name,
      amountInCents: amountInCents,
      type: type,
      isRecurring: isRecurring,
    );

    _currentMonth = currentMonth.addEntry(entry);
    notifyListeners();
    await _store.save(currentMonth);
  }

  Future<void> removeEntry(String entryId) async {
    _currentMonth = currentMonth.removeEntry(entryId);
    notifyListeners();
    await _store.save(currentMonth);
  }

  Future<void> syncNow() => _store.syncNow();

  void _handleRemoteMonth(FinancialMonth month) {
    if (_isDisposed || !isInitialized) {
      return;
    }

    if (month.storageKey != currentMonth.storageKey ||
        month.clientUpdatedAt.isBefore(currentMonth.clientUpdatedAt)) {
      return;
    }

    _currentMonth = month;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    unawaited(_remoteSubscription.cancel());
    unawaited(_store.dispose());
    super.dispose();
  }
}
