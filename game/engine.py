"""Moteur de tour : ordres, resolution simultanee, victoire et vue pour l'interface."""

from __future__ import annotations

import random
from typing import Any

from . import ai, diplomacy, economy, events, military, research
from .effects import industry_total, tech_catalog
from .model import GameState, Nation
from .scenario import load_config, playable_nations


def _apply_orders(
    state: GameState,
    nation: Nation,
    orders: dict[str, Any],
) -> tuple[list[dict[str, Any]], list[dict[str, str]]]:
    messages: list[dict[str, Any]] = []
    moves: list[dict[str, str]] = []
    if not orders or nation.eliminated:
        return messages, moves

    if orders.get("research"):
        ok, message = research.start_research(state, nation, str(orders["research"]))
        if ok:
            messages.append({"category": "recherche", "message": message})
        else:
            state.add_log("ordre", f"{nation.short} : {message}")

    for order in orders.get("construction", []) or []:
        ok, message = economy.queue_construction(
            state, nation, str(order.get("province", "")), str(order.get("kind", ""))
        )
        if ok:
            messages.append({"category": "construction", "message": message})
        else:
            state.add_log("ordre", f"{nation.short} : {message}")

    for order in orders.get("recruits", []) or []:
        ok, message = economy.queue_recruit(
            state,
            nation,
            str(order.get("province", "")),
            str(order.get("unit", "")),
            int(order.get("count", 1)),
        )
        if ok:
            messages.append({"category": "armee", "message": message})
        else:
            state.add_log("ordre", f"{nation.short} : {message}")

    for order in orders.get("diplomacy", []) or []:
        action = order.get("action")
        target = str(order.get("target", ""))
        if action == "improve":
            ok, message = diplomacy.improve_relations(state, nation, target)
        elif action in ("alliance", "nap", "trade", "transit"):
            ok, message = diplomacy.propose(state, nation, target, action)
        elif action == "war":
            ok, message = diplomacy.declare_war(state, nation, target)
        elif action == "peace":
            ok, message = diplomacy.propose_peace(state, nation, target)
        else:
            ok, message = False, f"Action diplomatique inconnue : {action}"
        if ok:
            messages.append({"category": "diplomatie", "message": message})
        else:
            state.add_log("ordre", f"{nation.short} : {message}")

    for move in orders.get("moves", []) or []:
        moves.append({"army": str(move.get("army", "")), "to": str(move.get("to", ""))})
    return messages, moves


def _update_stability_and_intelligence(state: GameState) -> list[dict[str, Any]]:
    config = load_config()
    messages: list[dict[str, Any]] = []
    for nation in state.nations.values():
        if nation.eliminated:
            continue
        wars = len(nation.wars)
        if wars:
            nation.stability -= config["stability"]["war_penalty"] * wars
        else:
            nation.stability += config["stability"]["recovery"]
        occupied = [p for p in state.provinces.values() if p.controller == nation.id and p.owner != nation.id]
        nation.stability -= 0.15 * len(occupied)
        nation.stability = max(config["stability"]["min"], min(config["stability"]["max"], nation.stability))
        nation.intelligence = min(
            config["intelligence"]["max"],
            nation.intelligence + config["intelligence"]["per_turn_gain"] + nation.stats["diplomacy"] * 0.05,
        )
        for province in state.provinces.values():
            if province.controller == province.owner:
                province.unrest = max(0.0, province.unrest - 2.0)
            else:
                province.unrest = min(100.0, province.unrest + 1.0)
    return messages


def _update_eliminations(state: GameState) -> list[dict[str, Any]]:
    messages: list[dict[str, Any]] = []
    for nation in state.nations.values():
        if nation.eliminated:
            continue
        controlled = [p for p in state.provinces.values() if p.controller == nation.id]
        armies = state.nation_armies(nation.id)
        if not controlled and not armies:
            nation.eliminated = True
            for other in state.nations.values():
                other.wars.discard(nation.id)
            message = f"{nation.short} est elimine de la carte."
            state.add_log("systeme", message)
            messages.append({"category": "systeme", "message": message})
    return messages


def _victory_result(state: GameState, kind: str, winner: Nation, message: str) -> dict[str, Any]:
    result = {
        "type": kind,
        "nation": winner.id,
        "nation_name": winner.name,
        "player_won": state.player_nation == winner.id,
        "message": message,
        "turn": state.turn,
        "date": state.date_label(),
    }
    state.victory = result
    state.add_log("victoire", message)
    return result


