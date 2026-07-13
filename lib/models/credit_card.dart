class CreditCard {
  final String id;
  final String name;
  final String bank;
  final String brand;
  final double limit;
  final int closingDay;
  final int dueDay;
  final int color;
  final bool isActive;

  const CreditCard({
    required this.id,
    required this.name,
    required this.bank,
    required this.brand,
    required this.limit,
    required this.closingDay,
    required this.dueDay,
    required this.color,
    this.isActive = true,
  });

  int get bestPurchaseDay {
    if (closingDay == 31) {
      return 1;
    }

    return closingDay + 1;
  }

  DateTime nextInvoiceDate() {
    return invoiceForPurchase(DateTime.now());
  }

  int daysUntilInvoice() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final invoiceDate = nextInvoiceDate();

    return invoiceDate.difference(today).inDays;
  }

  bool purchaseGoesToNextInvoice() {
    final now = DateTime.now();

    return now.day > closingDay;
  }

  String purchaseAdvice() {
    if (purchaseGoesToNextInvoice()) {
      return 'Compra cairá apenas na próxima fatura.';
    }

    return 'Compra cairá na fatura atual.';
  }

  DateTime invoiceForPurchase(DateTime purchaseDate) {
    var month = purchaseDate.month;
    var year = purchaseDate.year;

    if (purchaseDate.day > closingDay) {
      month++;

      if (month > 12) {
        month = 1;
        year++;
      }
    }

    return DateTime(year, month, dueDay);
  }

  int daysToPay(DateTime purchaseDate) {
    final purchaseDay = DateTime(
      purchaseDate.year,
      purchaseDate.month,
      purchaseDate.day,
    );

    final invoiceDate = invoiceForPurchase(purchaseDay);

    return invoiceDate.difference(purchaseDay).inDays;
  }
}
