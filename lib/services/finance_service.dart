import '../shared/mock_data.dart';
import '../shared/purchase_repository.dart';

class ScheduledInstallment {
  final String purchaseId;
  final String description;
  final String cardId;
  final int installmentNumber;
  final int totalInstallments;
  final int amountInCents;
  final DateTime dueDate;

  const ScheduledInstallment({
    required this.purchaseId,
    required this.description,
    required this.cardId,
    required this.installmentNumber,
    required this.totalInstallments,
    required this.amountInCents,
    required this.dueDate,
  });

  double get amount {
    return amountInCents / 100;
  }
}

class FinanceService {
  static double totalPurchases() {
    double total = 0;

    for (final purchase in PurchaseRepository.purchases) {
      total += purchase.amount;
    }

    return total;
  }

  static int totalPurchasesCount() {
    return PurchaseRepository.purchases.length;
  }

  static String mostUsedCard() {
    if (PurchaseRepository.purchases.isEmpty) {
      return 'Nenhum';
    }

    final Map<String, int> counter = {};

    for (final purchase in PurchaseRepository.purchases) {
      counter.update(purchase.cardId, (value) => value + 1, ifAbsent: () => 1);
    }

    String mostUsedCardId = counter.keys.first;
    int highestQuantity = counter.values.first;

    counter.forEach((cardId, quantity) {
      if (quantity > highestQuantity) {
        highestQuantity = quantity;
        mostUsedCardId = cardId;
      }
    });

    final matchingCards = mockCards.where((card) => card.id == mostUsedCardId);

    if (matchingCards.isEmpty) {
      return 'Cartão não encontrado';
    }

    return matchingCards.first.name;
  }

  static double estimatedMonthlyInstallments() {
    double total = 0;

    for (final purchase in PurchaseRepository.purchases) {
      final installmentCount = purchase.installments <= 0
          ? 1
          : purchase.installments;

      total += purchase.amount / installmentCount;
    }

    return total;
  }

  static List<ScheduledInstallment> scheduledInstallments() {
    final List<ScheduledInstallment> schedule = [];

    for (final purchase in PurchaseRepository.purchases) {
      final matchingCards = mockCards.where(
        (card) => card.id == purchase.cardId,
      );

      if (matchingCards.isEmpty) {
        continue;
      }

      final card = matchingCards.first;

      final totalInstallments = purchase.installments <= 0
          ? 1
          : purchase.installments;

      final firstInvoiceDate = card.invoiceForPurchase(purchase.purchaseDate);

      final totalAmountInCents = (purchase.amount * 100).round();
      final baseInstallmentAmount = totalAmountInCents ~/ totalInstallments;
      final remainder = totalAmountInCents % totalInstallments;

      for (int index = 0; index < totalInstallments; index++) {
        final installmentAmount = index < remainder
            ? baseInstallmentAmount + 1
            : baseInstallmentAmount;

        final dueDate = _addMonths(firstInvoiceDate, index);

        schedule.add(
          ScheduledInstallment(
            purchaseId: purchase.id,
            description: purchase.description,
            cardId: purchase.cardId,
            installmentNumber: index + 1,
            totalInstallments: totalInstallments,
            amountInCents: installmentAmount,
            dueDate: dueDate,
          ),
        );
      }
    }

    schedule.sort((first, second) => first.dueDate.compareTo(second.dueDate));

    return schedule;
  }

  static Map<DateTime, List<ScheduledInstallment>>
  installmentsGroupedByMonth() {
    final Map<DateTime, List<ScheduledInstallment>> grouped = {};

    for (final installment in scheduledInstallments()) {
      final monthKey = DateTime(
        installment.dueDate.year,
        installment.dueDate.month,
      );

      grouped.putIfAbsent(monthKey, () => []);

      grouped[monthKey]!.add(installment);
    }

    return grouped;
  }

  static double totalForMonth(DateTime month) {
    final installments =
        installmentsGroupedByMonth()[DateTime(month.year, month.month)];

    if (installments == null) {
      return 0;
    }

    int totalInCents = 0;

    for (final installment in installments) {
      totalInCents += installment.amountInCents;
    }

    return totalInCents / 100;
  }

  static DateTime _addMonths(DateTime date, int monthsToAdd) {
    final totalMonths = date.month - 1 + monthsToAdd;

    final newYear = date.year + totalMonths ~/ 12;
    final newMonth = totalMonths % 12 + 1;

    final lastDayOfNewMonth = DateTime(newYear, newMonth + 1, 0).day;

    final safeDay = date.day > lastDayOfNewMonth ? lastDayOfNewMonth : date.day;

    return DateTime(newYear, newMonth, safeDay);
  }
}