def economic_ranking(state: GameState, alive: list[Nation]) -> tuple[dict[str, float], list[Nation]]:
    """Classe les nations economiquement viables.

    Les micro-Etats sont exclus : leur indice par habitant est artificiellement
    eleve et ne doit pas leur offrir une victoire economique (H-023).
    """
    config = load_config()["victory"]
    indices = {n.id: economy.development_index(state, n) for n in alive}
    eligible = [
        n
        for n in alive
        if len([p for p in state.provinces.values() if p.controller == n.id]) >= config["economic_min_provinces"]
        and n.population >= config["economic_min_population"]
    ]
    ranking = sorted(eligible, key=lambda n: indices[n.id], reverse=True)
    return indices, ranking


def check_victory(state: GameState) -> dict[str, Any] | None:
    if state.victory:
        return state.victory
    config = load_config()["victory"]
    total = max(1, len(state.provinces))
    alive = [n for n in state.nations.values() if not n.eliminated]
    if not alive:
        state.victory = {
            "type": "effondrement",
            "nation": None,
            "nation_name": None,
            "player_won": False,
            "message": "Toutes les puissances se sont effondrees. Le monde entre dans une longue nuit.",
            "turn": state.turn,
            "date": state.date_label(),
        }
        return state.victory

    for nation in alive:
        controlled = len([p for p in state.provinces.values() if p.controller == nation.id])
        if controlled / total >= config["territorial_share"]:
            return _victory_result(
                state,
                "territoriale",
                nation,
                f"{nation.name} controle {controlled}/{total} provinces : victoire territoriale.",
            )

    for nation in alive:
        coalition = {nation.id} | {ally for ally in nation.alliances if ally in state.nations and not state.nations[ally].eliminated}
        controlled = len([p for p in state.provinces.values() if p.controller in coalition])
        friendly = all(nation.relation(member) > 25 for member in coalition if member != nation.id)
        if len(coalition) >= 2 and controlled / total >= config["diplomatic_share"] and friendly:
            return _victory_result(
                state,
                "diplomatique",
                nation,
                f"{nation.name} dirige une coalition de {len(coalition)} puissances couvrant {controlled}/{total} provinces.",
            )

    indices, ranking = economic_ranking(state, alive)
    leader = ranking[0].id if ranking else None
    margin = indices[ranking[0].id] - indices[ranking[1].id] if len(ranking) > 1 else 0.0
    for nation in alive:
        if nation.id == leader:
            state.economic_leader_streak[nation.id] = state.economic_leader_streak.get(nation.id, 0) + 1
        else:
            state.economic_leader_streak[nation.id] = 0
    if (
        leader
        and state.economic_leader_streak.get(leader, 0) >= config["economic_turns"]
        and indices[leader] >= config["economic_min_index"]
        and margin >= config["economic_margin"]
    ):
        winner = state.nations[leader]
        return _victory_result(
            state,
            "economique",
            winner,
            f"{winner.name} conserve le meilleur indice de developpement pendant {config['economic_turns']} tours.",
        )

    if state.player_nation:
        player = state.nations.get(state.player_nation)
        if player and player.eliminated:
            return _victory_result(
                state,
                "defaite",
                player,
                f"{player.name} est elimine : la partie est perdue.",
            )
    return None


def end_turn(
    state: GameState,
    player_orders: dict[str, Any] | None = None,
    event_choices: dict[str, str] | None = None,
    orders_by_nation: dict[str, dict[str, Any]] | None = None,
) -> list[dict[str, Any]]:
    """Resout un tour complet et avance d'un mois."""
    if state.victory:
        return state.report
    rng = random.Random(f"{state.seed}:{state.turn}")
    report: list[dict[str, Any]] = [
        {"category": "tour", "message": f"Resolution de {state.date_label()} (tour {state.turn + 1})."}
    ]

    player_orders = player_orders or {}
    choices = dict(event_choices or {})
    choices.update(player_orders.get("event_choices", {}) or {})
    report.extend(events.resolve_pending_events(state, choices, rng))
    for army in state.armies.values():
        army.moved = False

    orders: dict[str, dict[str, Any]] = {}
    for nation in state.nations.values():
        if nation.eliminated:
            continue
        if state.player_nation and nation.id == state.player_nation:
            orders[nation.id] = player_orders
        else:
            orders[nation.id] = ai.ai_orders(state, nation, rng)
        if orders_by_nation and nation.id in orders_by_nation:
            orders[nation.id] = orders_by_nation[nation.id]

    all_moves: list[dict[str, str]] = []
    for nation in state.nations.values():
        if nation.id not in orders:
            continue
        messages, moves = _apply_orders(state, nation, orders[nation.id])
        report.extend(messages)
        all_moves.extend(moves)

    for nation in state.nations.values():
        if nation.eliminated:
            continue
        report.extend(economy.process_economy(state, nation))
        report.extend(economy.process_construction(state, nation))
        report.extend(economy.process_recruits(state, nation))
        report.extend(research.process_research(state, nation))

    report.extend(military.resolve_movement(state, all_moves, rng))
    report.extend(_update_eliminations(state))
    report.extend(events.trigger_events(state, rng))
    report.extend(_update_stability_and_intelligence(state))
    report.extend(military.update_supply(state))

    victory = check_victory(state)
    if victory:
        report.append({"category": "victoire", "message": victory["message"]})

    if len(report) == 1:
        report.append({"category": "tour", "message": "Aucun evenement notable ce mois-ci."})
    state.report = report
    if not victory:
        state.next_month()
    return report


