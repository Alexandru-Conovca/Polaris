from fastapi import APIRouter, Depends, Request, Response

from .auth import require_auth
from .db import conn, now_iso
from .domain_helpers import pagination, positive_int_field
from .errors import json_response, not_found, read_json_body, string_field, validation_error

router = APIRouter()


def _to_json(row) -> dict:
    return {
        "id": row["id"],
        "name": row["name"],
        "aperture": row["aperture"],
        "focalLength": row["focal_length"],
        "mountType": row["mount_type"],
        "createdAt": row["created_at"],
    }


def _find(user_id: int, telescope_id: str):
    try:
        parsed_id = int(telescope_id)
    except (TypeError, ValueError):
        return None
    return conn.execute(
        "SELECT * FROM telescopes WHERE id = ? AND user_id = ?",
        (parsed_id, user_id),
    ).fetchone()


def _read_body(body: dict) -> tuple:
    name = string_field(body, "name")
    mount_type = string_field(body, "mountType")
    aperture = positive_int_field(body, "aperture")
    focal_length = positive_int_field(body, "focalLength")
    if name is None or mount_type is None:
        raise validation_error("name and mountType are required")
    if aperture is None or focal_length is None:
        raise validation_error("aperture and focalLength must be positive integers")
    return name, aperture, focal_length, mount_type


@router.get("/telescopes")
async def list_telescopes(request: Request, user_id: int = Depends(require_auth)):
    page, limit, search = pagination(request)
    pattern = "%" + search + "%"
    args = (user_id, pattern, pattern)
    where = "user_id = ? AND (name LIKE ? OR mount_type LIKE ?)"
    total = conn.execute(
        "SELECT COUNT(*) AS n FROM telescopes WHERE " + where, args
    ).fetchone()["n"]
    rows = conn.execute(
        "SELECT * FROM telescopes WHERE " + where
        + " ORDER BY id DESC LIMIT ? OFFSET ?",
        args + (limit, (page - 1) * limit),
    ).fetchall()
    return json_response(
        {"items": [_to_json(row) for row in rows], "page": page, "limit": limit, "total": total}
    )


@router.post("/telescopes")
async def create_telescope(request: Request, user_id: int = Depends(require_auth)):
    body = await read_json_body(request)
    if body is None:
        raise validation_error("Body must be a JSON object")
    values = _read_body(body)
    cursor = conn.execute(
        "INSERT INTO telescopes (user_id, name, aperture, focal_length, mount_type, created_at) "
        "VALUES (?, ?, ?, ?, ?, ?)",
        (user_id,) + values + (now_iso(),),
    )
    return json_response(_to_json(_find(user_id, str(cursor.lastrowid))), status=201)


@router.get("/telescopes/{telescope_id}")
async def get_telescope(telescope_id: str, user_id: int = Depends(require_auth)):
    row = _find(user_id, telescope_id)
    if row is None:
        raise not_found("Telescope not found")
    return json_response(_to_json(row))


@router.put("/telescopes/{telescope_id}")
async def update_telescope(
    telescope_id: str, request: Request, user_id: int = Depends(require_auth)
):
    row = _find(user_id, telescope_id)
    if row is None:
        raise not_found("Telescope not found")
    body = await read_json_body(request)
    if body is None:
        raise validation_error("Body must be a JSON object")
    values = _read_body(body)
    conn.execute(
        "UPDATE telescopes SET name=?, aperture=?, focal_length=?, mount_type=? "
        "WHERE id=? AND user_id=?",
        values + (row["id"], user_id),
    )
    return json_response(_to_json(_find(user_id, telescope_id)))


@router.delete("/telescopes/{telescope_id}")
async def delete_telescope(telescope_id: str, user_id: int = Depends(require_auth)):
    row = _find(user_id, telescope_id)
    if row is None:
        raise not_found("Telescope not found")
    conn.execute("DELETE FROM telescopes WHERE id = ?", (row["id"],))
    return Response(status_code=204)
