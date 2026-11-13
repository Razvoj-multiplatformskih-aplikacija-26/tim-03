import '../pet/pet.dart';
import '../user.dart';
import 'service_order.dart';

abstract final class AccessPolicy {
  // The mobile app has screens only for the owner, so the walker signs in to the backoffice for now.
  static bool canUseMobile(User user) => user.role == Role.owner;

  static bool canUseBackoffice(User user) => user.role.isStaff;

  static bool canViewBoard(User user) => user.role.isStaff;

  static bool canView(User user, ServiceOrder order) => user.role.isStaff || order.ownerId == user.id;

  static bool canPlaceOrder(User user, Pet pet) => user.role == Role.owner && pet.ownerId == user.id;

  static bool canCancel(User user, ServiceOrder order) => user.role == Role.manager || order.ownerId == user.id;

  static bool canConfirm(User user) => switch (user.role) {
    Role.caretaker || Role.veterinarian || Role.manager => true,
    Role.owner || Role.walker => false,
  };

  static bool canReject(User user) => user.role == Role.manager;

  static bool canHandlePet(User user) => user.role.isStaff;
}
