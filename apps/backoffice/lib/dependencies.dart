import 'package:domain/domain.dart';
import 'package:use_cases/use_cases.dart';

import 'data/fake_center.dart';
import 'data/fake_sessions.dart';
import 'data/seed.dart';

final class BackofficeDependencies {
  BackofficeDependencies({
    required this.clock,
    required OrderRepository orders,
    required BoardRepository boards,
    required SessionRepository sessions,
  }) : getCenterBoard = GetCenterBoard(boards: boards),
       confirmOrder = ConfirmOrder(orders: orders, boards: boards, clock: clock),
       rejectOrder = RejectOrder(orders: orders, clock: clock),
       logIn = LogIn(sessions: sessions),
       restoreSession = RestoreSession(sessions: sessions),
       logOut = LogOut(sessions: sessions),
       sessionExpirations = sessions.expirations;

  factory BackofficeDependencies.fake({
    Clock clock = const SystemClock(),
    Duration? latency,
    User staff = currentStaff,
    bool signedIn = true,
  }) {
    final center = latency == null ? FakeCenter(clock: clock) : FakeCenter(clock: clock, latency: latency);
    return BackofficeDependencies(
      clock: clock,
      orders: center,
      boards: center,
      sessions: FakeSessions(staff, signedIn: signedIn),
    );
  }

  final Clock clock;

  final GetCenterBoard getCenterBoard;
  final ConfirmOrder confirmOrder;
  final RejectOrder rejectOrder;

  /// The signed-in staff member comes from here, through SessionBloc, and never from the screens.
  final LogIn logIn;
  final RestoreSession restoreSession;
  final LogOut logOut;
  final Stream<void> sessionExpirations;
}
