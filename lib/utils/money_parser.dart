class MoneyParser {
  const MoneyParser._();

  static int? parseToCents(String input) {
    var value = input
        .trim()
        .replaceAll('R\$', '')
        .replaceAll(RegExp(r'\s+'), '');

    if (value.isEmpty) {
      return null;
    }

    var sign = 1;
    if (value.startsWith('-')) {
      sign = -1;
      value = value.substring(1);
    }

    if (value.isEmpty || !RegExp(r'^[0-9.,]+$').hasMatch(value)) {
      return null;
    }

    String wholePart;
    String decimalPart;

    if (value.contains(',')) {
      final separatorIndex = value.lastIndexOf(',');
      wholePart = value.substring(0, separatorIndex).replaceAll('.', '');
      decimalPart = value.substring(separatorIndex + 1);
    } else if (value.contains('.')) {
      final separatorIndex = value.lastIndexOf('.');
      final possibleDecimalPart = value.substring(separatorIndex + 1);
      if (possibleDecimalPart.length <= 2) {
        wholePart = value.substring(0, separatorIndex).replaceAll('.', '');
        decimalPart = possibleDecimalPart;
      } else {
        wholePart = value.replaceAll('.', '');
        decimalPart = '';
      }
    } else {
      wholePart = value;
      decimalPart = '';
    }

    wholePart = wholePart.replaceAll(',', '');
    decimalPart = decimalPart.replaceAll(RegExp(r'[^0-9]'), '');

    final whole = int.tryParse(wholePart.isEmpty ? '0' : wholePart);
    if (whole == null || decimalPart.length > 2) {
      return null;
    }

    final normalizedDecimals = decimalPart.padRight(2, '0');
    final decimals = int.tryParse(
      normalizedDecimals.isEmpty ? '0' : normalizedDecimals,
    );
    if (decimals == null) {
      return null;
    }

    return sign * (whole * 100 + decimals);
  }
}
