import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/data/fake_center.dart';
import 'package:mobile/data/seed.dart';
import 'package:use_cases/use_cases.dart';

void main() {
  setUpAll(initializeDomainTimeZones);

  final mondayNine = FixedClock(DateTime.utc(2026, 10, 19, 7));

  FakeCenter center() => FakeCenter(clock: mondayNine, latency: Duration.zero);

  test('starts with the seeded orders of the signed-in owner', () async {
    expect(await center().ordersOf(currentOwner.id), hasLength(12));
  });

  test('a simulated failure makes only the next request fail', () async {
    final fake = center()..failingRequests = 1;
    await expectLater(fake.ordersOf(currentOwner.id), throwsA(isA<RepositoryException>()));
    expect(await fake.ordersOf(currentOwner.id), isNotEmpty);
  });

  test('a simulated empty response comes back once', () async {
    final fake = center()..emptyResponses = 1;
    expect(await fake.ordersOf(currentOwner.id), isEmpty);
    expect(await fake.ordersOf(currentOwner.id), isNotEmpty);
  });

  test('a new order goes through the domain, which refuses an overlap for the same pet (R6)', () async {
    final fake = center();
    final rex = fakePets.first;
    final orders = await fake.ordersOf(currentOwner.id);
    final active = orders.firstWhere((order) => order.petId == rex.id && order.isActive);
    final request = OrderRequest(owner: currentOwner, pet: rex, service: active.service, period: active.period);
    expect(await fake.create(request), const Failure<ServiceOrder>(PetAlreadyBooked()));
  });
}
