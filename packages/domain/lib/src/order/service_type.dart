import '../user.dart';

enum ServiceType {
  boarding,
  grooming,
  vetCheckup,
  walk;

  bool get needsKennel => this == ServiceType.boarding;

  Role? get performer => switch (this) {
    ServiceType.boarding => null,
    ServiceType.grooming => Role.caretaker,
    ServiceType.vetCheckup => Role.veterinarian,
    ServiceType.walk => Role.walker,
  };

  Duration? get visitLength => switch (this) {
    ServiceType.boarding => null,
    ServiceType.grooming => const Duration(hours: 2),
    ServiceType.vetCheckup => const Duration(minutes: 30),
    ServiceType.walk => const Duration(hours: 1),
  };
}
