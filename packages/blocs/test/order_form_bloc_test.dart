import 'package:bloc_test/bloc_test.dart';
import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:test/test.dart';
import 'package:use_cases/use_cases.dart';

import 'fakes.dart';

void main() {
  setUpAll(initializeDomainTimeZones);

  const ownersPet = Pet(id: rex, ownerId: UserId('u-owner'), name: 'Reks', species: Species.dog, size: PetSize.large);
  const someoneElsesPet = Pet(
    id: PetId('p-other'),
    ownerId: UserId('u-owner-2'),
    name: 'Žuća',
    species: Species.dog,
    size: PetSize.small,
  );
  final tomorrow = mondayNine.add(const Duration(days: 1));
  final grooming = ServicePeriod.existing(start: tomorrow, end: tomorrow.add(const Duration(hours: 2)));

  late InMemoryOrders repository;

  setUp(() => repository = InMemoryOrders());

  OrderFormBloc build() {
    final center = InMemoryCenter();
    return OrderFormBloc(
      placeOrder: PlaceOrder(orders: repository),
      getMyPets: GetMyPets(pets: center),
      getOpeningHours: GetOpeningHours(center: center),
      owner: owner,
    );
  }

  /// Loads the pets and the opening hours; the test then skips the loading and editing states.
  Future<void> start(OrderFormBloc bloc) async {
    bloc.add(const OrderFormStarted());
    await bloc.stream.firstWhere((state) => state is OrderFormEditing);
  }

  OrderFormSubmitted submitted(Pet pet) =>
      OrderFormSubmitted(pet: pet, service: ServiceType.grooming, period: grooming);

  blocTest<OrderFormBloc, OrderFormState>(
    'sends the order and hands back the stored one',
    build: build,
    act: (bloc) async {
      await start(bloc);
      bloc.add(submitted(ownersPet));
    },
    skip: 2,
    expect: () => [
      isA<OrderFormSubmitting>(),
      isA<OrderFormSucceeded>().having((s) => s.order.status, 'status', const Pending()),
    ],
    verify: (_) => expect(repository.orders, hasLength(1)),
  );

  blocTest<OrderFormBloc, OrderFormState>(
    'reports the domain\'s refusal as a type, not as text',
    build: build,
    act: (bloc) async {
      await start(bloc);
      bloc.add(submitted(someoneElsesPet));
    },
    skip: 2,
    expect: () => [
      isA<OrderFormSubmitting>(),
      isA<OrderFormRejected>().having((s) => s.error, 'error', const NotAllowed()),
    ],
  );

  blocTest<OrderFormBloc, OrderFormState>(
    'reports a lost connection so the owner can send again',
    build: () {
      repository.failing = true;
      return build();
    },
    act: (bloc) async {
      await start(bloc);
      bloc.add(submitted(ownersPet));
    },
    skip: 2,
    expect: () => [isA<OrderFormSubmitting>(), isA<OrderFormFailed>()],
  );

  blocTest<OrderFormBloc, OrderFormState>(
    'sends once even if the button is pressed twice',
    build: build,
    act: (bloc) async {
      await start(bloc);
      bloc
        ..add(submitted(ownersPet))
        ..add(submitted(ownersPet));
    },
    skip: 2,
    expect: () => [isA<OrderFormSubmitting>(), isA<OrderFormSucceeded>()],
    verify: (_) => expect(repository.orders, hasLength(1)),
  );
}
