import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  group('R1 · OrderNote', () {
    test('accepts a note of exactly 300 characters', () {
      expect(OrderNote.parse('a' * 300).valueOrNull?.length, 300);
    });

    test('rejects a note of 301 characters', () {
      expect(OrderNote.parse('a' * 301), const Failure<OrderNote>(NoteTooLong(301)));
    });

    test('counts an emoji family as one character', () {
      const family = '👨‍👩‍👧‍👦';
      expect(OrderNote.parse(family * 300).isSuccess, isTrue);
      expect(OrderNote.parse(family * 301), const Failure<OrderNote>(NoteTooLong(301)));
    });

    test('trims surrounding whitespace before measuring', () {
      final note = OrderNote.parse('  ${'š' * 300}  ').valueOrNull;
      expect(note?.length, 300);
      expect(note?.text.startsWith('š'), isTrue);
    });
  });
}
