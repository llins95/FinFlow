import 'dart:convert';
import 'dart:typed_data';

enum PixKeyType { cpf, cnpj, phone, email, random }

class PixKey {
  const PixKey({
    required this.id,
    required this.type,
    required this.value,
    this.title = '',
    this.qrCodePngBase64,
  });

  final String id;
  final PixKeyType type;
  final String value;
  final String title;
  final String? qrCodePngBase64;

  Uint8List? get qrCodeBytes {
    final encoded = qrCodePngBase64;
    if (encoded == null || encoded.isEmpty) {
      return null;
    }
    try {
      return base64Decode(encoded);
    } on FormatException {
      return null;
    }
  }

  String get typeLabel => switch (type) {
    PixKeyType.cpf => 'CPF',
    PixKeyType.cnpj => 'CNPJ',
    PixKeyType.phone => 'Celular',
    PixKeyType.email => 'E-mail',
    PixKeyType.random => 'Chave aleatória',
  };

  PixKey copyWith({
    PixKeyType? type,
    String? value,
    String? title,
    Object? qrCodePngBase64 = _unset,
  }) {
    return PixKey(
      id: id,
      type: type ?? this.type,
      value: value ?? this.value,
      title: title ?? this.title,
      qrCodePngBase64: identical(qrCodePngBase64, _unset)
          ? this.qrCodePngBase64
          : qrCodePngBase64 as String?,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'type': type.name,
      'value': value,
      'title': title,
      'qrCodePngBase64': qrCodePngBase64,
    };
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
      qrCodePngBase64: map['qrCodePngBase64'] as String?,
    );
  }
}

const Object _unset = Object();
