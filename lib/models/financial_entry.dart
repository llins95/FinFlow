enum EntryType { income, expense }

class FinancialEntry {
  final String id;
  final String description;
  final int amountInCents;
  final EntryType type;
  final DateTime dueDate;
  final bool paid;
  final String? recurrenceId;

  const FinancialEntry({
    required this.id,
    required this.description,
    required this.amountInCents,
    required this.type,
    required this.dueDate,
    this.paid = false,
    this.recurrenceId,
  });

  double get amount => amountInCents / 100;

  FinancialEntry copyWith({String? description, int? amountInCents, DateTime? dueDate, bool? paid}) => FinancialEntry(
    id: id,
    description: description ?? this.description,
    amountInCents: amountInCents ?? this.amountInCents,
    type: type,
    dueDate: dueDate ?? this.dueDate,
    paid: paid ?? this.paid,
    recurrenceId: recurrenceId,
  );

  Map<String, dynamic> toMap() => {
    'id': id, 'description': description, 'amountInCents': amountInCents,
    'type': type.name, 'dueDate': dueDate.toIso8601String(), 'paid': paid,
    'recurrenceId': recurrenceId,
  };

  factory FinancialEntry.fromMap(Map<dynamic, dynamic> map) => FinancialEntry(
    id: map['id'] as String,
    description: map['description'] as String,
    amountInCents: map['amountInCents'] as int,
    type: EntryType.values.byName(map['type'] as String),
    dueDate: DateTime.parse(map['dueDate'] as String),
    paid: map['paid'] as bool? ?? false,
    recurrenceId: map['recurrenceId'] as String?,
  );
}
