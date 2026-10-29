import 'dart:async';

import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:test/test.dart';
import 'package:use_cases/use_cases.dart';

import 'fakes.dart';

const _manager = User(id: UserId('u-manager'), name: 'Milica', role: Role.manager);
const _caretaker = User(id: UserId('u-caretaker'), name: 'Jelena', role: Role.caretaker);
const _rexPet = Pet(id: rex, ownerId: UserId('u-owner'), name: 'Reks', species: Species.dog, size: PetSize.large);

/// The whole center in memory. While [gate] is set, saving waits for it, like a slow network.
final class _Center implements OrderRepository, BoardRepository {
  _Center(List<ServiceOrder> orders) : orders = List.of(orders);

  final List<ServiceOrder> orders;
  Completer<void>? gate;

  @override
  Future<CenterBoard> board() async => CenterBoard(
    orders: List.unmodifiable(orders),
    pets: {rex: _rexPet},
    people: {
      for (final person in [owner, _manager, _caretaker]) person.id: person,
    },
    kennels: const [],
  );

  @override
  Future<ServiceOrder> save(ServiceOrder order) async {
    await gate?.future;
    orders[orders.indexWhere((o) => o.id == order.id)] = order;
    return order;
  }

  @override
  Future<List<ServiceOrder>> ordersOf(UserId ownerId) async => orders.where((o) => o.ownerId == ownerId).toList();

  @override
  Future<ServiceOrder?> find(OrderId id) async => orders.where((o) => o.id == id).firstOrNull;

  @override
  Future<Result<ServiceOrder>> create(OrderRequest request) => throw UnimplementedError();
}

void main() {
  final clock = FixedClock(mondayNine);
  final tomorrow = orderAt(mondayNine.add(const Duration(days: 1)), id: 'o-tomorrow');
  final dayAfter = orderAt(mondayNine.add(const Duration(days: 2)), id: 'o-day-after');

  late _Center center;
  late OrderBoardBloc bloc;

  setUp(() {
    center = _Center([tomorrow, dayAfter]);
    bloc = OrderBoardBloc(
      getCenterBoard: GetCenterBoard(boards: center),
      confirmOrder: ConfirmOrder(orders: center, boards: center, clock: clock),
      rejectOrder: RejectOrder(orders: center, clock: clock),
      clock: clock,
      staff: _manager,
    );
  });

  tearDown(() => bloc.close());

  /// The first loaded state that passes [test], the current one included.
  Future<OrderBoardLoaded> until(bool Function(OrderBoardLoaded state) test) async {
    final current = bloc.state;
    if (current is OrderBoardLoaded && test(current)) return current;
    final next = await bloc.stream.firstWhere((state) => state is OrderBoardLoaded && test(state));
    return next as OrderBoardLoaded;
  }

  /// Loads the board, selects the first order and starts confirming it; the save waits until the test opens the gate.
  Future<Completer<void>> confirmFirstAndHold() async {
    bloc.add(const OrderBoardRequested());
    await until((state) => true);
    bloc.add(OrderBoardOrderSelected(tomorrow.id));
    await until((state) => state.selectedId == tomorrow.id);
    final gate = center.gate = Completer<void>();
    bloc.add(OrderConfirmationRequested(tomorrow.id));
    await until((state) => state.isBusy);
    return gate;
  }

  group('OrderBoardBloc · selection while an action is on its way', () {
    test('moving the selection keeps the action in flight, so no second action can start', () async {
      final gate = await confirmFirstAndHold();

      bloc.add(const OrderBoardSelectionMoved(1));
      final moved = await until((state) => state.selectedId == dayAfter.id);

      expect(moved.isBusy, isTrue);
      gate.complete();
      await until((state) => state.notice is StaffActionSucceeded);
    });

    test('after a success the selection made meanwhile stays', () async {
      final gate = await confirmFirstAndHold();
      bloc.add(const OrderBoardSelectionMoved(1));
      await until((state) => state.selectedId == dayAfter.id);

      gate.complete();
      final done = await until((state) => state.notice is StaffActionSucceeded);

      expect(done.selectedId, dayAfter.id);
      expect(done.isBusy, isFalse);
      expect(done.board.orderById(tomorrow.id)!.status, isA<Confirmed>());
    });

    test('after a lost connection the selection made meanwhile stays and the action ends', () async {
      final gate = await confirmFirstAndHold();
      bloc.add(const OrderBoardSelectionMoved(1));
      await until((state) => state.selectedId == dayAfter.id);

      gate.completeError(const RepositoryException('simulated outage'));
      final done = await until((state) => state.notice is StaffActionFailed);

      expect(done.selectedId, dayAfter.id);
      expect(done.isBusy, isFalse);
      expect(done.board.orderById(tomorrow.id)!.status, isA<Pending>());
    });
  });
}
