import 'package:use_cases/use_cases.dart';

import 'data/fake_center.dart';
import 'data/fake_sessions.dart';
import 'data/seed.dart';

final class AppDependencies {
  const AppDependencies({
    required this.orders,
    required this.pets,
    required this.center,
    required this.sessions,
    required this.clock,
  });

  factory AppDependencies.fake({Clock clock = const SystemClock(), Duration? latency, bool signedIn = true}) {
    final fake = latency == null ? FakeCenter(clock: clock) : FakeCenter(clock: clock, latency: latency);
    return AppDependencies(
      orders: fake,
      pets: fake,
      center: fake,
      sessions: FakeSessions(currentOwner, signedIn: signedIn),
      clock: clock,
    );
  }

  final OrderRepository orders;
  final PetRepository pets;
  final CenterRepository center;

  /// The signed-in owner comes from here, through SessionBloc, and never from the screens.
  final SessionRepository sessions;
  final Clock clock;
}
