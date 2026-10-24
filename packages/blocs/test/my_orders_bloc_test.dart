import 'package:bloc_test/bloc_test.dart';
import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:test/test.dart';
import 'package:use_cases/use_cases.dart';

import 'fakes.dart';

void main() {
  final clock = FixedClock(mondayNine);
  final inFiveHours = orderAt(mondayNine.add(const Duration(hours: 5)), id: 'o-soon');
  final inThreeDays = orderAt(mondayNine.add(const Duration(days: 3)), id: 'o-later', petId: mica);
  final lastWeek = orderAt(
    mondayNine.subtract(const Duration(days: 7)),
    id: 'o-done',
    status: Completed(at: mondayNine.subtract(const Duration(days: 7))),
  );

  late InMemoryOrders repository;

  setUp(() => repository = InMemoryOrders([inFiveHours, inThreeDays, lastWeek]));

  MyOrdersBloc build() => MyOrdersBloc(
    getMyOrders: GetMyOrders(orders: repository),
    cancelOrder: CancelOrder(orders: repository, clock: clock),
    clock: clock,
    owner: owner,
  );

  /// Loads the orders and waits until the bloc is done with them; the test then skips these two states.
  Future<void> load(MyOrdersBloc bloc) async {
    bloc.add(const MyOrdersRequested());
    await bloc.stream.firstWhere((state) => state is! MyOrdersLoading);
  }

  group('MyOrdersBloc · loading', () {
    blocTest<MyOrdersBloc, MyOrdersState>(
      'loads the orders and asks the domain which ones may still be cancelled',
      build: build,
      act: (bloc) => bloc.add(const MyOrdersRequested()),
      expect: () => [
        const MyOrdersLoading(),
        isA<MyOrdersLoaded>()
            .having((s) => s.current, 'current', [inFiveHours, inThreeDays])
            .having((s) => s.history, 'history', [lastWeek])
            .having((s) => s.cancellable, 'cancellable', {inThreeDays.id})
            .having((s) => s.tooLateToCancel, 'too late (R4)', {inFiveHours.id}),
      ],
    );

    blocTest<MyOrdersBloc, MyOrdersState>(
      'is empty when the owner has no orders',
      build: () {
        repository.orders.clear();
        return build();
      },
      act: (bloc) => bloc.add(const MyOrdersRequested()),
      expect: () => [const MyOrdersLoading(), const MyOrdersEmpty()],
    );

    blocTest<MyOrdersBloc, MyOrdersState>(
      'fails when the repository cannot be reached, and loads again on retry',
      build: build,
      act: (bloc) async {
        repository.failing = true;
        await load(bloc);
        repository.failing = false;
        bloc.add(const MyOrdersRequested());
      },
      expect: () => [const MyOrdersLoading(), isA<MyOrdersFailure>(), const MyOrdersLoading(), isA<MyOrdersLoaded>()],
    );

    blocTest<MyOrdersBloc, MyOrdersState>(
      'shows only the chosen pet\'s orders',
      build: build,
      act: (bloc) async {
        await load(bloc);
        bloc.add(const MyOrdersPetFilterChanged(mica));
      },
      skip: 2,
      expect: () => [
        isA<MyOrdersLoaded>()
            .having((s) => s.current, 'current', [inThreeDays])
            .having((s) => s.history, 'history', isEmpty),
      ],
    );
  });

  group('MyOrdersBloc · cancelling', () {
    blocTest<MyOrdersBloc, MyOrdersState>(
      'marks the order in flight, cancels it and reports it in the reloaded state',
      build: build,
      act: (bloc) async {
        await load(bloc);
        bloc.add(OrderCancellationRequested(inThreeDays.id, reason: 'Promena plana.'));
      },
      skip: 2,
      expect: () => [
        isA<MyOrdersLoaded>().having((s) => s.cancellingId, 'cancelling', inThreeDays.id),
        isA<MyOrdersLoaded>()
            .having((s) => s.byId(inThreeDays.id)?.status, 'status', isA<Cancelled>())
            .having((s) => s.notice, 'notice', isA<OrderCancelled>())
            .having((s) => s.cancellingId, 'cancelling', isNull),
      ],
    );

    blocTest<MyOrdersBloc, MyOrdersState>(
      'keeps the list and reports the domain\'s answer when it is too late (R4)',
      build: build,
      act: (bloc) async {
        await load(bloc);
        bloc.add(OrderCancellationRequested(inFiveHours.id));
      },
      skip: 3,
      expect: () => [
        isA<MyOrdersLoaded>()
            .having((s) => s.notice, 'notice', const CancellationRejected(CancellationTooLate()))
            .having((s) => s.byId(inFiveHours.id)?.status, 'status', const Pending()),
      ],
    );

    blocTest<MyOrdersBloc, MyOrdersState>(
      'keeps the list and reports a lost connection',
      build: build,
      act: (bloc) async {
        await load(bloc);
        repository.failing = true;
        bloc.add(OrderCancellationRequested(inThreeDays.id));
      },
      skip: 3,
      expect: () => [isA<MyOrdersLoaded>().having((s) => s.notice, 'notice', isA<CancellationFailed>())],
    );

    blocTest<MyOrdersBloc, MyOrdersState>(
      'forgets the notice once the screen has shown it',
      build: build,
      act: (bloc) async {
        await load(bloc);
        bloc.add(OrderCancellationRequested(inFiveHours.id));
        await bloc.stream.firstWhere((state) => state is MyOrdersLoaded && state.notice != null);
        bloc.add(const MyOrdersNoticeAcknowledged());
      },
      skip: 4,
      expect: () => [isA<MyOrdersLoaded>().having((s) => s.notice, 'notice', isNull)],
    );
  });
}
