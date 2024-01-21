CREATE TABLE lists (
  id serial PRIMARY KEY,
  name text NOT NULL UNIQUE
);

CREATE TABLE todos (
  id serial PRIMARY KEY,
  name text NOT NULL,
  list_id int NOT NULL REFERENCES lists(id),
  completed boolean DEFAULT false
);