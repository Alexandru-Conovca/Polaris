# SQLite setup. The database file is created automatically on first start.
#
# To add your own entity: add a CREATE TABLE below, then copy the pattern
# of app/notes.py for its routes.

import sqlite3
from datetime import datetime, timezone
from pathlib import Path

# The project folder (the one holding requirements.txt), regardless of the
# current working directory — so app.db always lands in the same place.
BASE_DIR = Path(__file__).resolve().parent.parent

_SCHEMA = """
CREATE TABLE IF NOT EXISTS users (
  id            INTEGER PRIMARY KEY AUTOINCREMENT,
  email         TEXT    NOT NULL UNIQUE,
  password_hash TEXT    NOT NULL,
  name          TEXT    NOT NULL,
  created_at    TEXT    NOT NULL
);

CREATE TABLE IF NOT EXISTS notes (
  id         INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id    INTEGER NOT NULL REFERENCES users (id),
  title      TEXT    NOT NULL,
  content    TEXT    NOT NULL DEFAULT '',
  created_at TEXT    NOT NULL
);

CREATE TABLE IF NOT EXISTS files (
  id         INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id    INTEGER NOT NULL REFERENCES users (id),
  name       TEXT    NOT NULL,
  mime_type  TEXT    NOT NULL,
  size       INTEGER NOT NULL,
  path       TEXT    NOT NULL,
  created_at TEXT    NOT NULL
);

CREATE TABLE IF NOT EXISTS celestial_objects (
  id              INTEGER PRIMARY KEY AUTOINCREMENT,
  name            TEXT    NOT NULL,
  type            TEXT    NOT NULL,
  description     TEXT    NOT NULL DEFAULT '',
  magnitude       REAL    NOT NULL,
  coordinates     TEXT    NOT NULL,
  constellation   TEXT    NOT NULL,
  is_visible_now  INTEGER NOT NULL DEFAULT 0,
  created_at      TEXT    NOT NULL
);

CREATE TABLE IF NOT EXISTS quests (
  id           INTEGER PRIMARY KEY AUTOINCREMENT,
  title        TEXT    NOT NULL,
  description  TEXT    NOT NULL DEFAULT '',
  difficulty   TEXT    NOT NULL,
  tasks_count  INTEGER NOT NULL,
  created_at   TEXT    NOT NULL
);

CREATE TABLE IF NOT EXISTS telescopes (
  id            INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id       INTEGER NOT NULL REFERENCES users (id) ON DELETE CASCADE,
  name          TEXT    NOT NULL,
  aperture      INTEGER NOT NULL,
  focal_length  INTEGER NOT NULL,
  mount_type    TEXT    NOT NULL,
  created_at    TEXT    NOT NULL
);

CREATE TABLE IF NOT EXISTS observations (
  id                  INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id             INTEGER NOT NULL REFERENCES users (id) ON DELETE CASCADE,
  celestial_object_id INTEGER NOT NULL REFERENCES celestial_objects (id),
  quest_id            INTEGER NOT NULL REFERENCES quests (id),
  telescope_id        INTEGER REFERENCES telescopes (id) ON DELETE SET NULL,
  observed_at         TEXT    NOT NULL,
  location            TEXT    NOT NULL,
  status              TEXT    NOT NULL,
  created_at          TEXT    NOT NULL
);

CREATE TABLE IF NOT EXISTS favorites (
  user_id             INTEGER NOT NULL REFERENCES users (id) ON DELETE CASCADE,
  celestial_object_id INTEGER NOT NULL REFERENCES celestial_objects (id) ON DELETE CASCADE,
  created_at          TEXT    NOT NULL,
  PRIMARY KEY (user_id, celestial_object_id)
);
"""

# The single database connection, opened (and the schema applied) at import
# time. All route handlers are `async def`, so they all run on the event
# loop's single thread — one shared connection is safe here.
# isolation_level=None = autocommit: every INSERT/UPDATE/DELETE is written
# to disk immediately, which is what gives persistence across restarts.
conn = sqlite3.connect(
    BASE_DIR / "app.db", check_same_thread=False, isolation_level=None
)
conn.row_factory = sqlite3.Row  # rows behave like dicts: row["title"]
conn.execute("PRAGMA foreign_keys = ON")
conn.executescript(_SCHEMA)


def now_iso():
    """Current UTC time in ISO-8601, the format used for all timestamps."""
    return (
        datetime.now(timezone.utc)
        .isoformat(timespec="milliseconds")
        .replace("+00:00", "Z")
    )
