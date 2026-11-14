import 'package:flutter_test/flutter_test.dart';
import 'package:hhmmobile/core/utils/formatters.dart';

void main() {
  group('Formatters', () {
    group('usd', () {
      test('should use two decimals from one dollar up', () {
        expect(Formatters.usd(65420.5), r'$65,420.50');
      });

      test('should show more decimals for sub-dollar prices', () {
        expect(Formatters.usd(0.5), r'$0.5000');
        expect(Formatters.usd(0.00001234), r'$0.00001234');
      });

      test('should show a dash when the price is missing', () {
        expect(Formatters.usd(null), '—');
      });
    });

    group('usdCompact', () {
      test('should abbreviate large market values', () {
        expect(Formatters.usdCompact(2.62e12), r'$2.62T');
        expect(Formatters.usdCompact(9.513e10), r'$95.1B');
      });

      test('should show a dash when the value is missing', () {
        expect(Formatters.usdCompact(null), '—');
      });
    });
  });
}
