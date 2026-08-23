enum PixKeyType { cpf, cnpj, phone, email, random }

class PixKey {
  const PixKey({
    required this.id,
    required this.type,
    required this.value,
    this.title = '',
  });

  final String id;
  final PixKeyType type;
  final String value;
  final String title;

  String get typeLabel => switch (type) {
    PixKeyType.cpf => 'CPF',
    PixKeyType.cnpj => 'CNPJ',
    PixKeyType.phone => 'Celular',
    PixKeyType.email => 'E-mail',
    PixKeyType.random => 'Chave aleatória',
  };

  PixKey copyWith({PixKeyType? type, String? value, String? title}) {
    return PixKey(
      id: id,
      type: type ?? this.type,
      value: value ?? this.value,
      title: title ?? this.title,
    );
  }

  Map<String, Object?> toMap() {
    return {'id': id, 'type': type.name, 'value': value, 'title': title};
  }

  factory PixKey.fromMap(Map<dynamic, dynamic> map) {
    final typeName = map['type'] as String?;
    final type = PixKeyType.values.firstWhere(
      (item) => item.name == typeName,
      orElse: () => PixKeyType.random,
    );

    return PixKey(
      id: map['id'] as String? ?? '',
      type: type,
      value: map['value'] as String? ?? '',
      title: map['title'] as String? ?? '',
    );
  }
}
