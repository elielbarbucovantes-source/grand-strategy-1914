"""Recherche technologique (H-011)."""

from __future__ import annotations

from typing import Any

from .effects import industry_total, research_modifier, tech_catalog
from .model import GameState, Nation
from .scenario import load_config


def tech_year_limit(config: dict[str, Any] | None = None) -> int:
    return 3


def available_technologies(state: GameState, nation: Nation) -> list[dict[str, Any]]:
    """Technologies recherchables : prerequis remplis, non connues, pas trop en avance."""
    config = load_config()
    catalog = tech_catalog()
    result = []
    for tech in catalog.values():
        if tech["id"] in nation.techs:
            continue
        if any(not nation.has_tech(req) for req in tech.get("requires", [])):
            continue
        if tech["year"] > state.year + tech_year_limit(config):
            continue
        result.append(tech)
    return sorted(result, key=lambda t: (t["year"], t["cost"], t["id"]))


def adjusted_cost(state: GameState, nation: Nation, tech: dict[str, Any]) -> int:
    config = load_config()
    penalty = config["research"]["ahead_penalty"]
    years_ahead = max(0, int(tech["year"]) - state.year)
    return int(round(float(tech["cost"]) * (1.0 + penalty * years_ahead)))


def monthly_points(state: GameState, nation: Nation) -> float:
    config = load_config()
    base = nation.stats["technology"] * config["research"]["points_per_tech_stat"]
    base += industry_total(state, nation) * config["research"]["points_per_industry"]
    return base * research_modifier(state, nation)


def start_research(state: GameState, nation: Nation, tech_id: str) -> tuple[bool, str]:
    catalog = tech_catalog()
    tech = catalog.get(tech_id)
    if not tech:
        return False, "Technologie inconnue."
    if tech_id in nation.techs:
        return False, "Technologie deja maitrisee."
    allowed = {t["id"] for t in available_technologies(state, nation)}
    if tech_id not in allowed:
        return False, "Prerequis ou date non satisfaits."
    if nation.research_tech == tech_id:
        return True, "Recherche deja en cours."
    nation.research_tech = tech_id
    nation.research_progress = 0.0
    return True, f"Recherche lancee : {tech['name']}."


def process_research(state: GameState, nation: Nation) -> list[dict[str, Any]]:
    messages: list[dict[str, Any]] = []
    if not nation.research_tech:
        return messages
    catalog = tech_catalog()
    tech = catalog.get(nation.research_tech)
    if not tech:
        nation.research_tech = None
        nation.research_progress = 0.0
        return messages
    nation.research_progress += monthly_points(state, nation)
    cost = adjusted_cost(state, nation, tech)
    if nation.research_progress >= cost:
        nation.techs.append(tech["id"])
        nation.research_progress = 0.0
        nation.research_tech = None
        nation.prestige += 1
        message = f"{nation.short} acheve la recherche « {tech['name']} »."
        state.add_log("recherche", message)
        messages.append({"category": "recherche", "message": message})
    return messages
