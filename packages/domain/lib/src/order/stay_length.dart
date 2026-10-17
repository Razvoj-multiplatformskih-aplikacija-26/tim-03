import 'package:meta/meta.dart';

import '../errors.dart';
import '../result.dart';

/// Number of nights a pet stays in boarding.
@immutable
final class StayLength {
  const StayLength._(this.value);

  static const min = 1;
  static const max = 30;

  static const shortest = StayLength._(min);

  final int value;

  static Result<StayLength> parse(int value) {
    if (value < min || value > max) return Failure(InvalidStayLength(value));
    return Success(StayLength._(value));
  }

  @override
  bool operator ==(Object other) => other is StayLength && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'StayLength($value)';
}
