from fastapi import APIRouter, Depends, Request, Response

from .auth import require_auth
from .db import conn, now_iso
from .domain_helpers import pagination, required_foreign_id
from .errors import json_response, not_found, read_json_body, string_field, validation_error

router = APIRouter()


def _to_json(row) -> dict:
    return {
        "id": row["id"],
        "objectId": row["celestial_object_id"],
        "objectName": row["object_name"],
        "questId": row["quest_id"],
        "questTitle": row["quest_title"],
        "telescopeId": row["telescope_id"],
        "observedAt": row["observed_at"],
        "location": row["location"],
        "status": row["status"],
        "createdAt": row["created_at"],
    }


_SELECT = """
SELECT observations.*, celestial_objects.name AS object_name,
       quests.title AS quest_title
FROM observations
JOIN celestial_objects ON celestial_objects.id = observations.celestial_object_id
JOIN quests ON quests.id = observations.quest_id
"""


def _find(user_id: int, observation_id: str):
    try:
        parsed_id = int(observation_id)
    except (TypeError, ValueError):
        return None
    return conn.execute(
        _SELECT + " WHERE observations.id = ? AND observations.user_id = ?",
        (parsed_id, user_id),
    ).fetchone()


def _reference_exists(table: str, record_id: int, user_id: int = None) -> bool:
    if table == "telescopes":
        return conn.execute(
            "SELECT 1 FROM telescopes WHERE id = ? AND user_id = ?",
            (record_id, user_id),
        ).fetchone() is not None
    return conn.execute(
        "SELECT 1 FROM " + table + " WHERE id = ?", (record_id,)
    ).fetchone() is not None


def _read_body(body: dict, user_id: int) -> tuple:
    object_id = required_foreign_id(body, "objectId")
    quest_id = required_foreign_id(body, "questId")
    telescope_value = body.get("telescopeId")
    telescope_id = None
    if telescope_value is not None:
        telescope_id = required_foreign_id(body, "telescopeId")
    observed_at = string_field(body, "observedAt")
    location = string_field(body, "location")
    status = string_field(body, "status")
    if observed_at is None or location is None or status is None:
        raise validation_error("observedAt, location, and status are required")
    if not _reference_exists("celestial_objects", object_id):
        raise validation_error("objectId references an unknown celestial object")
    if not _reference_exists("quests", quest_id):
        raise validation_error("questId references an unknown quest")
    if telescope_id is not None and not _reference_exists("telescopes", telescope_id, user_id):
        raise validation_error("telescopeId references an unknown telescope")
    return object_id, quest_id, telescope_id, observed_at, location, status


@router.get("/observations")
async def list_observations(request: Request, user_id: int = Depends(require_auth)):
    page, limit, search = pagination(request)
    pattern = "%" + search + "%"
    args = (user_id, pattern, pattern, pattern, pattern)
    where = (
        "observations.user_id = ? AND "
        "(celestial_objects.name LIKE ? OR quests.title LIKE ? "
        "OR observations.location LIKE ? OR observations.status LIKE ?)"
    )
    total = conn.execute(
        "SELECT COUNT(*) AS n FROM observations "
        "JOIN celestial_objects ON celestial_objects.id = observations.celestial_object_id "
        "JOIN quests ON quests.id = observations.quest_id WHERE " + where,
        args,
    ).fetchone()["n"]
    rows = conn.execute(
        _SELECT + " WHERE " + where
        + " ORDER BY observations.id DESC LIMIT ? OFFSET ?",
        args + (limit, (page - 1) * limit),
    ).fetchall()
    return json_response(
        {"items": [_to_json(row) for row in rows], "page": page, "limit": limit, "total": total}
    )


@router.post("/observations")
async def create_observation(request: Request, user_id: int = Depends(require_auth)):
    body = await read_json_body(request)
    if body is None:
        raise validation_error("Body must be a JSON object")
    values = _read_body(body, user_id)
    cursor = conn.execute(
        "INSERT INTO observations "
        "(user_id, celestial_object_id, quest_id, telescope_id, observed_at, location, status, created_at) "
        "VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
        (user_id,) + values + (now_iso(),),
    )
    return json_response(
        _to_json(_find(user_id, str(cursor.lastrowid))), status=201
    )


@router.get("/observations/{observation_id}")
async def get_observation(
    observation_id: str, user_id: int = Depends(require_auth)
):
    row = _find(user_id, observation_id)
    if row is None:
        raise not_found("Observation not found")
    return json_response(_to_json(row))


@router.put("/observations/{observation_id}")
async def update_observation(
    observation_id: str, request: Request, user_id: int = Depends(require_auth)
):
    row = _find(user_id, observation_id)
    if row is None:
        raise not_found("Observation not found")
    body = await read_json_body(request)
    if body is None:
        raise validation_error("Body must be a JSON object")
    values = _read_body(body, user_id)
    conn.execute(
        "UPDATE observations SET celestial_object_id=?, quest_id=?, telescope_id=?, "
        "observed_at=?, location=?, status=? WHERE id=? AND user_id=?",
        values + (row["id"], user_id),
    )
    return json_response(_to_json(_find(user_id, observation_id)))


@router.delete("/observations/{observation_id}")
async def delete_observation(
    observation_id: str, user_id: int = Depends(require_auth)
):
    row = _find(user_id, observation_id)
    if row is None:
        raise not_found("Observation not found")
    conn.execute("DELETE FROM observations WHERE id = ?", (row["id"],))
    return Response(status_code=204)
