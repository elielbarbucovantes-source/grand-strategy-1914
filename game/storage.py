"""Sauvegarde et chargement de parties au format JSON."""

from __future__ import annotations

import json
import re
from pathlib import Path
from typing import Any

from .model import GameState

SAVE_DIR = Path(__file__).resolve().parent.parent / "saves"
SAFE_NAME = re.compile(r"[^a-zA-Z0-9_-]+")


def _safe_name(name: str) -> str:
    cleaned = SAFE_NAME.sub("-", name.strip()).strip("-")
    return cleaned[:60] or "partie"


def save_dir(base_dir: Path | None = None) -> Path:
    directory = base_dir or SAVE_DIR
    directory.mkdir(parents=True, exist_ok=True)
    return directory


def save_game(state: GameState, name: str, base_dir: Path | None = None) -> dict[str, Any]:
    directory = save_dir(base_dir)
    filename = f"{_safe_name(name)}.json"
    path = directory / filename
    payload = state.to_dict()
    payload["save_name"] = name.strip() or filename[:-5]
    with path.open("w", encoding="utf-8") as handle:
        json.dump(payload, handle, ensure_ascii=False, indent=2)
    return {"name": path.stem, "file": filename, "turn": state.turn, "date": state.date_label()}


def load_game(name: str, base_dir: Path | None = None) -> GameState:
    directory = save_dir(base_dir)
    filename = f"{_safe_name(name)}.json"
    path = directory / filename
    if not path.exists():
        raise FileNotFoundError(f"Sauvegarde introuvable : {name}")
    with path.open(encoding="utf-8") as handle:
        data = json.load(handle)
    return GameState.from_dict(data)


def list_saves(base_dir: Path | None = None) -> list[dict[str, Any]]:
    directory = save_dir(base_dir)
    saves = []
    for path in sorted(directory.glob("*.json")):
        try:
            with path.open(encoding="utf-8") as handle:
                data = json.load(handle)
            player = data.get("player_nation")
            saves.append(
                {
                    "name": path.stem,
                    "player": player,
                    "turn": data.get("turn", 0),
                    "year": data.get("year"),
                    "month": data.get("month"),
                    "date": data.get("save_name") or path.stem,
                }
            )
        except (OSError, ValueError):
            continue
    return sorted(saves, key=lambda item: item["name"], reverse=True)
