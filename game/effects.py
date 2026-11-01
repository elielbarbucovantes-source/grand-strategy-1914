"""Agregation des effets de recherche et des multiplicateurs nationaux."""

from __future__ import annotations

from typing import Any

from .model import GameState, Nation
from .scenario import load_technologies

EFFECT_KEYS = (
    "combat", "artillery", "naval", "production", "raw_efficiency",
    "research", "stability", "manpower", "intelligence", "prestige",
    "supply", "unity",
)


def tech_catalog() -> dict[str, dict[str, Any]]:
    return {tech["id"]: tech for tech in load_technologies()}


def tech_effects(state: GameState, nation: Nation) -> dict[str, float]:
    catalog = tech_catalog()
    totals = {key: 0.0 for key in EFFECT_KEYS}
    for tech_id in nation.techs:
        tech = catalog.get(tech_id)
        if not tech:
            continue
        for key, value in tech.get("effects", {}).items():
            if key in totals:
                totals[key] += float(value)
    return totals


def industry_total(state: GameState, nation: Nation) -> int:
    return sum(p.industry for p in state.provinces.values() if p.controller == nation.id)


def stability_factor(nation: Nation) -> float:
    """La stabilite module l'economie et la recherche entre 0,7 et 1,1."""
    return max(0.7, min(1.1, 0.7 + nation.stability / 150.0))


def combat_modifier(state: GameState, nation: Nation) -> float:
    effects = tech_effects(state, nation)
    return 1.0 + effects["combat"] + effects["artillery"] * 0.25


def supply_modifier(state: GameState, nation: Nation) -> float:
    return 1.0 + tech_effects(state, nation)["supply"]


def production_modifier(state: GameState, nation: Nation) -> float:
    effects = tech_effects(state, nation)
    return (1.0 + effects["production"]) * (1.0 + nation.stats["economy"] / 40.0) * stability_factor(nation)


def research_modifier(state: GameState, nation: Nation) -> float:
    effects = tech_effects(state, nation)
    return (1.0 + effects["research"]) * stability_factor(nation)


def manpower_modifier(state: GameState, nation: Nation) -> float:
    return 1.0 + tech_effects(state, nation)["manpower"]


def intelligence_modifier(state: GameState, nation: Nation) -> float:
    return tech_effects(state, nation)["intelligence"]
