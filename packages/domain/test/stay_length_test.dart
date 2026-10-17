import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  group('R2 · StayLength', () {
    test('accepts one and thirty nights', () {
      expect(StayLength.parse(1).valueOrNull?.value, 1);
      expect(StayLength.parse(30).valueOrNull?.value, 30);
    });

    test('rejects zero and thirty-one nights', () {
      expect(StayLength.parse(0), const Failure<StayLength>(InvalidStayLength(0)));
      expect(StayLength.parse(31), const Failure<StayLength>(InvalidStayLength(31)));
    });
  });
}
