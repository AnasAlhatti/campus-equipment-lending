CREATE TABLE students (
    student_id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name text NOT NULL CHECK (btrim(name) <> ''),
    email text NOT NULL UNIQUE
);

CREATE TABLE equipment (
    equipment_id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name text NOT NULL CHECK (btrim(name) <> ''),
    asset_tag text NOT NULL UNIQUE
);

CREATE TABLE checkouts (
    checkout_id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    student_id integer NOT NULL REFERENCES students (student_id),
    checked_out_at date NOT NULL,
    due_on date NOT NULL,
    CONSTRAINT checkout_due_date CHECK (due_on >= checked_out_at)
);

CREATE TABLE checkout_items (
    checkout_id integer REFERENCES checkouts (checkout_id) ON DELETE CASCADE,
    equipment_id integer REFERENCES equipment (equipment_id),
    PRIMARY KEY (checkout_id, equipment_id)
);
