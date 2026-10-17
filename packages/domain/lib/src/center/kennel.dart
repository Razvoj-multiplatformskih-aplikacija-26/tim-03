import 'package:meta/meta.dart';

import '../identifiers.dart';
import '../pet/pet.dart';

@immutable
final class Kennel {
  const Kennel({required this.id, required this.label, required this.size});

  final KennelId id;
  final String label;

  /// The largest pet the kennel can hold. One kennel holds one pet at a time.
  final PetSize size;

  bool fits(PetSize petSize) => petSize.index <= size.index;

  @override
  bool operator ==(Object other) => other is Kennel && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Kennel($label, ${size.name})';
}
