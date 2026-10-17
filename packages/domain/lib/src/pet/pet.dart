import 'package:meta/meta.dart';

import '../identifiers.dart';

enum Species { dog, cat }

/// Ordered from the smallest to the largest, so a kennel fits every size up to its own.
enum PetSize { small, medium, large }

@immutable
final class Pet {
  const Pet({required this.id, required this.ownerId, required this.name, required this.species, required this.size});

  final PetId id;
  final UserId ownerId;
  final String name;
  final Species species;
  final PetSize size;

  @override
  bool operator ==(Object other) =>
      other is Pet &&
      other.id == id &&
      other.ownerId == ownerId &&
      other.name == name &&
      other.species == species &&
      other.size == size;

  @override
  int get hashCode => Object.hash(id, ownerId, name, species, size);

  @override
  String toString() => 'Pet($name, ${species.name}, ${size.name})';
}
