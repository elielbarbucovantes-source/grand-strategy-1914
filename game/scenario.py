"""Chargement du scenario 1914 et creation d'une partie."""

from __future__ import annotations

import json
import random
from pathlib import Path
from typing import Any

from .model import Army, GameState, Nation, Province, Treaty

DATA_DIR = Path(__file__).resolve().parent / "data"

ROMAN = (
    "I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X",
    "XI", "XII", "XIII", "XIV", "XV", "XVI", "XVII", "XVIII", "XIX", "XX",
)


def load_data(name: str) -> dict[str, Any]:
    with (DATA_DIR / name).open(encoding="utf-8") as handle:
        return json.load(handle)


def load_config() -> dict[str, Any]:
    return load_data("config.json")


def load_technologies() -> list[dict[str, Any]]:
    return load_data("technologies.json")["technologies"]


def load_events() -> list[dict[str, Any]]:
    return load_data("events.json")["events"]


def _starting_techs(tech_stat: int) -> list[str]:
    """H-011 : les nations les plus avancees maitrisent deja les bases de 1914."""
    if tech_stat >= 8:
        return [
            "army_1914_infantry",
            "navy_dreadnought",
            "industry_electrification",
            "society_welfare",
        ]
    if tech_stat >= 6:
        return ["army_1914_infantry", "industry_electrification"]
    if tech_stat >= 4:
        return ["army_1914_infantry"]
    return []


def _corps_count(nation: Nation) -> int:
    if nation.playable:
        return max(2, min(10, round(nation.stats["army"] / 1.4)))
    return max(1, min(4, round(nation.population / 4)))


def _garrison_provinces(nation: Nation, provinces: list[Province]) -> list[str]:
    owned = [p for p in provinces if p.owner == nation.id]
    if not owned:
        return []
    ordered = sorted(
        owned,
        key=lambda p: (p.id != nation.capital, -p.strategic, -p.industry, p.id),
    )
    return [p.id for p in ordered]


def new_game(player_nation: str | None = None, seed: int | None = None) -> GameState:
    """Cree une partie neuve. ``player_nation=None`` lance le mode observation."""
    config = load_config()
    map_data = load_data("map.json")
    nations_data = load_data("nations.json")["nations"]

    seed = int(seed if seed is not None else random.SystemRandom().randint(1, 2_000_000_000))

    provinces: dict[str, Province] = {}
    for raw in map_data["provinces"]:
        province = Province.from_dict(raw)
        province.controller = province.owner
        provinces[province.id] = province

    nations: dict[str, Nation] = {}
    for raw in nations_data:
        nation = Nation.from_dict(raw)
        nation.stock = {
            "food": float(nation.stats["resources"] * 5 + nation.colonies.get("food", 0) * 2),
            "raw": float(nation.stats["resources"] * 4 + nation.colonies.get("raw", 0) * 2),
            "wealth": float(nation.stats["economy"] * 6 + nation.colonies.get("wealth", 0) * 2),
        }
        nation.manpower = float(nation.population * config["economy"]["manpower_per_million"])
        nation.stability = min(85.0, config["stability"]["base"] + nation.stats["unity"] * 2.0)
        nation.prestige = float(nation.stats["prestige"] * 5)
        nation.intelligence = float(config["intelligence"]["base"] + nation.stats["diplomacy"] * 2)
        nation.techs = _starting_techs(nation.stats["technology"])
        nations[nation.id] = nation

    if player_nation is not None:
        if player_nation not in nations:
            raise ValueError(f"Nation inconnue : {player_nation}")
        if not nations[player_nation].playable:
            raise ValueError(f"Nation non jouable : {player_nation}")
        nations[player_nation].is_player = True

    # Armees initiales (H-007 : chaque formation est un corps).
    armies: dict[str, Army] = {}
    military = config["military"]
    for nation in nations.values():
        garrisons = _garrison_provinces(nation, list(provinces.values()))
        if not garrisons:
            continue
        count = _corps_count(nation)
        for index in range(count):
            army_id = f"{nation.id}_corps_{index + 1}"
            armies[army_id] = Army(
                id=army_id,
                name=f"{ROMAN[index]}e corps",
                nation=nation.id,
                province=garrisons[index % len(garrisons)],
                infantry=military["starting_infantry"],
                artillery=military["starting_artillery"],
                cavalry=military["starting_cavalry"],
                supply=100.0,
                morale=100.0,
            )

    treaties: list[Treaty] = []
    seen: set[tuple[str, str]] = set()
    for nation in nations.values():
        for ally in nation.starting_alliances:
            if ally not in nations:
                continue
            pair = tuple(sorted((nation.id, ally)))
            if pair in seen:
                continue
            seen.add(pair)
            nations[nation.id].alliances.add(ally)
            nations[ally].alliances.add(nation.id)
            treaties.append(
                Treaty(
                    id=f"alliance_{pair[0]}_{pair[1]}",
                    type="alliance",
                    a=pair[0],
                    b=pair[1],
                    signed_turn=0,
                )
            )

    start = config["start"]
    state = GameState(
        version=1,
        seed=seed,
        turn=0,
        year=int(start["year"]),
        month=int(start["month"]),
        player_nation=player_nation,
        nations=nations,
        provinces=provinces,
        armies=armies,
        adjacency={k: list(v) for k, v in map_data["adjacency"].items()},
        treaties=treaties,
    )

    if player_nation:
        label = nations[player_nation].name
        state.add_log("systeme", f"Vous dirigez {label}. Juin 1914 : l'Europe entre dans l'ete le plus dangereux de son histoire.")
        state.report.append({"category": "systeme", "message": f"Partie lancee : {label}."})
    else:
        state.add_log("systeme", "Mode observation : vous ne dirigez aucun pays, mais vous suivez tous les evenements.")
        state.report.append({"category": "systeme", "message": "Partie lancee en mode observation."})

    return state


def playable_nations() -> list[dict[str, Any]]:
    data = load_data("nations.json")["nations"]
    return [
        {
            "id": n["id"],
            "name": n["name"],
            "short": n["short"],
            "adjective": n["adjective"],
            "color": n["color"],
            "population": n["population"],
            "stats": n["stats"],
            "personality": n["personality"],
            "ambitions": n["ambitions"],
            "capital": n["capital"],
        }
        for n in data
        if n["playable"]
    ]


def nation_briefs() -> list[dict[str, Any]]:
    data = load_data("nations.json")["nations"]
    return [
        {
            "id": n["id"],
            "name": n["name"],
            "short": n["short"],
            "color": n["color"],
            "playable": n["playable"],
            "capital": n["capital"],
            "population": n["population"],
            "stats": n["stats"],
            "personality": n["personality"],
        }
        for n in data
    ]
