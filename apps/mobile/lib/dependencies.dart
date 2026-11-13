import 'package:domain/domain.dart';
import 'package:use_cases/use_cases.dart';

import 'data/fake_center.dart';
import 'data/seed.dart';

final class AppDependencies {
  const AppDependencies({
    required this.orders,
    required this.pets,
    required this.center,
    required this.clock,
    required this.owner,
  });

  factory AppDependencies.fake({Clock clock = const SystemClock(), Duration? latency}) {
    final fake = latency == null ? FakeCenter(clock: clock) : FakeCenter(clock: clock, latency: latency);
    return AppDependencies(orders: fake, pets: fake, center: fake, clock: clock, owner: currentOwner);
  }

  final OrderRepository orders;
  final PetRepository pets;
  final CenterRepository center;
  final Clock clock;

  final User owner;
}
