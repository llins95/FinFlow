import '../utils/money_parser.dart';

class NotificationPurchaseCandidate {
  const NotificationPurchaseCandidate({
    required this.id,
    required this.sourcePackage,
    required this.description,
    required this.amountInCents,
    required this.occurredAt,
    required this.rawTitle,
    required this.rawText,
  });

  final String id;
  final String sourcePackage;
  final String description;
  final int amountInCents;
  final DateTime occurredAt;
  final String rawTitle;
  final String rawText;
}

class NotificationPurchaseParser {
  static final RegExp _amountPattern = RegExp(
    r'R\$\s*([0-9][0-9.]*,[0-9]{2})',
    caseSensitive: false,
  );

  static NotificationPurchaseCandidate? tryParse(
    Map<Object?, Object?> raw,
  ) {
    final id = _readString(raw['id']);
    final sourcePackage = _readString(raw['sourcePackage']);
    final title = _readString(raw['title']);
    final text = _readString(raw['text']);
    final postedAt = raw['postedAt'];

    if (id.isEmpty || postedAt is! num) {
      return null;
    }

    final textMatch = _amountPattern.firstMatch(text);
    final titleMatch = _amountPattern.firstMatch(title);
    final amountMatch = textMatch ?? titleMatch;
    if (amountMatch == null) {
      return null;
    }

    final amountInCents = MoneyParser.parseToCents(amountMatch.group(1)!);
    if (amountInCents == null || amountInCents <= 0) {
      return null;
    }

    final matchedSource = textMatch == null ? title : text;
    final otherSource = textMatch == null ? text : title;

    return NotificationPurchaseCandidate(
      id: id,
      sourcePackage: sourcePackage,
      description: _extractDescription(
        matchedSource,
        otherSource,
        amountMatch,
      ),
      amountInCents: amountInCents,
      occurredAt: DateTime.fromMillisecondsSinceEpoch(
        postedAt.toInt(),
        isUtc: true,
      ).toLocal(),
      rawTitle: title,
      rawText: text,
    );
  }

  static String _extractDescription(
    String matchedSource,
    String otherSource,
    RegExpMatch amountMatch,
  ) {
    var candidate = matchedSource.replaceRange(
      amountMatch.start,
      amountMatch.end,
      ' ',
    );

    if (candidate.trim().length < 3 && otherSource.trim().isNotEmpty) {
      candidate = otherSource;
    }

    candidate = candidate
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceFirst(
          RegExp(
            r'^(?:pagamento|compra|transação)\s*'
            r'(?:(?:foi\s+)?aprovad[ao]|realizad[ao]|de|no valor de)?\s*',
            caseSensitive: false,
          ),
          '',
        )
        .replaceFirst(
          RegExp(
            r'^(?:você\s+)?(?:pagou|gastou|comprou)\s*'
            r'(?:em|no|na|para|com)?\s*',
            caseSensitive: false,
          ),
          '',
        )
        .replaceFirst(
          RegExp(r'^(?:em|no|na|para|com)\s+', caseSensitive: false),
          '',
        )
        .split(RegExp(r'[•\n]'))
        .first
        .trim()
        .replaceAll(RegExp(r'^[\s:–—-]+|[\s.!]+$'), '');

    if (candidate.length > 80) {
      candidate = candidate.substring(0, 80).trimRight();
    }

    if (candidate.length < 2 || _isGeneric(candidate)) {
      final cleanTitle = titleWithoutAmount(otherSource);
      if (cleanTitle.length >= 2 && !_isGeneric(cleanTitle)) {
        return cleanTitle;
      }
      return 'Compra pela Carteira do Google';
    }

    return candidate;
  }

  static String titleWithoutAmount(String value) {
    return value
        .replaceAll(_amountPattern, '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim()
        .replaceAll(RegExp(r'^[\s:–—-]+|[\s.!]+$'), '');
  }

  static bool _isGeneric(String value) {
    final normalized = value.toLowerCase();
    return normalized == 'pagamento' ||
        normalized == 'pagamento aprovado' ||
        normalized == 'pagamento realizado' ||
        normalized == 'compra' ||
        normalized == 'compra aprovada' ||
        normalized == 'google wallet' ||
        normalized == 'carteira do google';
  }

  static String _readString(Object? value) => value?.toString().trim() ?? '';
}
