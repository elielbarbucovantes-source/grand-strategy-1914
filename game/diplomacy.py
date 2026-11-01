"""Diplomatie du MVP (H-008, H-009, H-010)."""

from __future__ import annotations

from typing import Any

from .model import GameState, Nation, Treaty
from .scenario import load_config


def relation_category(value: int) -> str:
    if value < -25:
        return "hostilite"
    if value > 25:
        return "amitie"
    return "neutralite"


def relation_label(value: int) -> str:
    return {
        "hostilite": "Hostilite",
        "neutralite": "Neutralite",
        "amitie": "Amitie",
    }[relation_category(value)]


def _clamp_relation(value: int) -> int:
    config = load_config()["diplomacy"]
    return max(config["min_relation"], min(config["max_relation"], value))


def change_relation(state: GameState, a: str, b: str, delta: int) -> None:
    if a not in state.nations or b not in state.nations or a == b:
        return
    state.nations[a].relations[b] = _clamp_relation(state.nations[a].relation(b) + delta)
    state.nations[b].relations[a] = _clamp_relation(state.nations[b].relation(a) + delta)


def set_relation(state: GameState, a: str, b: str, value: int) -> None:
    if a not in state.nations or b not in state.nations or a == b:
        return
    state.nations[a].relations[b] = _clamp_relation(value)
    state.nations[b].relations[a] = _clamp_relation(value)


def has_treaty(state: GameState, a: str, b: str, kind: str) -> bool:
    return any(t.active and t.type == kind and {t.a, t.b} == {a, b} for t in state.treaties)


def treaties_of(state: GameState, nation: str) -> list[Treaty]:
    return [t for t in state.treaties if t.active and t.involves(nation)]


def add_treaty(state: GameState, kind: str, a: str, b: str) -> Treaty:
    existing = next((t for t in state.treaties if t.active and t.type == kind and {t.a, t.b} == {a, b}), None)
    if existing:
        return existing
    treaty = Treaty(
        id=f"{kind}_{min(a, b)}_{max(a, b)}",
        type=kind,
        a=a,
        b=b,
        signed_turn=state.turn,
    )
    state.treaties.append(treaty)
    if kind == "alliance":
        state.nations[a].alliances.add(b)
        state.nations[b].alliances.add(a)
    return treaty


def remove_treaties(state: GameState, a: str, b: str, kinds: tuple[str, ...] | None = None) -> None:
    for treaty in state.treaties:
        if not treaty.active or {treaty.a, treaty.b} != {a, b}:
            continue
        if kinds and treaty.type not in kinds:
            continue
        treaty.active = False
        if treaty.type == "alliance":
            state.nations[a].alliances.discard(b)
            state.nations[b].alliances.discard(a)


def improve_relations(state: GameState, nation: Nation, target_id: str) -> tuple[bool, str]:
    config = load_config()["diplomacy"]
    target = state.nations.get(target_id)
    if not target or target.eliminated:
        return False, "Nation cible invalide."
    if target_id in nation.wars:
        return False, "Impossible d'ameliorer les relations avec un ennemi en guerre."
    if nation.stock["wealth"] < config["improve_cost"]:
        return False, "Richesse insuffisante."
    nation.stock["wealth"] -= config["improve_cost"]
    change_relation(state, nation.id, target_id, config["improve_gain"])
    message = f"{nation.short} ameliore ses relations avec {target.short} (+{config['improve_gain']})."
    state.add_log("diplomatie", message)
    return True, message


def _acceptance(state: GameState, target: Nation, proposer: Nation, kind: str) -> bool:
    relation = target.relation(proposer.id)
    shared_enemy = bool(target.wars & proposer.wars)
    if kind == "alliance":
        if has_treaty(state, target.id, proposer.id, "alliance"):
            return True
        return relation >= 55 or (relation >= 40 and shared_enemy)
    if kind == "nap":
        return relation >= 10
    if kind == "trade":
        return relation >= 25
    if kind == "transit":
        return relation >= 35
    if kind == "peace":
        target_strength = _strength(state, target)
        proposer_strength = _strength(state, proposer)
        exhaustion = (100.0 - target.stability) / 100.0
        disadvantage = proposer_strength / max(1.0, target_strength)
        chance = load_config()["diplomacy"]["peace_base_chance"] + exhaustion * 0.3 + max(0.0, disadvantage - 1.0) * 0.2
        return chance >= 0.55
    return False


def _strength(state: GameState, nation: Nation) -> float:
    from .military import army_power

    return sum(army_power(state, a) for a in state.nation_armies(nation.id))


