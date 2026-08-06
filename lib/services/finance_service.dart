import '../models/financial_entry.dart';
import '../models/purchase_record.dart';

class ScheduledInstallment {
  const ScheduledInstallment({
    required this.purchaseId,
    required this.description,
    required this.cardId,
    required this.cardName,
    required this.cardColor,
    required this.installmentNumber,
    required this.totalInstallments,
    required this.amountInCents,
    required this.dueDate,
  });

  final String purchaseId;
  final String description;
  final String cardId;
  final String cardName;
  final int cardColor;
  final int installmentNumber;
  final int totalInstallments;
  final int amountInCents;
  final DateTime dueDate;

  double get amount => amountInCents / 100;
}

class PurchaseSearchResult {
  const PurchaseSearchResult({
    required this.record,
    required this.installments,
    required this.matchingInstallmentNumbers,
  });

  final PurchaseRecord record;
  final List<ScheduledInstallment> installments;
  final Set<int> matchingInstallmentNumbers;

  bool get matchedByMonth => matchingInstallmentNumbers.isNotEmpty;

  bool installmentMatches(ScheduledInstallment installment) {
    return matchingInstallmentNumbers.contains(installment.installmentNumber);
  }
}

class FinanceService {
  static List<ScheduledInstallment> scheduledInstallments(
    Iterable<PurchaseRecord> purchases,
  ) {
    final schedule = <ScheduledInstallment>[];

    for (final record in purchases) {
      final purchase = record.entry;
      if (purchase.type != FinancialEntryType.purchase) {
        continue;
      }

      final installmentCount = (purchase.installments ?? 1).clamp(1, 99);
      final firstInvoiceDate = firstInvoiceDateFor(purchase);
      final baseAmount = purchase.amountInCents ~/ installmentCount;
      final remainder = purchase.amountInCents % installmentCount;

      for (var index = 0; index < installmentCount; index++) {
        schedule.add(
          ScheduledInstallment(
            purchaseId: purchase.id,
            description: purchase.name,
            cardId: purchase.relatedCardId ?? '',
            cardName: purchase.relatedCardName ?? 'Cartão não encontrado',
            cardColor: purchase.cardColor ?? 0xFF455A64,
            installmentNumber: index + 1,
            totalInstallments: installmentCount,
            amountInCents: baseAmount + (index < remainder ? 1 : 0),
            dueDate: addMonths(firstInvoiceDate, index),
          ),
        );
      }
    }

    schedule.sort((first, second) => first.dueDate.compareTo(second.dueDate));
    return schedule;
  }

  static List<PurchaseSearchResult> searchPurchases(
    Iterable<PurchaseRecord> purchases,
    String query,
  ) {
    final normalizedQuery = _normalizeSearchText(query);
    if (normalizedQuery.isEmpty) {
      return const [];
    }

    final results = <PurchaseSearchResult>[];

    for (final record in purchases) {
      final purchase = record.entry;
      final installments = scheduledInstallments([record]);
      final searchablePurchase = _normalizeSearchText(
        '${purchase.name} ${purchase.relatedCardName ?? ''}',
      );
      final matchesPurchase = searchablePurchase.contains(normalizedQuery);
      final matchingNumbers = <int>{
        for (final installment in installments)
          if (_monthMatches(installment.dueDate, normalizedQuery))
            installment.installmentNumber,
      };

      if (matchesPurchase || matchingNumbers.isNotEmpty) {
        results.add(
          PurchaseSearchResult(
            record: record,
            installments: List.unmodifiable(installments),
            matchingInstallmentNumbers: Set.unmodifiable(matchingNumbers),
          ),
        );
      }
    }

    results.sort(
      (first, second) =>
          second.record.purchaseDate.compareTo(first.record.purchaseDate),
    );
    return List.unmodifiable(results);
  }

