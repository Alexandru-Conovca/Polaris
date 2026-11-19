from fastapi import APIRouter, Depends, Request, Response

from .auth import require_auth
from .db import conn, now_iso
from .domain_helpers import boolean_field, float_field, pagination
from .errors import (
    json_response,
    not_found,
    read_json_body,
    string_field,
    validation_error,
)

router = APIRouter()


def _to_json(row) -> dict:
    return {
        "id": row["id"],
        "name": row["name"],
        "type": row["type"],
        "description": row["description"],
        "magnitude": row["magnitude"],
        "coordinates": row["coordinates"],
        "constellation": row["constellation"],
        "isVisibleNow": bool(row["is_visible_now"]),
        "createdAt": row["created_at"],
    }


def _find(object_id: str):
    try:
        parsed_id = int(object_id)
    except (TypeError, ValueError):
        return None
    return conn.execute(
        "SELECT * FROM celestial_objects WHERE id = ?", (parsed_id,)
    ).fetchone()


def _read_body(body: dict) -> tuple:
    values = {
        "name": string_field(body, "name"),
        "type": string_field(body, "type"),
        "description": body.get("description", ""),
        "magnitude": float_field(body, "magnitude"),
        "coordinates": string_field(body, "coordinates"),
        "constellation": string_field(body, "constellation"),
        "is_visible_now": boolean_field(body, "isVisibleNow"),
    }
    if values["name"] is None or values["type"] is None:
        raise validation_error("name and type are required")
    if not isinstance(values["description"], str):
        raise validation_error("description must be a string")
    if values["magnitude"] is None:
        raise validation_error("magnitude must be a number")
    if values["coordinates"] is None or values["constellation"] is None:
        raise validation_error("coordinates and constellation are required")
    if values["is_visible_now"] is None:
        raise validation_error("isVisibleNow must be a boolean")
    return (
        values["name"],
        values["type"],
        values["description"],
        values["magnitude"],
        values["coordinates"],
        values["constellation"],
        int(values["is_visible_now"]),
    )


@router.get("/celestial-objects")
async def list_objects(request: Request, user_id: int = Depends(require_auth)):
    page, limit, search = pagination(request)
    pattern = "%" + search + "%"
    where = "name LIKE ? OR type LIKE ? OR constellation LIKE ?"
    args = (pattern, pattern, pattern)
    total = conn.execute(
        "SELECT COUNT(*) AS n FROM celestial_objects WHERE " + where, args
    ).fetchone()["n"]
    rows = conn.execute(
        "SELECT * FROM celestial_objects WHERE " + where
        + " ORDER BY id DESC LIMIT ? OFFSET ?",
        args + (limit, (page - 1) * limit),
    ).fetchall()
    return json_response(
        {"items": [_to_json(row) for row in rows], "page": page, "limit": limit, "total": total}
    )


@router.post("/celestial-objects")
async def create_object(request: Request, user_id: int = Depends(require_auth)):
    body = await read_json_body(request)
    if body is None:
        raise validation_error("Body must be a JSON object")
    values = _read_body(body)
    cursor = conn.execute(
        "INSERT INTO celestial_objects "
        "(name, type, description, magnitude, coordinates, constellation, is_visible_now, created_at) "
        "VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
        values + (now_iso(),),
    )
    return json_response(_to_json(_find(str(cursor.lastrowid))), status=201)


@router.get("/celestial-objects/{object_id}")
async def get_object(object_id: str, user_id: int = Depends(require_auth)):
    row = _find(object_id)
    if row is None:
        raise not_found("Celestial object not found")
    return json_response(_to_json(row))


@router.put("/celestial-objects/{object_id}")
async def update_object(
    object_id: str, request: Request, user_id: int = Depends(require_auth)
):
    row = _find(object_id)
    if row is None:
        raise not_found("Celestial object not found")
    body = await read_json_body(request)
    if body is None:
        raise validation_error("Body must be a JSON object")
    values = _read_body(body)
    conn.execute(
        "UPDATE celestial_objects SET name=?, type=?, description=?, magnitude=?, "
        "coordinates=?, constellation=?, is_visible_now=? WHERE id=?",
        values + (row["id"],),
    )
    return json_response(_to_json(_find(object_id)))


@router.delete("/celestial-objects/{object_id}")
async def delete_object(object_id: str, user_id: int = Depends(require_auth)):
    row = _find(object_id)
    if row is None:
        raise not_found("Celestial object not found")
    conn.execute("DELETE FROM celestial_objects WHERE id = ?", (row["id"],))
    return Response(status_code=204)
