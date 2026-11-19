from fastapi import APIRouter, Depends, Request, Response

from .auth import require_auth
from .db import conn, now_iso
from .domain_helpers import pagination, positive_int_field
from .errors import json_response, not_found, read_json_body, string_field, validation_error

router = APIRouter()


def _to_json(row) -> dict:
    return {
        "id": row["id"],
        "title": row["title"],
        "description": row["description"],
        "difficulty": row["difficulty"],
        "tasksCount": row["tasks_count"],
        "createdAt": row["created_at"],
    }


def _find(quest_id: str):
    try:
        parsed_id = int(quest_id)
    except (TypeError, ValueError):
        return None
    return conn.execute("SELECT * FROM quests WHERE id = ?", (parsed_id,)).fetchone()


def _read_body(body: dict) -> tuple:
    title = string_field(body, "title")
    difficulty = string_field(body, "difficulty")
    description = body.get("description", "")
    tasks_count = positive_int_field(body, "tasksCount")
    if title is None or difficulty is None:
        raise validation_error("title and difficulty are required")
    if not isinstance(description, str):
        raise validation_error("description must be a string")
    if tasks_count is None:
        raise validation_error("tasksCount must be a positive integer")
    return title, description, difficulty, tasks_count


@router.get("/quests")
async def list_quests(request: Request, user_id: int = Depends(require_auth)):
    page, limit, search = pagination(request)
    pattern = "%" + search + "%"
    args = (pattern, pattern, pattern)
    where = "title LIKE ? OR description LIKE ? OR difficulty LIKE ?"
    total = conn.execute(
        "SELECT COUNT(*) AS n FROM quests WHERE " + where, args
    ).fetchone()["n"]
    rows = conn.execute(
        "SELECT * FROM quests WHERE " + where
        + " ORDER BY id DESC LIMIT ? OFFSET ?",
        args + (limit, (page - 1) * limit),
    ).fetchall()
    return json_response(
        {"items": [_to_json(row) for row in rows], "page": page, "limit": limit, "total": total}
    )


@router.post("/quests")
async def create_quest(request: Request, user_id: int = Depends(require_auth)):
    body = await read_json_body(request)
    if body is None:
        raise validation_error("Body must be a JSON object")
    values = _read_body(body)
    cursor = conn.execute(
        "INSERT INTO quests (title, description, difficulty, tasks_count, created_at) "
        "VALUES (?, ?, ?, ?, ?)",
        values + (now_iso(),),
    )
    return json_response(_to_json(_find(str(cursor.lastrowid))), status=201)


@router.get("/quests/{quest_id}")
async def get_quest(quest_id: str, user_id: int = Depends(require_auth)):
    row = _find(quest_id)
    if row is None:
        raise not_found("Quest not found")
    return json_response(_to_json(row))


@router.put("/quests/{quest_id}")
async def update_quest(
    quest_id: str, request: Request, user_id: int = Depends(require_auth)
):
    row = _find(quest_id)
    if row is None:
        raise not_found("Quest not found")
    body = await read_json_body(request)
    if body is None:
        raise validation_error("Body must be a JSON object")
    values = _read_body(body)
    conn.execute(
        "UPDATE quests SET title=?, description=?, difficulty=?, tasks_count=? WHERE id=?",
        values + (row["id"],),
    )
    return json_response(_to_json(_find(quest_id)))


@router.delete("/quests/{quest_id}")
async def delete_quest(quest_id: str, user_id: int = Depends(require_auth)):
    row = _find(quest_id)
    if row is None:
        raise not_found("Quest not found")
    conn.execute("DELETE FROM quests WHERE id = ?", (row["id"],))
    return Response(status_code=204)
