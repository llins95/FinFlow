import 'package:finflow/utils/money_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('converte valores brasileiros para centavos', () {
    expect(MoneyParser.parseToCents('5.759,27'), 575927);
    expect(MoneyParser.parseToCents('R\$ 1.470,22'), 147022);
    expect(MoneyParser.parseToCents('100'), 10000);
    expect(MoneyParser.parseToCents('50,9'), 5090);
    expect(MoneyParser.parseToCents('-883,70'), -88370);
  });

  test('rejeita valores inválidos', () {
    expect(MoneyParser.parseToCents(''), isNull);
    expect(MoneyParser.parseToCents('abc'), isNull);
    expect(MoneyParser.parseToCents('12,345'), isNull);
  });
}
