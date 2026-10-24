import 'package:test/test.dart';
import 'package:use_cases/use_cases.dart';

void main() {
  group('Clock', () {
    test('FixedClock always answers the same instant, in UTC', () {
      final clock = FixedClock(DateTime(2026, 10, 20, 10, 30));
      expect(clock.now(), clock.now());
      expect(clock.now().isUtc, isTrue);
    });

    test('SystemClock answers in UTC', () {
      expect(const SystemClock().now().isUtc, isTrue);
    });
  });
}
