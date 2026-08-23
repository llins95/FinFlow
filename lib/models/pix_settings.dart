import 'dart:convert';
import 'dart:typed_data';

import 'financial_entry.dart';
import 'financial_month.dart';
import 'pix_key.dart';

class PixSettings {
  static const int storageYear = 2100;
  static const int storageMonth = 12;
  static const String storageEntryId = 'finflow-user-settings';

  const PixSettings({
    this.keys = const [],
    this.qrCodeTitle,
    this.qrCodePngBase64,
    this.dataResetId,
  });

  final List<PixKey> keys;
  final String? qrCodeTitle;
  final String? qrCodePngBase64;
  final String? dataResetId;

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

  PixSettings copyWith({
    List<PixKey>? keys,
    Object? qrCodeTitle = _unset,
    Object? qrCodePngBase64 = _unset,
    Object? dataResetId = _unset,
  }) {
    return PixSettings(
      keys: List.unmodifiable(keys ?? this.keys),
      qrCodeTitle: identical(qrCodeTitle, _unset)
          ? this.qrCodeTitle
          : qrCodeTitle as String?,
      qrCodePngBase64: identical(qrCodePngBase64, _unset)
          ? this.qrCodePngBase64
          : qrCodePngBase64 as String?,
      dataResetId: identical(dataResetId, _unset)
          ? this.dataResetId
          : dataResetId as String?,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'schemaVersion': 1,
      'pixKeys': keys.map((key) => key.toMap()).toList(),
      'qrCodeTitle': qrCodeTitle,
      'qrCodePngBase64': qrCodePngBase64,
      'dataResetId': dataResetId,
    };
  }

  factory PixSettings.fromMap(Map<dynamic, dynamic> map) {
    final rawKeys = map['pixKeys'] as List<dynamic>? ?? const [];
    return PixSettings(
      keys: List.unmodifiable(
        rawKeys
            .whereType<Map>()
            .map((item) => PixKey.fromMap(item))
            .where((key) => key.id.isNotEmpty && key.value.isNotEmpty),
      ),
      qrCodeTitle: map['qrCodeTitle'] as String?,
      qrCodePngBase64: map['qrCodePngBase64'] as String?,
      dataResetId: map['dataResetId'] as String?,
    );
  }

  FinancialMonth toFinancialMonth({DateTime? clientUpdatedAt}) {
    return FinancialMonth(
      year: storageYear,
      month: storageMonth,
      entries: [
        FinancialEntry(
          id: storageEntryId,
          name: 'Configurações sincronizadas',
          amountInCents: 0,
          type: FinancialEntryType.appSettings,
          metadata: toMap(),
        ),
      ],
      clientUpdatedAt: clientUpdatedAt,
    );
  }

  factory PixSettings.fromFinancialMonth(FinancialMonth? month) {
    if (month == null) {
      return const PixSettings();
    }
    for (final entry in month.entries) {
      if (entry.id == storageEntryId && entry.metadata != null) {
        return PixSettings.fromMap(entry.metadata!);
      }
    }
    return const PixSettings();
  }
}

const Object _unset = Object();
