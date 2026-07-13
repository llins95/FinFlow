class Purchase {
  final String id;
  final String description;
  final double amount;
  final String cardId;
  final int installments;
  final DateTime purchaseDate;

  const Purchase({
    required this.id,
    required this.description,
    required this.amount,
    required this.cardId,
    required this.installments,
    required this.purchaseDate,
  });

  Purchase copyWith({
    String? id,
    String? description,
    double? amount,
    String? cardId,
    int? installments,
    DateTime? purchaseDate,
  }) {
    return Purchase(
      id: id ?? this.id,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      cardId: cardId ?? this.cardId,
      installments: installments ?? this.installments,
      purchaseDate: purchaseDate ?? this.purchaseDate,
    );
  }
}
