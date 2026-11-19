from typing import Optional, Tuple

from .errors import validation_error


def int_or(value: Optional[str], default: int) -> int:
    try:
        return int(value)
    except (TypeError, ValueError):
        return default


def float_field(body: dict, key: str) -> Optional[float]:
    value = body.get(key)
    if isinstance(value, bool):
        return None
    try:
        return float(value)
    except (TypeError, ValueError):
        return None


def positive_int_field(body: dict, key: str) -> Optional[int]:
    value = body.get(key)
    if isinstance(value, bool):
        return None
    try:
        parsed = int(value)
    except (TypeError, ValueError):
        return None
    return parsed if parsed > 0 else None


def boolean_field(body: dict, key: str) -> Optional[bool]:
    value = body.get(key)
    return value if isinstance(value, bool) else None


def pagination(request) -> Tuple[int, int, str]:
    query = request.query_params
    page = max(int_or(query.get("page"), 1), 1)
    limit = min(max(int_or(query.get("limit"), 20), 1), 100)
    return page, limit, query.get("search", "")


def required_foreign_id(body: dict, key: str) -> int:
    value = positive_int_field(body, key)
    if value is None:
        raise validation_error(key + " must be a positive integer")
    return value
