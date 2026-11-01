"""IA autonome et non omnisciente du MVP (H-012, H-013, H-019)."""

from __future__ import annotations

import random
from collections import deque
from typing import Any

from . import diplomacy, economy, research
from .effects import industry_total
from .military import army_power, visible_provinces
from .model import GameState, Nation
from .scenario import load_config


PERSONALITY_RESEARCH = {
    "aggressive": ("armee", "industrie", "science", "societe", "marine"),
    "defensive": ("armee", "societe", "industrie", "science", "marine"),
    "diplomat": ("science", "industrie", "societe", "marine", "armee"),
    "opportunist": ("armee", "marine", "industrie", "science", "societe"),
    "cautious": ("industrie", "armee", "science", "societe", "marine"),
}


def _owned_provinces(state: GameState, nation: Nation) -> list:
    return [p for p in state.provinces.values() if p.controller == nation.id]


def _border_provinces(state: GameState, nation: Nation) -> list:
    border = []
    for province in _owned_provinces(state, nation):
        for neighbour_id in state.adjacency.get(province.id, []):
            neighbour = state.provinces.get(neighbour_id)
            if neighbour and neighbour.controller != nation.id:
                border.append(province)
                break
    return border


def _visible_enemy_power(state: GameState, nation: Nation, province_id: str) -> float:
    visible = visible_provinces(state, nation)
    if province_id not in visible:
        return 0.0
    enemies = [
        army for army in state.armies.values()
        if army.province == province_id and army.nation in nation.wars
    ]
    return sum(army_power(state, army) for army in enemies)


def _own_power(state: GameState, nation: Nation) -> float:
    return sum(army_power(state, army) for army in state.nation_armies(nation.id))


def _enemy_power_estimate(state: GameState, nation: Nation) -> float:
    total = 0.0
    visible = visible_provinces(state, nation)
    for army in state.armies.values():
        if army.nation in nation.wars and army.province in visible:
            total += army_power(state, army)
    return max(1.0, total)


def _path_to_enemy(state: GameState, nation: Nation, start: str, max_depth: int = 12) -> list[str]:
    """Plus court chemin vers une province ennemie, sans connaitre les armees cachees."""
    if start not in state.provinces:
        return []
    queue: deque[tuple[str, list[str]]] = deque([(start, [])])
    visited = {start}
    while queue:
        current, path = queue.popleft()
        if len(path) >= max_depth:
            continue
        for neighbour in state.adjacency.get(current, []):
            province = state.provinces.get(neighbour)
            if not province or neighbour in visited:
                continue
            if province.controller == nation.id or province.controller in nation.alliances:
                visited.add(neighbour)
                queue.append((neighbour, path + [neighbour]))
            elif province.controller in nation.wars:
                return path + [neighbour]
    return []


def _path_to_own(state: GameState, nation: Nation, start: str, max_depth: int = 12) -> list[str]:
    if start not in state.provinces:
        return []
    queue: deque[tuple[str, list[str]]] = deque([(start, [])])
    visited = {start}
    while queue:
        current, path = queue.popleft()
        if len(path) >= max_depth:
            continue
        for neighbour in state.adjacency.get(current, []):
            province = state.provinces.get(neighbour)
            if not province or neighbour in visited:
                continue
            if province.controller == nation.id:
                return path + [neighbour]
            if province.controller in nation.alliances or province.controller in nation.wars:
                visited.add(neighbour)
                queue.append((neighbour, path + [neighbour]))
    return []


def _choose_research(state: GameState, nation: Nation, rng: random.Random) -> str | None:
    available = research.available_technologies(state, nation)
    if not available:
        return None
    order = PERSONALITY_RESEARCH.get(nation.personality, PERSONALITY_RESEARCH["cautious"])
    branch_rank = {branch: index for index, branch in enumerate(order)}

    def score(tech: dict[str, Any]) -> tuple[float, int]:
        cost = research.adjusted_cost(state, nation, tech)
        return (branch_rank.get(tech["branch"], 9) + cost / 300.0 + rng.random() * 0.8, cost)

    return min(available, key=score)["id"]