def take_control(state: GameState, nation_id: str) -> tuple[bool, str]:
    nation = state.nations.get(nation_id)
    if not nation:
        return False, "Nation inconnue."
    if not nation.playable:
        return False, "Cette nation n'est pas jouable dans le MVP."
    if nation.eliminated:
        return False, "Cette nation est eliminee."
    for other in state.nations.values():
        other.is_player = False
    nation.is_player = True
    state.player_nation = nation.id
    state.add_log("systeme", f"Prise de controle : {nation.name}.")
    return True, f"Vous dirigez maintenant {nation.name}."


def _valid_moves(state: GameState, nation: Nation, army) -> list[dict[str, Any]]:
    destinations = []
    for province_id in state.adjacency.get(army.province, []):
        province = state.provinces[province_id]
        ok, reason = military.validate_move(state, army, province_id)
        destinations.append(
            {
                "id": province_id,
                "name": province.name,
                "controller": province.controller,
                "owner": province.owner,
                "allowed": ok,
                "reason": reason,
                "enemy": province.controller in nation.wars,
                "terrain": province.terrain,
            }
        )
    return destinations


def _tech_view(state: GameState, nation: Nation) -> list[dict[str, Any]]:
    catalog = tech_catalog()
    available = {t["id"] for t in research.available_technologies(state, nation)}
    result = []
    for tech_id, tech in catalog.items():
        if tech_id in nation.techs:
            continue
        result.append(
            {
                "id": tech_id,
                "name": tech["name"],
                "branch": tech["branch"],
                "year": tech["year"],
                "cost": research.adjusted_cost(state, nation, tech),
                "description": tech["description"],
                "requires": tech["requires"],
                "available": tech_id in available,
                "current": nation.research_tech == tech_id,
                "progress": nation.research_progress if nation.research_tech == tech_id else 0,
            }
        )
    return sorted(result, key=lambda t: (not t["available"], t["year"], t["cost"]))


def _nation_brief(state: GameState, nation: Nation, viewer: Nation | None) -> dict[str, Any]:
    relation = viewer.relation(nation.id) if viewer and viewer.id != nation.id else 0
    return {
        "id": nation.id,
        "name": nation.name,
        "short": nation.short,
        "adjective": nation.adjective,
        "color": nation.color,
        "playable": nation.playable,
        "eliminated": nation.eliminated,
        "capital": nation.capital,
        "population": nation.population,
        "stats": dict(nation.stats),
        "personality": nation.personality,
        "stability": round(nation.stability, 1),
        "prestige": round(nation.prestige, 1),
        "relation": relation,
        "relation_category": diplomacy.relation_category(relation) if viewer and viewer.id != nation.id else "soi",
        "at_war": bool(viewer and nation.id in viewer.wars),
        "ally": bool(viewer and nation.id in viewer.alliances),
        "provinces": len([p for p in state.provinces.values() if p.controller == nation.id]),
        "armies": len(state.nation_armies(nation.id)),
        "is_player": nation.is_player,
    }


