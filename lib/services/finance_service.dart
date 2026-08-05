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

  static Map<DateTime, List<ScheduledInstallment>>
  installmentsGroupedByMonth(Iterable<PurchaseRecord> purchases) {
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
    final lastDay = DateTime(
      invoiceMonth.year,
      invoiceMonth.month + 1,
      0,
    ).day;

    return DateTime(
      invoiceMonth.year,
      invoiceMonth.month,
      dueDay.clamp(1, lastDay),
    );
  }

  static DateTime addMonths(DateTime date, int monthsToAdd) {
    final targetMonth = DateTime(date.year, date.month + monthsToAdd);
    final lastDay = DateTime(
      targetMonth.year,
      targetMonth.month + 1,
      0,
    ).day;

    return DateTime(
      targetMonth.year,
      targetMonth.month,
      date.day.clamp(1, lastDay),
    );
  }
}