def propose(state: GameState, nation: Nation, target_id: str, kind: str) -> tuple[bool, str]:
    config = load_config()["diplomacy"]
    target = state.nations.get(target_id)
    if not target or target.eliminated or target_id == nation.id:
        return False, "Nation cible invalide."
    costs = {
        "alliance": config["alliance_cost"],
        "nap": config["nap_cost"],
        "trade": config["trade_cost"],
        "transit": config["transit_cost"],
    }
    if kind not in costs:
        return False, "Type d'accord inconnu."
    if nation.stock["wealth"] < costs[kind]:
        return False, "Richesse insuffisante."
    if kind in ("alliance", "nap", "trade", "transit") and has_treaty(state, nation.id, target_id, kind):
        return False, "Cet accord existe deja."
    if target_id in nation.wars:
        return False, "Impossible de negocier ce traite avec un ennemi en guerre."
    nation.stock["wealth"] -= costs[kind]
    if not _acceptance(state, target, nation, kind):
        message = f"{target.short} refuse la proposition de {nation.short}."
        state.add_log("diplomatie", message)
        return False, message
    add_treaty(state, kind, nation.id, target_id)
    change_relation(state, nation.id, target_id, 5)
    names = {"alliance": "alliance defensive", "nap": "pacte de non-agression", "trade": "accord commercial", "transit": "droit de transit"}
    message = f"{nation.short} et {target.short} signent un {names[kind]}."
    state.add_log("diplomatie", message)
    return True, message


def declare_war(state: GameState, nation: Nation, target_id: str) -> tuple[bool, str]:
    config = load_config()["diplomacy"]
    target = state.nations.get(target_id)
    if not target or target.eliminated or target_id == nation.id:
        return False, "Nation cible invalide."
    if target_id in nation.wars:
        return False, "La guerre est deja declaree."
    remove_treaties(state, nation.id, target_id)
    nation.wars.add(target_id)
    target.wars.add(nation.id)
    change_relation(state, nation.id, target_id, -config["declare_war_relation_cost"])
    nation.stability = max(0.0, nation.stability - config["war_stability_cost"])
    target.stability = max(0.0, target.stability - config["war_stability_cost"] * 0.5)
    message = f"{nation.short} declare la guerre a {target.short} !"
    state.add_log("diplomatie", message)

    # Les allies defensifs de la cible entrent en guerre.
    for ally_id in sorted(target.alliances):
        ally = state.nations.get(ally_id)
        if not ally or ally.eliminated or ally_id in (nation.id,) or ally_id in target.wars:
            continue
        if has_treaty(state, ally_id, target_id, "alliance"):
            ally.wars.add(nation.id)
            nation.wars.add(ally_id)
            change_relation(state, ally_id, nation.id, -25)
            state.add_log("diplomatie", f"{ally.short} honore son alliance avec {target.short} et entre en guerre contre {nation.short}.")
    # Les allies offensifs suivent si la relation est solide.
    for ally_id in sorted(nation.alliances):
        ally = state.nations.get(ally_id)
        if not ally or ally.eliminated or ally_id in nation.wars or ally_id == target_id:
            continue
        if has_treaty(state, nation.id, ally_id, "alliance") and ally.relation(nation.id) >= 50:
            ally.wars.add(target_id)
            target.wars.add(ally_id)
            change_relation(state, ally_id, target_id, -25)
            state.add_log("diplomatie", f"{ally.short} rejoint {nation.short} contre {target.short}.")
    return True, message


def make_peace(state: GameState, nation: Nation, target_id: str, transfer_land: bool = True) -> tuple[bool, str]:
    target = state.nations.get(target_id)
    if not target or target_id not in nation.wars:
        return False, "Aucune guerre en cours avec cette nation."
    nation.wars.discard(target_id)
    target.wars.discard(nation.id)
    change_relation(state, nation.id, target_id, 10)
    nation.stability = min(100.0, nation.stability + 2)
    target.stability = min(100.0, target.stability + 2)
    transferred: list[str] = []
    if transfer_land:
        for province in state.provinces.values():
            if province.owner == target_id and province.controller == nation.id:
                province.owner = nation.id
                transferred.append(province.name)
            elif province.owner == nation.id and province.controller == target_id:
                province.owner = target_id
                transferred.append(province.name)
    message = f"Paix entre {nation.short} et {target.short}."
    if transferred:
        message += f" Transfert de controle : {', '.join(sorted(transferred))}."
    state.add_log("diplomatie", message)
    return True, message


def propose_peace(state: GameState, nation: Nation, target_id: str) -> tuple[bool, str]:
    target = state.nations.get(target_id)
    if not target or target_id not in nation.wars:
        return False, "Aucune guerre en cours avec cette nation."
    if not _acceptance(state, target, nation, "peace"):
        message = f"{target.short} refuse de negocier la paix."
        state.add_log("diplomatie", message)
        return False, message
    return make_peace(state, nation, target_id)


def available_actions(state: GameState, nation: Nation) -> list[dict[str, Any]]:
    actions: list[dict[str, Any]] = []
    for target in state.nations.values():
        if target.id == nation.id or target.eliminated:
            continue
        relation = nation.relation(target.id)
        at_war = target.id in nation.wars
        actions.append(
            {
                "target": target.id,
                "target_name": target.short,
                "relation": relation,
                "category": relation_category(relation),
                "at_war": at_war,
                "can_improve": not at_war,
                "can_alliance": not at_war and not has_treaty(state, nation.id, target.id, "alliance"),
                "can_nap": not at_war and not has_treaty(state, nation.id, target.id, "nap"),
                "can_trade": not at_war and not has_treaty(state, nation.id, target.id, "trade"),
                "can_transit": not at_war and not has_treaty(state, nation.id, target.id, "transit"),
                "can_declare_war": not at_war,
                "can_peace": at_war,
            }
        )
    return sorted(actions, key=lambda a: (-a["relation"], a["target_name"]))
