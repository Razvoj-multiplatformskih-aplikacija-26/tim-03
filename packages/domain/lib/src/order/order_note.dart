import 'package:characters/characters.dart';
import 'package:meta/meta.dart';

import '../errors.dart';
import '../result.dart';

@immutable
final class OrderNote {
  const OrderNote._(this.text);

  static const maxLength = 300;

  final String text;

  int get length => text.characters.length;

  bool get isEmpty => text.isEmpty;

  static Result<OrderNote> parse(String input) {
    final text = input.trim();
    final length = text.characters.length;
    if (length > maxLength) return Failure(NoteTooLong(length));
    return Success(OrderNote._(text));
  }

  @override
  bool operator ==(Object other) => other is OrderNote && other.text == text;

  @override
  int get hashCode => text.hashCode;

  @override
  String toString() => 'OrderNote("$text")';
}
