"""Mouvement strategique, ravitaillement et combat (H-006, H-013)."""

from __future__ import annotations

import random
from collections import deque
from typing import Any

from .effects import combat_modifier, supply_modifier
from .model import Army, GameState, Nation
from .scenario import load_config


def _terrain_defense(province) -> float:
    config = load_config()["military"]
    return float(config["terrain_defense"].get(province.terrain, 1.0))


def regiment_power(army: Army, nation: Nation, config: dict[str, Any] | None = None) -> float:
    config = config or load_config()["military"]
    base = (
        army.infantry * config["infantry_power"]
        + army.artillery * config["artillery_power"]
        + army.cavalry * config["cavalry_power"]
    )
    morale = max(0.2, army.morale / 100.0)
    supply = 0.6 + 0.4 * max(0.0, min(100.0, army.supply)) / 100.0
    return base * nation.army_quality * morale * supply


def army_power(state: GameState, army: Army, defending: bool = False) -> float:
    config = load_config()["military"]
    nation = state.nations[army.nation]
    power = regiment_power(army, nation, config) * combat_modifier(state, nation)
    if defending:
        province = state.provinces[army.province]
        power *= _terrain_defense(province)
        power *= 1.0 + province.fortification * config["fortification_defense"]
        power *= 1.0 + army.entrenchment * config["entrenchment_defense"]
    return power


def total_power(state: GameState, armies: list[Army], defending: bool = False) -> float:
    return sum(army_power(state, army, defending) for army in armies)


def _allied(state: GameState, a: str, b: str) -> bool:
    if a == b:
        return True
    if b in state.nations[a].alliances:
        return True
    return any(
        t.active and t.type in ("alliance", "transit") and {t.a, t.b} == {a, b}
        for t in state.treaties
    )


def can_enter(state: GameState, nation: Nation, province_id: str) -> tuple[bool, str]:
    province = state.provinces.get(province_id)
    if not province:
        return False, "Province inconnue."
    if province.controller == nation.id:
        return True, ""
    if _allied(state, nation.id, province.controller):
        return True, ""
    if province.controller in nation.wars:
        return True, ""
    return False, "Il faut d'abord etre en guerre ou disposer d'un droit de passage."


def validate_move(state: GameState, army: Army, destination: str) -> tuple[bool, str]:
    if army.nation not in state.nations:
        return False, "Armee sans nation."
    if army.moved:
        return False, "Cette armee a deja ete engagee ce tour."
    if destination not in state.adjacency.get(army.province, []):
        return False, "Destination non adjacente."
    return can_enter(state, state.nations[army.nation], destination)


def _retreat_destination(state: GameState, army: Army, battle_province: str, origin: str | None) -> str | None:
    candidates: list[str] = []
    if origin and origin != battle_province:
        candidates.append(origin)
    candidates.extend(state.adjacency.get(battle_province, []))
    for province_id in candidates:
        province = state.provinces.get(province_id)
        if not province:
            continue
        if province.controller == army.nation or _allied(state, army.nation, province.controller):
            return province_id
    return None


def _apply_losses(state: GameState, army: Army, ratio: float) -> int:
    total = army.regiments
    if total <= 0:
        return 0
    losses = max(1, int(round(total * ratio)))
    losses = min(losses, total)
    remaining = losses
    for attribute in ("infantry", "artillery", "cavalry"):
        value = getattr(army, attribute)
        if value <= 0:
            continue
        take = min(value, max(0, int(round(losses * value / total))))
        take = min(take, remaining)
        setattr(army, attribute, value - take)
        remaining -= take
    while remaining > 0 and army.regiments > 0:
        for attribute in ("infantry", "cavalry", "artillery"):
            if getattr(army, attribute) > 0 and remaining > 0:
                setattr(army, attribute, getattr(army, attribute) - 1)
                remaining -= 1
    return losses


def _remove_if_destroyed(state: GameState, army: Army, messages: list[dict[str, Any]]) -> None:
    if army.regiments <= 0:
        state.armies.pop(army.id, None)
        message = f"{state.nations[army.nation].short} : le {army.name} est detruit."
        state.add_log("combat", message)
        messages.append({"category": "combat", "message": message})


def _capture(state: GameState, province, victor: str, messages: list[dict[str, Any]]) -> None:
    old_controller = province.controller
    if old_controller == victor:
        return
    province.controller = victor
    province.unrest = min(100.0, province.unrest + 15.0)
    victor_nation = state.nations[victor]
    old_nation = state.nations.get(old_controller)
    message = f"{victor_nation.short} occupe {province.name}."
    state.add_log("occupation", message)
    messages.append({"category": "occupation", "message": message})
    if old_nation and province.id == old_nation.capital:
        old_nation.stability = max(0.0, old_nation.stability - 10.0)
        old_nation.prestige = max(0.0, old_nation.prestige - 5.0)
        victor_nation.prestige += 5
        message = f"La capitale de {old_nation.short} ({province.city}) est occupee !"
        state.add_log("occupation", message)
        messages.append({"category": "occupation", "message": message})