  static Map<DateTime, List<ScheduledInstallment>> installmentsGroupedByMonth(
    Iterable<PurchaseRecord> purchases,
  ) {
    final grouped = <DateTime, List<ScheduledInstallment>>{};

    for (final installment in scheduledInstallments(purchases)) {
      final monthKey = DateTime(
        installment.dueDate.year,
        installment.dueDate.month,
      );
      grouped.putIfAbsent(monthKey, () => []).add(installment);
    }

    return grouped;
  }

  static int totalForMonthInCents(
    DateTime month,
    Iterable<PurchaseRecord> purchases,
  ) {
    final installments = installmentsGroupedByMonth(
      purchases,
    )[DateTime(month.year, month.month)];

    return installments?.fold<int>(
          0,
          (total, installment) => total + installment.amountInCents,
        ) ??
        0;
  }

  static int totalForCardInMonthInCents(
    DateTime month,
    String cardId,
    Iterable<PurchaseRecord> purchases,
  ) {
    final monthKey = DateTime(month.year, month.month);
    final installments = installmentsGroupedByMonth(purchases)[monthKey];

    return installments?.fold<int>(
          0,
          (total, installment) => installment.cardId == cardId
              ? total + installment.amountInCents
              : total,
        ) ??
        0;
  }

  static DateTime firstInvoiceDateFor(FinancialEntry purchase) {
    final purchaseDate = purchase.purchaseDate;
    if (purchaseDate == null) {
      throw ArgumentError('A compra não possui data.');
    }

    final closingDay = (purchase.closingDay ?? 1).clamp(1, 31);
    final dueDay = (purchase.dueDay ?? 1).clamp(1, 31);
    final invoiceMonth = purchaseDate.day > closingDay
        ? DateTime(purchaseDate.year, purchaseDate.month + 1)
        : DateTime(purchaseDate.year, purchaseDate.month);
    final lastDay = DateTime(invoiceMonth.year, invoiceMonth.month + 1, 0).day;

    return DateTime(
      invoiceMonth.year,
      invoiceMonth.month,
      dueDay.clamp(1, lastDay),
    );
  }

  static DateTime addMonths(DateTime date, int monthsToAdd) {
    final targetMonth = DateTime(date.year, date.month + monthsToAdd);
    final lastDay = DateTime(targetMonth.year, targetMonth.month + 1, 0).day;

    return DateTime(
      targetMonth.year,
      targetMonth.month,
      date.day.clamp(1, lastDay),
    );
  }

  static bool _monthMatches(DateTime date, String normalizedQuery) {
    const monthNames = <String>[
      '',
      'janeiro',
      'fevereiro',
      'marco',
      'abril',
      'maio',
      'junho',
      'julho',
      'agosto',
      'setembro',
      'outubro',
      'novembro',
      'dezembro',
    ];
    final month = date.month.toString();
    final paddedMonth = month.padLeft(2, '0');
    final year = date.year.toString();
    final shortYear = year.substring(2);
    final monthName = monthNames[date.month];
    final candidates = <String>{
      monthName,
      '$monthName $year',
      '$monthName $shortYear',
      '$month/$year',
      '$paddedMonth/$year',
      '$month/$shortYear',
      '$paddedMonth/$shortYear',
      '$month-$year',
      '$paddedMonth-$year',
      '$year-$paddedMonth',
    };

    return candidates.contains(normalizedQuery) ||
        (normalizedQuery.length >= 3 && monthName.startsWith(normalizedQuery));
  }

  static String _normalizeSearchText(String value) {
    const accents = 'áàâãäéèêëíìîïóòôõöúùûüç';
    const replacements = 'aaaaaeeeeiiiiooooouuuuc';
    final buffer = StringBuffer();

    for (final rune in value.toLowerCase().runes) {
      final character = String.fromCharCode(rune);
      final index = accents.indexOf(character);
      buffer.write(index >= 0 ? replacements[index] : character);
    }

    return buffer.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}
