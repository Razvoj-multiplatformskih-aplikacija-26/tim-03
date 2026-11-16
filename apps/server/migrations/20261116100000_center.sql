-- migrate:up
CREATE EXTENSION IF NOT EXISTS btree_gist;

CREATE TABLE users (
  id text PRIMARY KEY,
  name text NOT NULL,
  role text NOT NULL CHECK (role IN ('owner', 'caretaker', 'veterinarian', 'walker', 'manager')),
  login text UNIQUE,
  password_hash text
);

CREATE TABLE pets (
  id text PRIMARY KEY,
  owner_id text NOT NULL REFERENCES users (id),
  name text NOT NULL,
  species text NOT NULL CHECK (species IN ('dog', 'cat')),
  size text NOT NULL CHECK (size IN ('small', 'medium', 'large'))
);

CREATE TABLE kennels (
  id text PRIMARY KEY,
  label text NOT NULL UNIQUE,
  size text NOT NULL CHECK (size IN ('small', 'medium', 'large'))
);

CREATE TABLE opening_hours (
  weekday int PRIMARY KEY CHECK (weekday BETWEEN 1 AND 7),
  opens time NOT NULL,
  closes time NOT NULL,
  CHECK (closes > opens)
);

-- Only the current state is kept, as in the domain: status_by and status_at belong to it,
-- status_reason only to a rejection or a cancellation.
CREATE TABLE orders (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id text NOT NULL REFERENCES users (id),
  pet_id text NOT NULL REFERENCES pets (id),
  service text NOT NULL CHECK (service IN ('boarding', 'grooming', 'vet_checkup', 'walk')),
  starts_at timestamptz NOT NULL,
  ends_at timestamptz NOT NULL,
  -- The end plus the walker's travel time for a walk (walkTravelTime in the domain), otherwise the end.
  -- The server writes it from the domain's constant, so the rule has one number.
  busy_until timestamptz NOT NULL,
  note text,
  kennel_id text REFERENCES kennels (id),
  assignee_id text REFERENCES users (id),
  status text NOT NULL CHECK (
    status IN ('pending', 'confirmed', 'in_progress', 'ready_for_pickup', 'completed', 'rejected', 'cancelled')
  ),
  status_by text REFERENCES users (id),
  status_at timestamptz,
  status_reason text,
  created_at timestamptz NOT NULL,
  CHECK (ends_at > starts_at),
  CHECK (busy_until >= ends_at),
  -- R6: the same pet has no two active orders that overlap.
  CONSTRAINT orders_pet_not_double_booked EXCLUDE USING gist (
    pet_id WITH =,
    tstzrange(starts_at, ends_at) WITH &&
  ) WHERE (status IN ('pending', 'confirmed', 'in_progress', 'ready_for_pickup')),
  -- R7: one pet in a kennel at a time.
  CONSTRAINT orders_kennel_not_double_booked EXCLUDE USING gist (
    kennel_id WITH =,
    tstzrange(starts_at, ends_at) WITH &&
  ) WHERE (kennel_id IS NOT NULL AND status IN ('pending', 'confirmed', 'in_progress', 'ready_for_pickup')),
  -- R8: a staff member has no two appointments that overlap, a walker counting the travel time.
  CONSTRAINT orders_assignee_not_double_booked EXCLUDE USING gist (
    assignee_id WITH =,
    tstzrange(starts_at, busy_until) WITH &&
  ) WHERE (assignee_id IS NOT NULL AND status IN ('pending', 'confirmed', 'in_progress', 'ready_for_pickup'))
);

CREATE INDEX orders_by_owner ON orders (owner_id);
CREATE INDEX orders_by_start ON orders (starts_at);

-- migrate:down
DROP TABLE orders;
DROP TABLE opening_hours;
DROP TABLE kennels;
DROP TABLE pets;
DROP TABLE users;
