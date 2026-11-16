import 'package:domain/domain.dart';
import 'package:postgres/postgres.dart';

const exclusionViolation = '23P01';
const _active = "status IN ('pending', 'confirmed', 'in_progress', 'ready_for_pickup')";

final class CenterStore {
  const CenterStore(this._database);

  final Session _database;

  Future<bool> isEmpty() async {
    final rows = await _database.execute('SELECT count(*) FROM users');
    return rows.single[0] == 0;
  }

  Future<OpeningHours> openingHours() async {
    final rows = await _database.execute(
      "SELECT weekday, to_char(opens, 'HH24:MI'), to_char(closes, 'HH24:MI') FROM opening_hours",
    );
    return OpeningHours({
      for (final row in rows)
        row[0]! as int: DayHours(open: _localTime(row[1]! as String), close: _localTime(row[2]! as String)),
    });
  }

  Future<List<Kennel>> kennels() async {
    final rows = await _database.execute('SELECT id, label, size FROM kennels ORDER BY label');
    return [
      for (final row in rows)
        Kennel(
          id: KennelId(row[0]! as String),
          label: row[1]! as String,
          size: PetSize.values.byName(row[2]! as String),
        ),
    ];
  }

  Future<List<User>> people() async {
    final rows = await _database.execute('SELECT id, name, role FROM users ORDER BY name');
    return [for (final row in rows) _user(row)];
  }

  Future<List<User>> staff() async {
    final rows = await _database.execute("SELECT id, name, role FROM users WHERE role <> 'owner' ORDER BY name");
    return [for (final row in rows) _user(row)];
  }

  Future<List<Pet>> pets() => _pets('true', const {});

  Future<List<Pet>> petsOf(UserId ownerId) => _pets('owner_id = @owner', {'owner': ownerId.value});

  Future<Pet?> pet(PetId id) async {
    final found = await _pets('id = @id', {'id': id.value});
    return found.isEmpty ? null : found.single;
  }

  Future<List<ServiceOrder>> orders() => _orders('true', const {});

  Future<List<ServiceOrder>> ordersOf(UserId ownerId) => _orders('owner_id = @owner', {'owner': ownerId.value});

  Future<ServiceOrder?> find(OrderId id) async {
    if (!_uuid.hasMatch(id.value)) return null;
    final found = await _orders('id = @id::uuid', {'id': id.value});
    return found.isEmpty ? null : found.single;
  }

  /// Active orders whose time, walker's travel included, comes near [period]: every order R6, R7 and R8 can
  /// collide with. The domain then decides exactly.
  Future<List<ServiceOrder>> activeOrdersAround(ServicePeriod period) => _orders(
    '$_active AND tstzrange(starts_at, busy_until) && tstzrange(@from, @to)',
    {'from': period.start.subtract(walkTravelTime), 'to': period.end.add(walkTravelTime)},
  );

  /// Stores a new order; the database gives it its id.
  Future<ServiceOrder> insert(ServiceOrder order) async {
    final (:kind, :by, :at, :reason) = _statusColumns(order.status);
    final rows = await _database.execute(
      Sql.named('''
        INSERT INTO orders
          (owner_id, pet_id, service, starts_at, ends_at, busy_until, note, kennel_id, assignee_id,
           status, status_by, status_at, status_reason, created_at)
        VALUES
          (@owner, @pet, @service, @starts, @ends, @busyUntil, @note, @kennel, @assignee,
           @status, @statusBy, @statusAt, @reason, @created)
        RETURNING id::text
      '''),
      parameters: {
        'owner': order.ownerId.value,
        'pet': order.petId.value,
        'service': _serviceColumn(order.service),
        'starts': order.period.start,
        'ends': order.period.end,
        'busyUntil': _busyUntil(order),
        'note': order.note?.text,
        'kennel': order.kennelId?.value,
        'assignee': order.assigneeId?.value,
        'status': kind,
        'statusBy': by,
        'statusAt': at,
        'reason': reason,
        'created': order.createdAt.toUtc(),
      },
    );
    return ServiceOrder(
      id: OrderId(rows.single[0]! as String),
      ownerId: order.ownerId,
      petId: order.petId,
      service: order.service,
      period: order.period,
      createdAt: order.createdAt.toUtc(),
      note: order.note,
      kennelId: order.kennelId,
      assigneeId: order.assigneeId,
      status: order.status,
    );
  }

  /// Writes the new state only if the stored order is still in [from]: two calls at the same time cannot both
  /// change it. False means someone changed the order in the meantime.
  Future<bool> changeStatus(ServiceOrder changed, {required OrderStatus from}) async {
    final (:kind, :by, :at, :reason) = _statusColumns(changed.status);
    final result = await _database.execute(
      Sql.named('''
        UPDATE orders
        SET status = @status, status_by = @statusBy, status_at = @statusAt, status_reason = @reason,
            kennel_id = @kennel, assignee_id = @assignee
        WHERE id = @id::uuid AND status = @previous
      '''),
      parameters: {
        'id': changed.id.value,
        'status': kind,
        'statusBy': by,
        'statusAt': at,
        'reason': reason,
        'kennel': changed.kennelId?.value,
        'assignee': changed.assigneeId?.value,
        'previous': _statusColumns(from).kind,
      },
    );
    return result.affectedRows == 1;
  }

