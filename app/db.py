import sqlite3

from flask import Flask, current_app, g

SCHEMA = """
CREATE TABLE IF NOT EXISTS assets (
    id INTEGER PRIMARY KEY,
    hostname TEXT NOT NULL,
    owner TEXT NOT NULL,
    criticality TEXT NOT NULL
);
"""

SEED = [
    ("web-01", "platform", "high"),
    ("db-01", "platform", "critical"),
    ("ci-runner", "devops", "medium"),
]


def get_db() -> sqlite3.Connection:
    if "db" not in g:
        g.db = sqlite3.connect(current_app.config["DATABASE"])
        g.db.row_factory = sqlite3.Row
        g.db.executescript(SCHEMA)
        if g.db.execute("SELECT COUNT(*) FROM assets").fetchone()[0] == 0:
            g.db.executemany(
                "INSERT INTO assets (hostname, owner, criticality) VALUES (?, ?, ?)", SEED
            )
    return g.db


def close_db(_exc: BaseException | None = None) -> None:
    conn = g.pop("db", None)
    if conn is not None:
        conn.close()


def init_app(app: Flask) -> None:
    app.teardown_appcontext(close_db)