def _resolve_battle(
    state: GameState,
    province_id: str,
    attackers: list[Army],
    defenders: list[Army],
    origins: dict[str, str],
    rng: random.Random,
) -> list[dict[str, Any]]:
    config = load_config()["military"]
    messages: list[dict[str, Any]] = []
    province = state.provinces[province_id]
    attacker_power = total_power(state, attackers, defending=False) * rng.uniform(0.9, 1.1)
    defender_power = total_power(state, defenders, defending=True) * rng.uniform(0.9, 1.1)
    if defender_power <= 0:
        defender_power = 0.1

    attacker_wins = attacker_power >= defender_power * config["capture_ratio"]
    attacker_nations = {a.nation for a in attackers}
    lead_attacker = max(attacker_nations, key=lambda n: total_power(state, [a for a in attackers if a.nation == n]))
    lead_defender = max({d.nation for d in defenders}, key=lambda n: total_power(state, [d for d in defenders if d.nation == n]))

    ratio = attacker_power / max(1.0, defender_power)
    loss_scale = max(0.6, min(1.4, ratio if attacker_wins else 1.0 / max(0.1, ratio)))

    if attacker_wins:
        for army in defenders:
            lost = _apply_losses(state, army, config["defender_loss_ratio"] * loss_scale)
            army.morale = max(0.0, army.morale - config["morale_loss_defeat"])
            army.entrenchment = 0.0
            _remove_if_destroyed(state, army, messages)
            if army.id in state.armies:
                retreat = _retreat_destination(state, army, province_id, origins.get(army.id))
                if retreat:
                    army.province = retreat
                    army.supply = max(0.0, army.supply - config["retreat_supply_penalty"])
                else:
                    state.armies.pop(army.id, None)
                    message = f"{state.nations[army.nation].short} : le {army.name} se rend."
                    state.add_log("combat", message)
                    messages.append({"category": "combat", "message": message})
        for army in attackers:
            lost = _apply_losses(state, army, config["attacker_loss_ratio"] * max(0.6, 1.0 / loss_scale))
            army.morale = min(100.0, army.morale + config["morale_gain_victory"])
            army.entrenchment = 0.0
            _remove_if_destroyed(state, army, messages)
        survivors = [a for a in attackers if a.id in state.armies]
        for army in survivors:
            army.province = province_id
        if survivors:
            _capture(state, province, lead_attacker, messages)
            message = (
                f"Victoire de {state.nations[lead_attacker].short} a {province.name} "
                f"contre {state.nations[lead_defender].short}."
            )
        else:
            message = f"Combat indecis a {province.name} : plus aucune unite combattante."
    else:
        for army in attackers:
            lost = _apply_losses(state, army, config["defender_loss_ratio"] * loss_scale)
            army.morale = max(0.0, army.morale - config["morale_loss_defeat"])
            army.entrenchment = 0.0
            _remove_if_destroyed(state, army, messages)
            if army.id in state.armies:
                retreat = _retreat_destination(state, army, province_id, origins.get(army.id))
                if retreat:
                    army.province = retreat
                    army.supply = max(0.0, army.supply - config["retreat_supply_penalty"])
                else:
                    state.armies.pop(army.id, None)
                    message = f"{state.nations[army.nation].short} : le {army.name} est aneanti."
                    state.add_log("combat", message)
                    messages.append({"category": "combat", "message": message})
        for army in defenders:
            lost = _apply_losses(state, army, config["attacker_loss_ratio"] * max(0.6, 1.0 / loss_scale))
            army.morale = min(100.0, army.morale + config["morale_gain_victory"])
            army.entrenchment = min(0.3, army.entrenchment + 0.1)
            _remove_if_destroyed(state, army, messages)
        message = (
            f"L'offensive de {state.nations[lead_attacker].short} echoue a {province.name} "
            f"face a {state.nations[lead_defender].short}."
        )
    state.add_log("combat", message)
    messages.append({"category": "combat", "message": message})
    return messages


