from fastapi import APIRouter, Depends, Request, Response

from .auth import require_auth
from .db import conn, now_iso
from .domain_helpers import pagination
from .errors import json_response, not_found, validation_error

router = APIRouter()


def _to_json(row) -> dict:
    return {
        "id": row["id"],
        "objectId": row["celestial_object_id"],
        "object": {
            "id": row["celestial_object_id"],
            "name": row["name"],
            "type": row["type"],
            "description": row["description"],
            "magnitude": row["magnitude"],
            "coordinates": row["coordinates"],
            "constellation": row["constellation"],
            "isVisibleNow": bool(row["is_visible_now"]),
            "createdAt": row["object_created_at"],
        },
        "createdAt": row["created_at"],
    }


_SELECT = """
SELECT favorites.rowid AS id, favorites.celestial_object_id,
       favorites.created_at, celestial_objects.name,
       celestial_objects.type, celestial_objects.description,
       celestial_objects.magnitude, celestial_objects.coordinates,
       celestial_objects.constellation,
       celestial_objects.is_visible_now,
       celestial_objects.created_at AS object_created_at
FROM favorites
JOIN celestial_objects ON celestial_objects.id = favorites.celestial_object_id
"""


@router.get("/favorites")
async def list_favorites(request: Request, user_id: int = Depends(require_auth)):
    page, limit, search = pagination(request)
    pattern = "%" + search + "%"
    args = (user_id, pattern, pattern, pattern)
    where = (
        "favorites.user_id = ? AND "
        "(celestial_objects.name LIKE ? OR celestial_objects.type LIKE ? "
        "OR celestial_objects.constellation LIKE ?)"
    )
    total = conn.execute(
        "SELECT COUNT(*) AS n FROM favorites "
        "JOIN celestial_objects ON celestial_objects.id = favorites.celestial_object_id "
        "WHERE " + where,
        args,
    ).fetchone()["n"]
    rows = conn.execute(
        _SELECT + " WHERE " + where
        + " ORDER BY favorites.rowid DESC LIMIT ? OFFSET ?",
        args + (limit, (page - 1) * limit),
    ).fetchall()
    return json_response(
        {"items": [_to_json(row) for row in rows], "page": page, "limit": limit, "total": total}
    )


@router.post("/favorites/{object_id}")
async def add_favorite(object_id: str, user_id: int = Depends(require_auth)):
    try:
        parsed_id = int(object_id)
    except (TypeError, ValueError):
        raise validation_error("object_id must be a positive integer")
    if parsed_id <= 0:
        raise validation_error("object_id must be a positive integer")
    if conn.execute(
        "SELECT 1 FROM celestial_objects WHERE id = ?", (parsed_id,)
    ).fetchone() is None:
        raise not_found("Celestial object not found")
    if conn.execute(
        "SELECT 1 FROM favorites WHERE user_id = ? AND celestial_object_id = ?",
        (user_id, parsed_id),
    ).fetchone() is not None:
        raise validation_error("Celestial object is already a favorite")
    conn.execute(
        "INSERT INTO favorites (user_id, celestial_object_id, created_at) VALUES (?, ?, ?)",
        (user_id, parsed_id, now_iso()),
    )
    row = conn.execute(
        _SELECT + " WHERE favorites.user_id = ? AND favorites.celestial_object_id = ?",
        (user_id, parsed_id),
    ).fetchone()
    return json_response(_to_json(row), status=201)


@router.delete("/favorites/{object_id}")
async def remove_favorite(object_id: str, user_id: int = Depends(require_auth)):
    try:
        parsed_id = int(object_id)
    except (TypeError, ValueError):
        raise validation_error("object_id must be a positive integer")
    row = conn.execute(
        "SELECT 1 FROM favorites WHERE user_id = ? AND celestial_object_id = ?",
        (user_id, parsed_id),
    ).fetchone()
    if row is None:
        raise not_found("Favorite not found")
    conn.execute(
        "DELETE FROM favorites WHERE user_id = ? AND celestial_object_id = ?",
        (user_id, parsed_id),
    )
    return Response(status_code=204)
