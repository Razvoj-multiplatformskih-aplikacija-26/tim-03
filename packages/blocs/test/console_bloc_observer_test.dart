import 'package:bloc/bloc.dart';
import 'package:blocs/blocs.dart';
import 'package:test/test.dart';
import 'package:use_cases/use_cases.dart';

import 'fakes.dart';

void main() {
  test('ConsoleBlocObserver writes a line when a bloc is created, for every transition and when it closes', () async {
    final previous = Bloc.observer;
    addTearDown(() => Bloc.observer = previous);
    final lines = <String>[];
    Bloc.observer = ConsoleBlocObserver(lines.add);

    final repository = InMemoryOrders();
    final bloc = MyOrdersBloc(
      getMyOrders: GetMyOrders(orders: repository),
      cancelOrder: CancelOrder(orders: repository, clock: FixedClock(mondayNine)),
      clock: FixedClock(mondayNine),
      owner: owner,
    )..add(const MyOrdersRequested());
    await bloc.stream.firstWhere((state) => state is MyOrdersEmpty);
    await bloc.close();

    expect(lines, hasLength(4));
    expect(lines.first, endsWith('· created'));
    expect(lines[1], contains(' → '));
    expect(lines[2], contains(' → '));
    expect(lines.last, endsWith('· closed'));
  });
}
