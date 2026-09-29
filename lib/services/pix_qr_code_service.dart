import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

class PixQrCodeValidationException implements Exception {
  const PixQrCodeValidationException(this.message);

  final String message;

  @override
  String toString() => message;
}

class PixQrCodeService {
  const PixQrCodeService();

  static const int requiredDimension = 1000;
  static const int maximumFileSizeInBytes = 5 * 1024 * 1024;

  Future<Uint8List?> pickAndValidate() async {
    final file = await FilePicker.pickFile(
      dialogTitle: 'Selecionar QR Code Pix',
      type: FileType.custom,
      allowedExtensions: const ['png'],
    );
    if (file == null) {
      return null;
    }

    final bytes = await file.readAsBytes();
    await validate(bytes);
    return bytes;
  }

  Future<void> validate(Uint8List bytes) async {
    if (bytes.lengthInBytes > maximumFileSizeInBytes) {
      throw const PixQrCodeValidationException(
        'A imagem deve ter no máximo 5 MB.',
      );
    }
    if (!_hasPngSignature(bytes)) {
      throw const PixQrCodeValidationException(
        'Selecione uma imagem no formato PNG.',
      );
    }

    final dimensions = _readPngDimensions(bytes);
    if (dimensions == null || !_hasIendChunk(bytes)) {
      throw const PixQrCodeValidationException(
        'Não foi possível ler a imagem PNG selecionada.',
      );
    }
    final (width, height) = dimensions;
    if (width != requiredDimension || height != requiredDimension) {
      throw PixQrCodeValidationException(
        'A imagem deve ter exatamente '
        '$requiredDimension × $requiredDimension px. '
        'Arquivo selecionado: $width × $height px.',
      );
    }
  }

  bool _hasPngSignature(Uint8List bytes) {
    const signature = <int>[137, 80, 78, 71, 13, 10, 26, 10];
    if (bytes.length < signature.length) {
      return false;
    }
    for (var index = 0; index < signature.length; index++) {
      if (bytes[index] != signature[index]) {
        return false;
      }
    }
    return true;
  }

  (int, int)? _readPngDimensions(Uint8List bytes) {
    if (bytes.length < 33 ||
        bytes[8] != 0 ||
        bytes[9] != 0 ||
        bytes[10] != 0 ||
        bytes[11] != 13 ||
        bytes[12] != 73 ||
        bytes[13] != 72 ||
        bytes[14] != 68 ||
        bytes[15] != 82) {
      return null;
    }
    final data = ByteData.sublistView(bytes);
    return (data.getUint32(16), data.getUint32(20));
  }

  bool _hasIendChunk(Uint8List bytes) {
    if (bytes.length < 12) {
      return false;
    }
    final offset = bytes.length - 8;
    return bytes[offset] == 73 &&
        bytes[offset + 1] == 69 &&
        bytes[offset + 2] == 78 &&
        bytes[offset + 3] == 68;
  }
}
