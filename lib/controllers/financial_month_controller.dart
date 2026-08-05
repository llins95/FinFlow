import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

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
  final Map<String, FinancialMonth> _loadedMonths = {};

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

  List<FinancialMonth> get availableMonths {
    final months = _loadedMonths.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return List.unmodifiable(months);
  }

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
      _rememberMonth(initialMonth);

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
        _rememberMonth(month);
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
    _rememberMonth(previousMonth);
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
    _rememberMonth(nextMonth);
    notifyListeners();
  }

  Future<bool> goToMonth(int year, int month) async {
    if (_isLoading) {
      return false;
    }

    final selectedMonth = await _store.load(year, month);
    if (selectedMonth == null) {
      return false;
    }

    _currentMonth = selectedMonth;
    _rememberMonth(selectedMonth);
    notifyListeners();
    return true;
  }

  Future<void> updateEntry(FinancialEntry entry) async {
    _currentMonth = currentMonth.replaceEntry(entry);
    _rememberMonth(currentMonth);
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
    _rememberMonth(currentMonth);
    notifyListeners();
    await _store.save(currentMonth);
  }

  Future<void> addCardInvoice({
    required String name,
    required String bank,
    required String brand,
    required int limitInCents,
    required int closingDay,
    required int dueDay,
    required int color,
    bool isActive = true,
  }) async {
    final cardId = const Uuid().v4();
    final entry = FinancialEntry(
      id: 'card-$cardId',
      name: name,
      amountInCents: 0,
      type: FinancialEntryType.cardInvoice,
      isRecurring: true,
      isActive: isActive,
      relatedCardId: cardId,
      cardBank: bank,
      cardBrand: brand,
      cardLimitInCents: limitInCents,
      cardColor: color,
      closingDay: closingDay,
      dueDay: dueDay,
    );

    _currentMonth = currentMonth.addEntry(entry);
    _rememberMonth(currentMonth);
    notifyListeners();
    await _store.save(currentMonth);
  }

  Future<void> removeEntry(String entryId) async {
    _currentMonth = currentMonth.removeEntry(entryId);
    _rememberMonth(currentMonth);
    notifyListeners();
    await _store.save(currentMonth);
  }

  Future<void> syncNow() => _store.syncNow();

  void _handleRemoteMonth(FinancialMonth month) {
    if (_isDisposed) {
      return;
    }

    final loadedMonth = _loadedMonths[month.storageKey];
    if (loadedMonth != null &&
        month.clientUpdatedAt.isBefore(loadedMonth.clientUpdatedAt)) {
      return;
    }

    _rememberMonth(month);

    if (isInitialized &&
        month.storageKey == currentMonth.storageKey &&
        !month.clientUpdatedAt.isBefore(currentMonth.clientUpdatedAt)) {
      _currentMonth = month;
    }

    notifyListeners();
  }

  void _rememberMonth(FinancialMonth month) {
    _loadedMonths[month.storageKey] = month;
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
