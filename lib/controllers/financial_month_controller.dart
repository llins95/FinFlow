import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/financial_entry.dart';
import '../models/financial_month.dart';
import '../models/purchase.dart';
import '../models/purchase_record.dart';
import '../services/finance_service.dart';
import '../services/sync_status_controller.dart';
import '../shared/financial_month_repository.dart';
import '../shared/initial_financial_data.dart';
import '../utils/card_mapper.dart';

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

  List<PurchaseRecord> get purchaseRecords {
    final records = <PurchaseRecord>[
      for (final month in _loadedMonths.values)
        for (final entry in month.purchases)
          PurchaseRecord(month: month, entry: entry),
    ]..sort((a, b) => b.purchaseDate.compareTo(a.purchaseDate));

    return List.unmodifiable(records);
  }

  int purchaseInstallmentsForCardInMonth(
    FinancialEntry cardInvoice,
    DateTime month,
  ) {
    return FinanceService.totalForCardInMonthInCents(
      month,
      cardInvoice.relatedCardId ?? cardInvoice.id,
      purchaseRecords,
    );
  }

  int cardInvoiceTotalInCents(FinancialEntry cardInvoice) {
    return cardInvoice.amountInCents +
        purchaseInstallmentsForCardInMonth(cardInvoice, currentMonth.date);
  }

  int get currentTotalDebtInCents {
    final regularExpenses = currentMonth
        .entriesOfType(FinancialEntryType.expense)
        .fold<int>(0, (total, entry) => total + entry.amountInCents);
    final cardInvoices = currentMonth
        .entriesOfType(FinancialEntryType.cardInvoice)
        .fold<int>(0, (total, entry) => total + cardInvoiceTotalInCents(entry));

    return regularExpenses + cardInvoices;
  }

  int get currentBalanceInCents =>
      currentMonth.totalAvailableInCents - currentTotalDebtInCents;

  List<FinancialEntry> get activeCardInvoices {
    final cards =
        currentMonth
            .entriesOfType(FinancialEntryType.cardInvoice)
            .where((entry) => entry.isActive)
            .toList()
          ..sort((a, b) => (a.closingDay ?? 32).compareTo(b.closingDay ?? 32));
    return List.unmodifiable(cards);
  }

  List<FinancialEntry> get purchaseCardOptions {
    final cardsById = <String, FinancialEntry>{};

    for (final month in availableMonths) {
      for (final entry in month.entriesOfType(FinancialEntryType.cardInvoice)) {
        final cardId = entry.relatedCardId ?? entry.id;
        cardsById.putIfAbsent(cardId, () => entry);
      }
    }

    final cards = cardsById.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    return List.unmodifiable(cards);
  }

  bool get canGoToPreviousMonth =>
      isInitialized && currentMonth.date.isAfter(firstMonth);

  Future<void> initialize({DateTime? now}) async {
    if (_isLoading || isInitialized) {
      return;
    }

    _setLoading(true);

    try {
      var initialMonth = await _store.load(firstMonth.year, firstMonth.month);

      if (initialMonth == null) {
        initialMonth = buildInitialFinancialMonth();
        await _store.save(initialMonth);
      }
      _rememberMonth(initialMonth);

      final requestedDate = now ?? DateTime.now();
      final requestedMonth = DateTime(requestedDate.year, requestedDate.month);
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

    final previousDate = DateTime(currentMonth.year, currentMonth.month - 1);
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

  Future<void> addPurchase({
    required String description,
    required int amountInCents,
    required int installments,
    required DateTime purchaseDate,
    required FinancialEntry cardInvoice,
    String? sourceReference,
  }) async {
    if (sourceReference != null &&
        purchaseRecords.any(
          (record) => record.entry.sourceReference == sourceReference,
        )) {
      return;
    }

    final targetMonth = await _loadOrCreateMonth(purchaseDate);
    final purchase = _buildPurchaseEntry(
      id: 'purchase-${const Uuid().v4()}',
      description: description,
      amountInCents: amountInCents,
      installments: installments,
      purchaseDate: purchaseDate,
      cardInvoice: cardInvoice,
      sourceReference: sourceReference,
    );

    await _saveMonth(targetMonth.addEntry(purchase));
  }

  Future<void> updatePurchase({
    required PurchaseRecord record,
    required String description,
    required int amountInCents,
    required int installments,
    required DateTime purchaseDate,
    required FinancialEntry cardInvoice,
  }) async {
    final sourceMonth = await _loadMonth(record.month.year, record.month.month);
    if (sourceMonth == null) {
      throw StateError('O mês original da compra não foi encontrado.');
    }

    final updatedPurchase = _buildPurchaseEntry(
      id: record.entry.id,
      description: description,
      amountInCents: amountInCents,
      installments: installments,
      purchaseDate: purchaseDate,
      cardInvoice: cardInvoice,
      sourceReference: record.entry.sourceReference,
    );
    final targetMonth = await _loadOrCreateMonth(purchaseDate);

    if (sourceMonth.storageKey == targetMonth.storageKey) {
      await _saveMonth(sourceMonth.replaceEntry(updatedPurchase));
      return;
    }

    await _saveMonth(sourceMonth.removeEntry(record.entry.id));
    await _saveMonth(targetMonth.addEntry(updatedPurchase));
  }

  Future<void> removePurchase(PurchaseRecord record) async {
    final month = await _loadMonth(record.month.year, record.month.month);
    if (month == null) {
      return;
    }
    await _saveMonth(month.removeEntry(record.entry.id));
  }

  Future<int> importLegacyPurchases(Iterable<Purchase> purchases) async {
    var processedCount = 0;

    for (final legacyPurchase in purchases) {
      final purchaseDate = DateTime(
        legacyPurchase.purchaseDate.year,
        legacyPurchase.purchaseDate.month,
        legacyPurchase.purchaseDate.day,
      );
      if (purchaseDate.isBefore(firstMonth)) {
        processedCount++;
        continue;
      }

      final targetMonth = await _loadOrCreateMonth(purchaseDate);
      final entryId = legacyPurchase.id.startsWith('purchase-')
          ? legacyPurchase.id
          : 'purchase-${legacyPurchase.id}';
      if (targetMonth.entries.any((entry) => entry.id == entryId)) {
        processedCount++;
        continue;
      }

      final cardInvoice = _findCardInvoice(
        legacyPurchase.cardId,
        preferredMonth: targetMonth,
      );
      if (cardInvoice == null) {
        continue;
      }

      final purchase = _buildPurchaseEntry(
        id: entryId,
        description: legacyPurchase.description,
        amountInCents: (legacyPurchase.amount * 100).round(),
        installments: legacyPurchase.installments,
        purchaseDate: purchaseDate,
        cardInvoice: cardInvoice,
      );
      await _saveMonth(targetMonth.addEntry(purchase));
      processedCount++;
    }

    return processedCount;
  }

  Future<void> removeEntry(String entryId) async {
    _currentMonth = currentMonth.removeEntry(entryId);
    _rememberMonth(currentMonth);
    notifyListeners();
    await _store.save(currentMonth);
  }

  Future<void> syncNow() => _store.syncNow();

  FinancialEntry _buildPurchaseEntry({
    required String id,
    required String description,
    required int amountInCents,
    required int installments,
    required DateTime purchaseDate,
    required FinancialEntry cardInvoice,
    String? sourceReference,
  }) {
    final card = creditCardFromInvoice(cardInvoice);

    return FinancialEntry(
      id: id,
      name: description.trim(),
      amountInCents: amountInCents,
      type: FinancialEntryType.purchase,
      relatedCardId: card.id,
      relatedCardName: card.name,
      cardColor: card.color,
      closingDay: card.closingDay,
      dueDay: card.dueDay,
      purchaseDate: DateTime(
        purchaseDate.year,
        purchaseDate.month,
        purchaseDate.day,
      ),
      installments: installments.clamp(1, 99),
      sourceReference: sourceReference,
    );
  }

  FinancialEntry? _findCardInvoice(
    String cardId, {
    FinancialMonth? preferredMonth,
  }) {
    final preferredCards = preferredMonth?.entriesOfType(
      FinancialEntryType.cardInvoice,
    );
    if (preferredCards != null) {
      for (final card in preferredCards) {
        if ((card.relatedCardId ?? card.id) == cardId) {
          return card;
        }
      }
    }

    for (final card in purchaseCardOptions) {
      if ((card.relatedCardId ?? card.id) == cardId) {
        return card;
      }
    }
    return null;
  }

  Future<FinancialMonth?> _loadMonth(int year, int month) async {
    final key = '$year-${month.toString().padLeft(2, '0')}';
    final remembered = _loadedMonths[key];
    if (remembered != null) {
      return remembered;
    }

    final stored = await _store.load(year, month);
    if (stored != null) {
      _rememberMonth(stored);
    }
    return stored;
  }

  Future<FinancialMonth> _loadOrCreateMonth(DateTime date) async {
    final targetDate = DateTime(date.year, date.month);
    if (targetDate.isBefore(firstMonth)) {
      throw ArgumentError('O FinFlow começa em agosto de 2026.');
    }

    var month =
        await _loadMonth(firstMonth.year, firstMonth.month) ??
        buildInitialFinancialMonth();
    _rememberMonth(month);

    while (month.date.isBefore(targetDate)) {
      final nextDate = DateTime(month.year, month.month + 1);
      final storedNextMonth = await _loadMonth(nextDate.year, nextDate.month);
      if (storedNextMonth != null) {
        month = storedNextMonth;
        continue;
      }

      month = month.createNextMonth();
      await _store.save(month);
      _rememberMonth(month);
    }

    return month;
  }

  Future<void> _saveMonth(FinancialMonth month) async {
    _rememberMonth(month);
    if (isInitialized && currentMonth.storageKey == month.storageKey) {
      _currentMonth = month;
    }
    notifyListeners();
    await _store.save(month);
  }

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