def resolve_movement(
    state: GameState,
    moves: list[dict[str, str]],
    rng: random.Random,
) -> list[dict[str, Any]]:
    """Resout tous les mouvements du tour de facon simultanee.

    ``moves`` contient des dictionnaires ``{"army": id, "to": province_id}``.
    Les mouvements invalides sont ignores et signales.
    """
    messages: list[dict[str, Any]] = []
    valid_moves: list[tuple[Army, str, str]] = []
    seen_armies: set[str] = set()
    for move in moves:
        army = state.armies.get(move.get("army", ""))
        if not army or army.id in seen_armies:
            continue
        destination = move.get("to", "")
        ok, reason = validate_move(state, army, destination)
        if not ok:
            message = f"Mouvement refuse pour {army.name} : {reason}"
            state.add_log("ordre", message)
            messages.append({"category": "ordre", "message": message})
            continue
        seen_armies.add(army.id)
        valid_moves.append((army, army.province, destination))

    # Les armees qui ne bougent pas se retranchent.
    moved_ids = {army.id for army, _, _ in valid_moves}
    for army in state.armies.values():
        if army.id not in moved_ids:
            army.entrenchment = min(0.3, army.entrenchment + 0.1)
            army.moved = False

    # Regroupement des attaques par province.
    arrivals: dict[str, list[Army]] = {}
    origins: dict[str, str] = {}
    for army, origin, destination in valid_moves:
        army.moved = True
        origins[army.id] = origin
        arrivals.setdefault(destination, []).append(army)

    for province_id, incoming in arrivals.items():
        province = state.provinces[province_id]
        hostile = [a for a in incoming if province.controller in state.nations[a.nation].wars]
        friendly = [a for a in incoming if a not in hostile]

        for army in friendly:
            army.province = province_id
            army.entrenchment = 0.0

        if not hostile:
            continue

        defenders = [
            a for a in state.armies.values()
            if a.province == province_id and a.nation not in {h.nation for h in hostile}
        ]
        # Les armees amies de la province defense sont les defenseurs naturels.
        defenders = [d for d in defenders if province.controller in (d.nation, *state.nations[d.nation].alliances)]
        if defenders:
            messages.extend(_resolve_battle(state, province_id, hostile, defenders, origins, rng))
        else:
            for army in hostile:
                army.province = province_id
                army.entrenchment = 0.0
            _capture(state, province, hostile[0].nation, messages)

    return messages


def supply_network(state: GameState, nation: Nation) -> set[str]:
    controlled = {p.id for p in state.provinces.values() if p.controller == nation.id}
    if not controlled:
        return set()
    allowed = set(controlled)
    for province in state.provinces.values():
        if province.controller == nation.id or _allied(state, nation.id, province.controller):
            allowed.add(province.id)
    queue = deque(controlled)
    reachable = set(controlled)
    while queue:
        current = queue.popleft()
        for neighbour in state.adjacency.get(current, []):
            if neighbour in allowed and neighbour not in reachable:
                reachable.add(neighbour)
                queue.append(neighbour)
    return reachable


def update_supply(state: GameState) -> list[dict[str, Any]]:
    config = load_config()["military"]
    messages: list[dict[str, Any]] = []
    for nation in state.nations.values():
        if nation.eliminated:
            continue
        network = supply_network(state, nation)
        gain = config["supply_gain_connected"] * supply_modifier(state, nation)
        for army in state.nation_armies(nation.id):
            if army.province in network:
                army.supply = min(config["supply_max"], army.supply + gain)
                army.morale = min(100.0, army.morale + 3.0)
            else:
                army.supply = max(0.0, army.supply - config["supply_loss_cutoff"])
                army.morale = max(0.0, army.morale - 2.0)
            if army.supply < config["attrition_threshold"] and army.regiments > 0:
                lost = _apply_losses(state, army, config["attrition_ratio"])
                _remove_if_destroyed(state, army, messages)
                if lost:
                    message = f"{nation.short} : attrition dans le {army.name} (ravitaillement {army.supply:.0f})."
                    state.add_log("ravitaillement", message)
                    messages.append({"category": "ravitaillement", "message": message})
    return messages


def visible_provinces(state: GameState, nation: Nation | None) -> set[str]:
    if nation is None:
        return set(state.provinces)
    visible = {p.id for p in state.provinces.values() if p.controller == nation.id}
    for province_id in list(visible):
        visible.update(state.adjacency.get(province_id, []))
    for army in state.armies.values():
        if army.nation == nation.id or army.nation in nation.alliances:
            visible.add(army.province)
    for province in state.provinces.values():
        if province.controller in nation.alliances:
            visible.add(province.id)
    return visible


def estimate_army(state: GameState, viewer: Nation | None, army: Army) -> dict[str, Any]:
    if viewer is None or viewer.id == army.nation or army.nation in viewer.alliances:
        return {
            "exact": True,
            "infantry": army.infantry,
            "artillery": army.artillery,
            "cavalry": army.cavalry,
            "power": round(army_power(state, army), 1),
        }
    confidence = max(0.0, min(1.0, (viewer.intelligence - 10.0) / 80.0))
    error = 1.0 + (1.0 - confidence) * 0.5
    base = regiment_power(army, state.nations[army.nation])
    estimate = base * error
    return {
        "exact": False,
        "regiments_estimate": max(1, int(round(army.regiments * error))),
        "power_estimate": round(estimate, 1),
        "confidence": round(confidence, 2),
    }
