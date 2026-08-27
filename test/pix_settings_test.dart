import 'dart:convert';
import 'dart:typed_data';

import 'package:finflow/models/pix_key.dart';
import 'package:finflow/models/pix_settings.dart';
import 'package:finflow/services/pix_qr_code_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('serializa banco, chave e QR Code na configuração sincronizada', () {
    final settings = PixSettings(
      keys: const [
        PixKey(
          id: 'key-1',
          type: PixKeyType.email,
          value: 'pix@example.com',
          title: 'PicPay',
          qrCodePngBase64: 'iVBORw0KGgo=',
        ),
      ],
      dataResetId: 'reset-1',
    );

    final restored = PixSettings.fromFinancialMonth(
      settings.toFinancialMonth(clientUpdatedAt: DateTime.utc(2026, 8, 1)),
    );

    expect(restored.keys.single.value, 'pix@example.com');
    expect(restored.keys.single.type, PixKeyType.email);
    expect(restored.keys.single.title, 'PicPay');
    expect(restored.keys.single.qrCodePngBase64, 'iVBORw0KGgo=');
    expect(restored.keys.single.qrCodeBytes, isNotNull);
    expect(restored.dataResetId, 'reset-1');
  });

  test('mantém compatibilidade com o QR Code global da versão anterior', () {
    final legacy = PixSettings.fromMap({
      'schemaVersion': 1,
      'pixKeys': const [],
      'qrCodeTitle': 'PicPay',
      'qrCodePngBase64': 'iVBORw0KGgo=',
    });

    expect(legacy.qrCodeTitle, 'PicPay');
    expect(legacy.qrCodeBytes, isNotNull);
    expect(legacy.keys, isEmpty);
  });

  test('aceita PNG 1000 × 1000 e rejeita outra dimensão', () async {
    const service = PixQrCodeService();
    final valid = base64Decode(_valid1000Png);
    final invalid = base64Decode(_invalid10Png);

    await expectLater(service.validate(valid), completes);
    await expectLater(
      service.validate(invalid),
      throwsA(
        isA<PixQrCodeValidationException>().having(
          (error) => error.message,
          'message',
          contains('10 × 10'),
        ),
      ),
    );
  });

  test('rejeita arquivo que apenas usa extensão PNG', () async {
    const service = PixQrCodeService();
    await expectLater(
      service.validate(Uint8List.fromList([1, 2, 3, 4])),
      throwsA(isA<PixQrCodeValidationException>()),
    );
  });
}

const _valid1000Png =
    'iVBORw0KGgoAAAANSUhEUgAAA+gAAAPoAQAAAABl2OlJAAAAIGNIUk0AAHomAACAhAAA+gAAAIDoAAB1MAAA6mAAADqYAAAXcJy6UTwAAAACYktHRAAB3YoTpAAAAAd0SU1FB+oIFw42FWjq7jcAAAHFSURBVHja7c0xAQAADAIg+5fWGDsGBUgvxW632+12u91ut9vtdrvdbrfb7Xa73W632+12u91ut9vtdrvdbrfb7Xa73W632+12u91ut9vtdrvdbrfb7Xa73W632+12u91ut9vtdrvdbrfb7Xa73W632+12u91ut9vtdrvdbrfb7Xa73W632+12u91ut9vtdrvdbrfb7Xa73W632+12u91ut9vtdrvdbrfb7Xa73W632+12u91ut9vtdrvdbrfb7Xa73W632+12u91ut9vtdrvdbrfb7Xa73W632+12u91ut9vtdrvdbrfb7Xa73W632+12u91ut9vtdrvdbrfb7Xa73W632+12u91ut9vtdrvdbrfb7Xa73W632+12u91ut9vtdrvdbrfb7Xa73W632+12u91ut9vtdrvdbrfb7Xa73W632+12u91ut9vtdrvdbrfb7Xa73W632+12u91ut9vtdrvdbrfb7Xa73W632+12u91ut9vtdrvdbrfb7Xa73W632+12u91ut9vtdrvdbrfb7Xa73W632+12u91ut9vtdrvdbrfb7Xa73W632+12+4N9nDR8My+hcSEAAAAASUVORK5CYII=';

const _invalid10Png =
    'iVBORw0KGgoAAAANSUhEUgAAAAoAAAAKAQAAAAClSfIQAAAAIGNIUk0AAHomAACAhAAA+gAAAIDoAAB1MAAA6mAAADqYAAAXcJy6UTwAAAACYktHRAAB3YoTpAAAAAd0SU1FB+oIFw42HBE2VpMAAAAOSURBVAjXY/h/gAE3AgAHUhF35sjQ4wAAAABJRU5ErkJggg==';
