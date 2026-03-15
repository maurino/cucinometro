CREATE TABLE family_member (
    id      SERIAL PRIMARY KEY,
    name    TEXT NOT NULL UNIQUE
);
CREATE TYPE meal_kind AS ENUM ('lunch', 'dinner');
CREATE TABLE meal (
    id      SERIAL PRIMARY KEY,
    date    DATE NOT NULL,
    kind    meal_kind NOT NULL,
    CONSTRAINT meal_unique_per_day_kind UNIQUE (date, kind)
);
CREATE TABLE meal_participant (
    meal_id     INTEGER NOT NULL REFERENCES meal(id) ON DELETE CASCADE,
    member_id   INTEGER NOT NULL REFERENCES family_member(id) ON DELETE RESTRICT,
    PRIMARY KEY (meal_id, member_id)
);
CREATE TABLE dishwashing_assignment (
    id          SERIAL PRIMARY KEY,
    meal_id     INTEGER NOT NULL UNIQUE REFERENCES meal(id) ON DELETE CASCADE,
    member_id   INTEGER NOT NULL REFERENCES family_member(id) ON DELETE RESTRICT
);