import os
import re
from datetime import date
from typing import Literal

import requests
from mcp.server.fastmcp import FastMCP

API_BASE_URL = os.getenv("CUCINOMETRO_API_BASE_URL", "http://host.docker.internal:8000/api").rstrip("/")
REQUEST_TIMEOUT_SECONDS = float(os.getenv("REQUEST_TIMEOUT_SECONDS", "10"))
DEFAULT_FAMILY_MEMBERS = [
    "mauro",
    "daniela",
    "silvia",
    "claudia",
    "alessandra",
    "giulia",
    "francesco",
]

mcp = FastMCP("cucinometro-mcp")
mcp.settings.host = os.getenv("MCP_HOST", "0.0.0.0")
mcp.settings.port = int(os.getenv("MCP_PORT", "8080"))
mcp.settings.streamable_http_path = os.getenv("MCP_HTTP_PATH", "/mcp")


def _known_family_members() -> list[str]:
    raw = os.getenv("FAMILY_MEMBERS", "")
    if not raw.strip():
        return DEFAULT_FAMILY_MEMBERS[:]

    members = [name.strip().lower() for name in raw.split(",") if name.strip()]
    return members or DEFAULT_FAMILY_MEMBERS[:]


def _extract_participants_from_text(text: str, requester_name: str | None = None) -> list[str]:
    lowered_text = text.lower()
    participants: list[str] = []

    # Recognize known family members as whole words.
    for name in _known_family_members():
        pattern = r"\b" + re.escape(name) + r"\b"
        if re.search(pattern, lowered_text):
            participants.append(name)

    # Optional support for "io" when the caller provides who is asking.
    if re.search(r"\bio\b", lowered_text):
        if requester_name and requester_name.strip():
            participants.append(requester_name.strip())
        else:
            raise ValueError(
                "Found 'io' in the sentence but requester_name was not provided"
            )

    return _normalize_participants(participants)


def _normalize_participants(participants: list[str]) -> list[str]:
    cleaned: list[str] = []
    seen: set[str] = set()
    for raw in participants:
        name = raw.strip()
        if not name:
            continue
        lowered = name.lower()
        if lowered in seen:
            continue
        seen.add(lowered)
        cleaned.append(name)
    return cleaned


@mcp.tool()
def choose_dishwasher(
    participants: list[str],
    meal_kind: Literal["lunch", "dinner"] = "dinner",
    meal_date: str | None = None,
    explain: bool = True,
) -> dict:
    """Decide chi lava i piatti usando l'algoritmo del Cucinometro.

    Args:
        participants: Nomi dei partecipanti al pasto corrente.
        meal_kind: lunch oppure dinner.
        meal_date: Data ISO (YYYY-MM-DD). Se omessa usa la data di oggi.
        explain: Se true, include la spiegazione dettagliata della scelta.

    Returns:
        Risposta strutturata con lavapiatti scelto, statistiche e spiegazione.
    """
    normalized = _normalize_participants(participants)
    if not normalized:
        raise ValueError("At least one participant is required")

    payload = {
        "date": meal_date or date.today().isoformat(),
        "kind": meal_kind,
        "participants": normalized,
        "explain": explain,
    }

    endpoint = f"{API_BASE_URL}/meals/decide-dishwasher"
    try:
        response = requests.post(endpoint, json=payload, timeout=REQUEST_TIMEOUT_SECONDS)
    except requests.RequestException as exc:
        raise RuntimeError(f"Unable to reach Cucinometro API at {endpoint}: {exc}") from exc

    if not response.ok:
        detail = response.text
        try:
            detail = response.json()
        except ValueError:
            pass
        raise RuntimeError(f"Cucinometro API error ({response.status_code}): {detail}")

    data = response.json()
    explanation_text = None
    if data.get("explanation"):
        explanation_text = data["explanation"].get("explanation")

    return {
        "dishwasher": data.get("dishwasher"),
        "meal": data.get("meal"),
        "stats": data.get("stats"),
        "explanation": explanation_text,
        "api_base_url": API_BASE_URL,
    }


@mcp.tool()
def choose_dishwasher_from_text(
    question_text: str,
    requester_name: str | None = None,
    meal_kind: Literal["lunch", "dinner"] = "dinner",
    meal_date: str | None = None,
    explain: bool = True,
) -> dict:
    """Interpreta una frase in italiano e decide chi lava i piatti.

    Esempio frase: "oggi abbiamo mangiato io, daniela e alessandra".
    I nomi vengono estratti dal testo e passati al tool choose_dishwasher.

    Args:
        question_text: Frase in linguaggio naturale con i partecipanti.
        requester_name: Nome della persona che corrisponde a "io" nella frase.
        meal_kind: lunch oppure dinner.
        meal_date: Data ISO (YYYY-MM-DD). Se omessa usa la data di oggi.
        explain: Se true, include la spiegazione dettagliata della scelta.

    Returns:
        Risposta con partecipanti estratti e decisione del lavapiatti.
    """
    participants = _extract_participants_from_text(
        text=question_text,
        requester_name=requester_name,
    )
    if not participants:
        raise ValueError(
            "Could not extract participants from text. Mention at least one family member name."
        )

    decision = choose_dishwasher(
        participants=participants,
        meal_kind=meal_kind,
        meal_date=meal_date,
        explain=explain,
    )

    return {
        "parsed_participants": participants,
        "decision": decision,
    }


@mcp.tool()
def health_check() -> dict:
    """Verifica che il gateway del Cucinometro sia raggiungibile."""
    endpoint = f"{API_BASE_URL}/health"
    try:
        response = requests.get(endpoint, timeout=REQUEST_TIMEOUT_SECONDS)
        return {
            "ok": response.ok,
            "status_code": response.status_code,
            "body": response.text,
            "api_base_url": API_BASE_URL,
        }
    except requests.RequestException as exc:
        return {
            "ok": False,
            "error": str(exc),
            "api_base_url": API_BASE_URL,
        }
