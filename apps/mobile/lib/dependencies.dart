import 'package:domain/domain.dart';
import 'package:use_cases/use_cases.dart';

import 'data/fake_center.dart';
import 'data/seed.dart';

/// Everything the blocs get from outside, made in one place at start-up. The screens never learn which
/// implementation of the port they got, so swapping it changes only this file.
final class AppDependencies {
  const AppDependencies({required this.orders, required this.clock, required this.owner});

  /// Fake orders in memory, with a delay and a switch for errors. From KT2 a second constructor brings the HTTP
  /// adapter.
  factory AppDependencies.fake({Clock clock = const SystemClock(), Duration? latency}) => AppDependencies(
    orders: latency == null ? FakeCenter(clock: clock) : FakeCenter(clock: clock, latency: latency),
    clock: clock,
    owner: currentOwner,
  );

  final OrderRepository orders;
  final Clock clock;

  /// The one signed-in user; signing in arrives with the server in KT2.
  final User owner;
}
