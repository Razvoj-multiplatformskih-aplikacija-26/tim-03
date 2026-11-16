import 'package:api_contract/api_contract.dart';
import 'package:api_mapping/api_mapping.dart';
import 'package:domain/domain.dart';
import 'package:relic/relic.dart' hide Result;
import 'package:use_cases/use_cases.dart';

import 'http.dart';
import 'postgres_center.dart';
import 'sessions.dart';

/// The server's routes run the same use cases as the clients. The checks come in the order
/// 401 (signedIn) → 404 (may see the record) → 403 (may do the action) → 422 and 409 (the domain's rules).
final class CenterHandlers {
  CenterHandlers({required this.center, required this.clock})
    : _placeOrder = PlaceOrder(orders: center),
      _confirmOrder = ConfirmOrder(orders: center, boards: center, clock: clock),
      _rejectOrder = RejectOrder(orders: center, clock: clock),
      _cancelOrder = CancelOrder(orders: center, clock: clock),
      _getCenterBoard = GetCenterBoard(boards: center),
      _getOpeningHours = GetOpeningHours(center: center);

  final PostgresCenter center;
  final Clock clock;
  final PlaceOrder _placeOrder;
  final ConfirmOrder _confirmOrder;
  final RejectOrder _rejectOrder;
  final CancelOrder _cancelOrder;
  final GetCenterBoard _getCenterBoard;
  final GetOpeningHours _getOpeningHours;

  Future<Response> openingHours(Request request) async => json(200, (await _getOpeningHours()).toDto().toJson());

  Future<Response> board(Request request) async {
    if (!AccessPolicy.canViewBoard(_actor(request))) return problem(const NotAllowed());
    return json(200, (await _getCenterBoard()).toDto().toJson());
  }

  Future<Response> ordersOfOwner(Request request) async {
    final actor = _actor(request);
    final orders = await center.ordersOf(UserId(request.rawPathParameters[#ownerId]!));
    return json(200, [
      for (final order in orders)
        if (AccessPolicy.canView(actor, order)) order.toDto().toJson(),
    ]);
  }

  Future<Response> petsOfOwner(Request request) async {
    final actor = _actor(request);
    final pets = await center.petsOf(UserId(request.rawPathParameters[#ownerId]!));
    return json(200, [
      for (final pet in pets)
        if (AccessPolicy.canViewPet(actor, pet)) pet.toDto().toJson(),
    ]);
  }

  Future<Response> find(Request request) async {
    final order = await center.find(OrderId(request.rawPathParameters[#id]!));
    if (order == null || !AccessPolicy.canView(_actor(request), order)) return problem(const NotFound());
    return json(200, order.toDto().toJson());
  }

  /// The client sends what the owner chose; the stay, the period and the note are decided again here,
  /// by the same domain functions and with the server's clock.
  Future<Response> create(Request request) async {
    final actor = _actor(request);
    final body = NewOrderDto.fromJson(await readObject(request));
    final pet = await center.pet(PetId(body.petId));
    if (pet == null || !AccessPolicy.canViewPet(actor, pet)) return problem(const NotFound());
    if (!AccessPolicy.canPlaceOrder(actor, pet)) return problem(const NotAllowed());
    final service = serviceTypeFromDto(body.service);
    final nights = service.needsKennel ? StayLength.parse(body.nights ?? 0) : const Success(StayLength.shortest);
    if (nights case Failure(:final error)) return problem(error);
    final period = ServicePeriod.parse(
      body.start,
      service: service,
      now: clock.now(),
      openingHours: await _getOpeningHours(),
      nights: nights.valueOrNull!,
    );
    if (period case Failure(:final error)) return problem(error);
    final note = OrderNote.parse(body.note ?? '');
    if (note case Failure(:final error)) return problem(error);
    final created = await _placeOrder(
      OrderRequest(
        owner: actor,
        pet: pet,
        service: service,
        period: period.valueOrNull!,
        note: note.valueOrNull!.isEmpty ? null : note.valueOrNull,
      ),
    );
    return respond(created, status: 201);
  }

  Future<Response> confirm(Request request) => _change(request, (id, actor) => _confirmOrder(id: id, by: actor));

  Future<Response> reject(Request request) => _change(request, (id, actor) async {
    final body = ReasonDto.fromJson(await readObject(request));
    return _rejectOrder(id: id, by: actor, reason: body.reason);
  });

  Future<Response> cancel(Request request) => _change(request, (id, actor) async {
    final body = ReasonDto.fromJson(await readObject(request));
    return _cancelOrder(id: id, by: actor, reason: body.reason);
  });

  Future<Response> _change(
    Request request,
    Future<Result<ServiceOrder>> Function(OrderId id, User actor) change,
  ) async => respond(await change(OrderId(request.rawPathParameters[#id]!), _actor(request)));

  User _actor(Request request) => currentSession.get(request).user;
}