def _diplomacy_orders(state: GameState, nation: Nation, rng: random.Random) -> list[dict[str, str]]:
    config = load_config()["ai"]
    orders: list[dict[str, str]] = []
    if nation.eliminated:
        return orders

    if nation.wars:
        own = _own_power(state, nation)
        enemy = _enemy_power_estimate(state, nation)
        losing = own < enemy * 0.8 or nation.stability < 35
        if (losing and rng.random() < config["peace_chance"]) or rng.random() < 0.06:
            target = max(nation.wars, key=lambda n: state.nations[n].prestige if n in state.nations else 0)
            orders.append({"action": "peace", "target": target})
        return orders

    # Amelioration des relations et accords.
    candidates = [
        n for n in state.nations.values()
        if n.id != nation.id and not n.eliminated and n.id not in nation.wars
    ]
    if candidates and rng.random() < config["improve_chance"]:
        friendly = max(candidates, key=lambda n: nation.relation(n.id))
        orders.append({"action": "improve", "target": friendly.id})
    for target in candidates:
        relation = nation.relation(target.id)
        if relation >= 55 and not diplomacy.has_treaty(state, nation.id, target.id, "alliance"):
            if rng.random() < 0.25 and nation.stock["wealth"] >= 10:
                orders.append({"action": "alliance", "target": target.id})
                break
        if relation >= 30 and not diplomacy.has_treaty(state, nation.id, target.id, "trade"):
            if rng.random() < 0.15 and nation.stock["wealth"] >= 5:
                orders.append({"action": "trade", "target": target.id})
                break

    # Declaration de guerre : seulement contre un voisin, si les forces le permettent.
    if state.turn >= 2 and nation.personality in ("aggressive", "opportunist"):
        neighbours = set()
        for province in _owned_provinces(state, nation):
            for neighbour_id in state.adjacency.get(province.id, []):
                neighbour = state.provinces.get(neighbour_id)
                if neighbour and neighbour.controller != nation.id and neighbour.controller not in nation.alliances:
                    neighbours.add(neighbour.controller)
        viable = []
        own = _own_power(state, nation)
        for target_id in neighbours:
            target = state.nations.get(target_id)
            if not target or target.eliminated or target_id in nation.wars:
                continue
            if nation.relation(target_id) > config["aggression_threshold"]:
                continue
            visible_enemy = sum(
                army_power(state, army)
                for army in state.nation_armies(target_id)
                if army.province in visible_provinces(state, nation)
            )
            if own >= max(1.0, visible_enemy) * config["war_strength_ratio"]:
                viable.append(target_id)
        if viable and rng.random() < (0.35 if nation.personality == "aggressive" else 0.18):
            orders.append({"action": "war", "target": rng.choice(sorted(viable))})
    return orders


def _construction_orders(state: GameState, nation: Nation, rng: random.Random) -> list[dict[str, str]]:
    config = load_config()["ai"]
    orders: list[dict[str, str]] = []
    if rng.random() > config["build_chance"]:
        return orders
    owned = _owned_provinces(state, nation)
    if not owned:
        return orders
    border = _border_provinces(state, nation)
    if nation.personality in ("defensive", "cautious") and border:
        target = max(border, key=lambda p: (p.strategic, p.fortification))
        if target.fortification < 4:
            orders.append({"action": "construct", "province": target.id, "kind": "fortification"})
            return orders
    target = max(owned, key=lambda p: (p.industry, p.strategic, -p.fortification))
    if target.industry < 6:
        orders.append({"action": "construct", "province": target.id, "kind": "industry"})
    return orders


def _recruit_orders(state: GameState, nation: Nation, rng: random.Random) -> list[dict[str, str]]:
    config = load_config()["ai"]
    orders: list[dict[str, str]] = []
    if rng.random() > config["recruit_chance"]:
        return orders
    owned = _owned_provinces(state, nation)
    if not owned:
        return orders
    target = max(owned, key=lambda p: (p.strategic, p.industry))
    count = 2 if nation.wars else 1
    if economy.can_pay(nation, {k: v * count for k, v in economy.recruit_cost("infantry").items()}):
        orders.append({"action": "recruit", "province": target.id, "unit": "infantry", "count": count})
    return orders


def _movement_orders(state: GameState, nation: Nation, rng: random.Random) -> list[dict[str, str]]:
    config = load_config()["ai"]
    moves: list[dict[str, str]] = []
    armies = state.nation_armies(nation.id)
    if not armies:
        return moves
    if nation.wars:
        armies = sorted(armies, key=lambda a: -army_power(state, a))
        for army in armies[: config["max_moves_per_turn"]]:
            if army.moved:
                continue
            path = _path_to_enemy(state, nation, army.province)
            if not path:
                continue
            destination = path[0]
            target_province = state.provinces[destination]
            if target_province.controller in nation.wars:
                enemy_power = _visible_enemy_power(state, nation, destination)
                own_power = army_power(state, army)
                if enemy_power > 0 and own_power < enemy_power * 0.9 and len(path) == 1:
                    continue
            moves.append({"army": army.id, "to": destination})
    else:
        # En paix, les armees reviennent defendre le territoire national.
        for army in armies:
            province = state.provinces.get(army.province)
            if province and province.controller != nation.id:
                path = _path_to_own(state, nation, army.province)
                if path:
                    moves.append({"army": army.id, "to": path[0]})
    return moves


def ai_orders(state: GameState, nation: Nation, rng: random.Random) -> dict[str, Any]:
    """Construit les ordres d'une nation IA pour le tour courant."""
    orders: dict[str, Any] = {
        "moves": [],
        "research": None,
        "construction": [],
        "recruits": [],
        "diplomacy": [],
        "event_choices": {},
    }
    if nation.eliminated:
        return orders
    if not nation.research_tech:
        orders["research"] = _choose_research(state, nation, rng)
    orders["diplomacy"] = _diplomacy_orders(state, nation, rng)
    orders["construction"] = _construction_orders(state, nation, rng)
    orders["recruits"] = _recruit_orders(state, nation, rng)
    orders["moves"] = _movement_orders(state, nation, rng)
    return orders