def build_view(state: GameState | None, nation_id: str | None = None) -> dict[str, Any]:
    """Construit la vue. ``nation_id=None`` produit la vue d'observation."""
    if state is None:
        return {"game": False, "playable": playable_nations()}
    viewer = state.nations.get(nation_id) if nation_id else None
    visible = military.visible_provinces(state, viewer)
    is_observer = viewer is None

    provinces = []
    for province in state.provinces.values():
        provinces.append(
            {
                "id": province.id,
                "name": province.name,
                "city": province.city,
                "owner": province.owner,
                "controller": province.controller,
                "terrain": province.terrain,
                "resource": dict(province.resource),
                "industry": province.industry,
                "fortification": province.fortification,
                "port": province.port,
                "strategic": province.strategic,
                "hexes": [list(h) for h in province.hexes],
                "unrest": round(province.unrest, 1),
                "visible": is_observer or province.id in visible,
            }
        )

    armies = []
    for army in state.armies.values():
        if not is_observer and army.nation != viewer.id and army.province not in visible:
            continue
        info = military.estimate_army(state, viewer, army)
        entry = {
            "id": army.id,
            "name": army.name,
            "nation": army.nation,
            "province": army.province,
            "supply": round(army.supply, 1),
            "morale": round(army.morale, 1),
            "entrenchment": round(army.entrenchment, 2),
            "moved": army.moved,
            "exact": info["exact"],
        }
        entry.update({k: v for k, v in info.items() if k != "exact"})
        armies.append(entry)

    nations = [_nation_brief(state, n, viewer) for n in state.nations.values()]
    nations.sort(key=lambda n: (not n["is_player"], n["short"]))

    own: dict[str, Any] | None = None
    if viewer is not None:
        controlled = [p for p in state.provinces.values() if p.controller == viewer.id]
        production = economy.national_production(state, viewer)
        consumption = economy.national_consumption(state, viewer)
        current_tech = tech_catalog().get(viewer.research_tech or "")
        own_armies = []
        for army in state.nation_armies(viewer.id):
            own_armies.append(
                {
                    "id": army.id,
                    "name": army.name,
                    "province": army.province,
                    "infantry": army.infantry,
                    "artillery": army.artillery,
                    "cavalry": army.cavalry,
                    "regiments": army.regiments,
                    "supply": round(army.supply, 1),
                    "morale": round(army.morale, 1),
                    "entrenchment": round(army.entrenchment, 2),
                    "moved": army.moved,
                    "valid_moves": _valid_moves(state, viewer, army),
                }
            )
        own = {
            "id": viewer.id,
            "name": viewer.name,
            "short": viewer.short,
            "color": viewer.color,
            "capital": viewer.capital,
            "population": viewer.population,
            "stats": dict(viewer.stats),
            "personality": viewer.personality,
            "ambitions": list(viewer.ambitions),
            "stock": {k: round(v, 1) for k, v in viewer.stock.items()},
            "manpower": round(viewer.manpower, 1),
            "stability": round(viewer.stability, 1),
            "prestige": round(viewer.prestige, 1),
            "intelligence": round(viewer.intelligence, 1),
            "techs": list(viewer.techs),
            "known_techs": [
                {"id": tech_id, "name": tech_catalog().get(tech_id, {}).get("name", tech_id)}
                for tech_id in viewer.techs
            ],
            "research_tech": viewer.research_tech,
            "research_name": current_tech["name"] if current_tech else None,
            "research_progress": round(viewer.research_progress, 1),
            "research_cost": research.adjusted_cost(state, viewer, current_tech) if current_tech else None,
            "research_points": round(research.monthly_points(state, viewer), 1),
            "available_techs": _tech_view(state, viewer),
            "construction": [dict(item) for item in viewer.construction],
            "recruits": [dict(item) for item in viewer.recruits],
            "production": {k: round(v, 1) for k, v in production.items()},
            "consumption": {k: round(v, 1) for k, v in consumption.items()},
            "net": {k: round(production[k] - consumption[k], 1) for k in production},
            "development_index": economy.development_index(state, viewer),
            "industry": industry_total(state, viewer),
            "provinces": len(controlled),
            "regiments": sum(a.regiments for a in state.nation_armies(viewer.id)),
            "wars": sorted(viewer.wars),
            "alliances": sorted(viewer.alliances),
            "treaties": [
                t.to_dict() for t in state.treaties if t.active and t.involves(viewer.id)
            ],
            "armies": own_armies,
            "diplomacy": diplomacy.available_actions(state, viewer),
            "pending_events": list(state.pending_events),
        }

    victory_progress = None
    if viewer:
        total = max(1, len(state.provinces))
        coalition = {viewer.id} | {a for a in viewer.alliances if a in state.nations}
        victory_progress = {
            "territorial": round(len([p for p in state.provinces.values() if p.controller == viewer.id]) / total, 3),
            "coalition": round(len([p for p in state.provinces.values() if p.controller in coalition]) / total, 3),
            "economic_index": economy.development_index(state, viewer),
            "economic_streak": state.economic_leader_streak.get(viewer.id, 0),
        }

    wars = set()
    for nation in state.nations.values():
        for enemy in nation.wars:
            wars.add(tuple(sorted((nation.id, enemy))))
    alliances = {
        tuple(sorted((t.a, t.b)))
        for t in state.treaties
        if t.active and t.type == "alliance"
    }

    return {
        "game": True,
        "observer": is_observer,
        "turn": state.turn,
        "date": state.date_label(),
        "player_nation": state.player_nation,
        "wars": [list(pair) for pair in sorted(wars)],
        "alliances": [list(pair) for pair in sorted(alliances)],
        "map": {
            "grid": {"cols": 38, "rows": 26},
            "provinces": provinces,
            "adjacency": {k: list(v) for k, v in state.adjacency.items()},
        },
        "nations": nations,
        "armies": armies,
        "own": own,
        "report": list(state.report),
        "log": list(state.log[-80:]),
        "pending_events": list(state.pending_events),
        "victory": dict(state.victory) if state.victory else None,
        "victory_progress": victory_progress,
        "config": {
            "victory": load_config()["victory"],
            "diplomacy": load_config()["diplomacy"],
        },
    }
