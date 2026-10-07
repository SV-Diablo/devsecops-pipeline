from flask import Blueprint, abort, jsonify, request

from .db import get_db

bp = Blueprint("assets", __name__)

ALLOWED_CRITICALITY = {"low", "medium", "high", "critical"}


@bp.get("/health")
def health():
    return jsonify(status="ok")


@bp.get("/assets")
def list_assets():
    owner = request.args.get("owner", "")
    # Parameterized query: user input never becomes part of the SQL text.
    rows = get_db().execute(
        "SELECT id, hostname, owner, criticality FROM assets WHERE owner = ?", (owner,)
    ).fetchall()
    return jsonify([dict(r) for r in rows])


@bp.get("/assets/by-criticality/<level>")
def by_criticality(level: str):
    # Allow-list validation before the value reaches the database.
    if level not in ALLOWED_CRITICALITY:
        abort(400, description="invalid criticality")
    rows = get_db().execute(
        "SELECT id, hostname, owner, criticality FROM assets WHERE criticality = ?", (level,)
    ).fetchall()
    return jsonify([dict(r) for r in rows])