  Future<List<Pet>> _pets(String where, Map<String, Object?> parameters) async {
    final rows = await _database.execute(
      Sql.named('SELECT id, owner_id, name, species, size FROM pets WHERE $where ORDER BY name'),
      parameters: parameters,
    );
    return [
      for (final row in rows)
        Pet(
          id: PetId(row[0]! as String),
          ownerId: UserId(row[1]! as String),
          name: row[2]! as String,
          species: Species.values.byName(row[3]! as String),
          size: PetSize.values.byName(row[4]! as String),
        ),
    ];
  }

  Future<List<ServiceOrder>> _orders(String where, Map<String, Object?> parameters) async {
    final rows = await _database.execute(
      Sql.named('''
        SELECT id::text, owner_id, pet_id, service, starts_at, ends_at, note, kennel_id, assignee_id,
               status, status_by, status_at, status_reason, created_at
        FROM orders
        WHERE $where
        ORDER BY starts_at
      '''),
      parameters: parameters,
    );
    return [for (final row in rows) _order(row.toColumnMap())];
  }
}

final _uuid = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');

/// R8 in the database: a walker is busy until the end plus the travel time from the domain, others until the end.
DateTime _busyUntil(ServiceOrder order) =>
    order.service == ServiceType.walk ? order.period.end.add(walkTravelTime) : order.period.end;

User _user(ResultRow row) =>
    User(id: UserId(row[0]! as String), name: row[1]! as String, role: Role.values.byName(row[2]! as String));

ServiceOrder _order(Map<String, dynamic> row) => ServiceOrder(
  id: OrderId(row['id'] as String),
  ownerId: UserId(row['owner_id'] as String),
  petId: PetId(row['pet_id'] as String),
  service: _service(row['service'] as String),
  period: ServicePeriod.existing(start: row['starts_at'] as DateTime, end: row['ends_at'] as DateTime),
  createdAt: (row['created_at'] as DateTime).toUtc(),
  note: switch (row['note']) {
    final String text => OrderNote.parse(text).valueOrNull,
    _ => null,
  },
  kennelId: switch (row['kennel_id']) {
    final String id => KennelId(id),
    _ => null,
  },
  assigneeId: switch (row['assignee_id']) {
    final String id => UserId(id),
    _ => null,
  },
  status: _status(row),
);

OrderStatus _status(Map<String, dynamic> row) {
  final at = (row['status_at'] as DateTime?)?.toUtc();
  final by = row['status_by'] as String?;
  final reason = row['status_reason'] as String? ?? '';
  return switch (row['status']) {
    'confirmed' => Confirmed(confirmedBy: UserId(by!), at: at!),
    'in_progress' => InProgress(receivedBy: UserId(by!), at: at!),
    'ready_for_pickup' => ReadyForPickup(at: at!),
    'completed' => Completed(at: at!),
    'rejected' => Rejected(reason: reason, rejectedBy: UserId(by!), at: at!),
    'cancelled' => Cancelled(reason: reason, cancelledBy: UserId(by!), at: at!),
    _ => const Pending(),
  };
}

({String kind, String? by, DateTime? at, String? reason}) _statusColumns(OrderStatus status) => switch (status) {
  Pending() => (kind: 'pending', by: null, at: null, reason: null),
  Confirmed(:final confirmedBy, :final at) => (kind: 'confirmed', by: confirmedBy.value, at: at, reason: null),
  InProgress(:final receivedBy, :final at) => (kind: 'in_progress', by: receivedBy.value, at: at, reason: null),
  ReadyForPickup(:final at) => (kind: 'ready_for_pickup', by: null, at: at, reason: null),
  Completed(:final at) => (kind: 'completed', by: null, at: at, reason: null),
  Rejected(:final reason, :final rejectedBy, :final at) => (
    kind: 'rejected',
    by: rejectedBy.value,
    at: at,
    reason: reason,
  ),
  Cancelled(:final reason, :final cancelledBy, :final at) => (
    kind: 'cancelled',
    by: cancelledBy.value,
    at: at,
    reason: reason,
  ),
};

ServiceType _service(String column) => switch (column) {
  'boarding' => ServiceType.boarding,
  'grooming' => ServiceType.grooming,
  'vet_checkup' => ServiceType.vetCheckup,
  'walk' => ServiceType.walk,
  _ => throw StateError('Unknown service in the database: $column'),
};

String _serviceColumn(ServiceType service) => switch (service) {
  ServiceType.boarding => 'boarding',
  ServiceType.grooming => 'grooming',
  ServiceType.vetCheckup => 'vet_checkup',
  ServiceType.walk => 'walk',
};

LocalTime _localTime(String value) {
  final [hour, minute] = value.split(':');
  return LocalTime(int.parse(hour), int.parse(minute));
}
