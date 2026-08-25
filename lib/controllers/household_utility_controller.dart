import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/household_utility_expense.dart';
import '../shared/household_utility_repository.dart';

class HouseholdUtilityController extends ChangeNotifier {
  HouseholdUtilityController(
    this.store, {
    int? initialYear,
  }) : selectedYear = initialYear ?? DateTime.now().year;

  final HouseholdUtilityStore store;

  int selectedYear;
  bool isLoading = true;
  String? errorMessage;

  final Map<String, HouseholdUtilityExpense> _records = {};

  List<HouseholdUtilityExpense> get records =>
      List.unmodifiable(_records.values);

  Future<void> initialize() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await store.prepare();
      await _reloadLocal();
      await store.syncNow();
      await _reloadLocal();
    } catch (error) {
      errorMessage = error.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  int amountFor(int month, HouseholdUtilityKind kind) {
    return _records[_key(selectedYear, month)]?.amountFor(kind) ?? 0;
  }

  Future<void> setAmount(
    int month,
    HouseholdUtilityKind kind,
    int amountInCents,
  ) async {
    final normalized = amountInCents < 0 ? 0 : amountInCents;
    final key = _key(selectedYear, month);
    final current = _records[key] ??
        HouseholdUtilityExpense(year: selectedYear, month: month);
    final updated = current.withAmount(kind, normalized);

    _records[key] = updated;
    errorMessage = null;
    notifyListeners();

    try {
      await store.save(updated);
    } catch (error) {
      errorMessage = error.toString();
      notifyListeners();
      rethrow;
    }
  }

  void goToPreviousYear() {
    if (selectedYear <= 2000) {
      return;
    }
    selectedYear -= 1;
    notifyListeners();
  }

  void goToNextYear() {
    if (selectedYear >= 2100) {
      return;
    }
    selectedYear += 1;
    notifyListeners();
  }

  Future<void> refresh() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      await store.syncNow();
      await _reloadLocal();
    } catch (error) {
      errorMessage = error.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _reloadLocal() async {
    final loaded = await store.loadAll();
    _records
      ..clear()
      ..addEntries(loaded.map((record) => MapEntry(record.storageKey, record)));
  }

  String _key(int year, int month) {
    return '$year-${month.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    unawaited(store.dispose());
    super.dispose();
  }
}
