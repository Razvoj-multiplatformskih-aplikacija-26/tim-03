import '../user.dart';

enum ServiceType {
  boarding,
  grooming,
  vetCheckup,
  walk;

  /// Boarding needs a kennel for the whole stay; every other service needs a member of staff.
  bool get needsKennel => this == ServiceType.boarding;

  /// The staff role that performs the service, or null for boarding.
  Role? get performer => switch (this) {
    ServiceType.boarding => null,
    ServiceType.grooming => Role.caretaker,
    ServiceType.vetCheckup => Role.veterinarian,
    ServiceType.walk => Role.walker,
  };

  /// Length of one visit, or null for boarding, which lasts whole nights.
  Duration? get visitLength => switch (this) {
    ServiceType.boarding => null,
    ServiceType.grooming => const Duration(hours: 2),
    ServiceType.vetCheckup => const Duration(minutes: 30),
    ServiceType.walk => const Duration(hours: 1),
  };
}
