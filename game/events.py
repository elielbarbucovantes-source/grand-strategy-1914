"""Evenements historiques et generiques (H-015)."""

from __future__ import annotations

import random
from typing import Any

from . import diplomacy
from .model import GameState, Nation
from .scenario import load_events


def event_catalog() -> dict[str, dict[str, Any]]:
    return {event["id"]: event for event in load_events()}


def _resolve_target_token(state: GameState, value: str, target: str | None) -> str:
    if value == "$target":
        return target or ""
    return value


def _conditions_met(state: GameState, event: dict[str, Any], target: str | None) -> bool:
    for condition in event.get("trigger", {}).get("conditions", []):
        kind = condition.get("type")
        if kind == "flag":
            if bool(state.flags.get(condition["name"])) != bool(condition.get("value", True)):
                return False
        elif kind == "at_war":
            a = _resolve_target_token(state, condition["a"], target)
            b = _resolve_target_token(state, condition["b"], target)
            if a not in state.nations or b not in state.nations:
                return False
            if b not in state.nations[a].wars:
                return False
        elif kind == "not_at_war":
            a = _resolve_target_token(state, condition["a"], target)
            b = _resolve_target_token(state, condition["b"], target)
            if a in state.nations and b in state.nations and b in state.nations[a].wars:
                return False
        elif kind == "relation_below":
            a = _resolve_target_token(state, condition["a"], target)
            b = _resolve_target_token(state, condition["b"], target)
            if a not in state.nations or b not in state.nations:
                return False
            if state.nations[a].relation(b) >= int(condition["value"]):
                return False
        elif kind == "stability_below":
            nation_id = _resolve_target_token(state, condition["nation"], target)
            if nation_id not in state.nations or state.nations[nation_id].stability >= float(condition["value"]):
                return False
        elif kind == "turn_min":
            if state.turn < int(condition["value"]):
                return False
        elif kind == "nation_alive":
            nation_id = _resolve_target_token(state, condition["nation"], target)
            if nation_id not in state.nations or state.nations[nation_id].eliminated:
                return False
    return True


def _pick_target(state: GameState, event: dict[str, Any], rng: random.Random) -> str | None:
    target = event.get("target")
    if target not in (None, "random_all", "random_major"):
        return target
    pool = [
        n for n in state.nations.values()
        if not n.eliminated and (target != "random_major" or n.playable)
    ]
    if not pool:
        return None
    return rng.choice(pool).id


def _apply_effects(state: GameState, effects: list[dict[str, Any]], target: str | None) -> None:
    for effect in effects:
        kind = effect.get("type")
        if kind == "relation":
            a = _resolve_target_token(state, effect["from"], target)
            b = _resolve_target_token(state, effect["to"], target)
            diplomacy.change_relation(state, a, b, int(effect["delta"]))
        elif kind == "relation_all":
            a = _resolve_target_token(state, effect["from"], target)
            if a not in state.nations:
                continue
            for other in state.nations:
                if other != a:
                    diplomacy.change_relation(state, a, other, int(effect["delta"]))
        elif kind == "stability":
            nation = state.nations.get(_resolve_target_token(state, effect["nation"], target))
            if nation:
                nation.stability = max(0.0, min(100.0, nation.stability + float(effect["delta"])))
        elif kind == "prestige":
            nation = state.nations.get(_resolve_target_token(state, effect["nation"], target))
            if nation:
                nation.prestige = max(0.0, nation.prestige + float(effect["delta"]))
        elif kind == "stock":
            nation = state.nations.get(_resolve_target_token(state, effect["nation"], target))
            if nation:
                resource = effect["resource"]
                nation.stock[resource] = max(0.0, nation.stock.get(resource, 0.0) + float(effect["delta"]))
        elif kind == "research":
            nation = state.nations.get(_resolve_target_token(state, effect["nation"], target))
            if nation:
                nation.research_progress += float(effect["delta"])
        elif kind == "manpower":
            nation = state.nations.get(_resolve_target_token(state, effect["nation"], target))
            if nation:
                nation.manpower = max(0.0, nation.manpower + float(effect["delta"]))
        elif kind == "war":
            attacker = state.nations.get(_resolve_target_token(state, effect["attacker"], target))
            defender_id = _resolve_target_token(state, effect["defender"], target)
            if attacker and defender_id in state.nations and defender_id not in attacker.wars:
                diplomacy.declare_war(state, attacker, defender_id)
        elif kind == "alliance":
            a = _resolve_target_token(state, effect["a"], target)
            b = _resolve_target_token(state, effect["b"], target)
            if a in state.nations and b in state.nations:
                diplomacy.add_treaty(state, "alliance", a, b)
        elif kind == "flag":
            state.flags[effect["name"]] = effect.get("value", True)


def _schedule(state: GameState, event: dict[str, Any], option: dict[str, Any] | None, target: str | None) -> None:
    entries = event.get("schedule", [])
    if option:
        entries = entries + option.get("schedule", [])
    for entry in entries:
        due = state.turn + int(entry.get("delay", 1))
        scheduled_target = entry.get("target", target)
        state.scheduled_events.append(
            {"event": entry["event"], "turn": due, "target": scheduled_target}
        )


def _choose_ai_option(event: dict[str, Any], rng: random.Random) -> dict[str, Any]:
    options = event.get("options", [])
    if not options:
        return {}
    weights = [max(0.01, float(option.get("ai_weight", 1.0))) for option in options]
    return rng.choices(options, weights=weights, k=1)[0]


def _fire_event(
    state: GameState,
    event: dict[str, Any],
    target: str | None,
    rng: random.Random,
) -> list[dict[str, Any]]:
    messages: list[dict[str, Any]] = []
    options = event.get("options", [])
    if options:
        target_nation = state.nations.get(target or "")
        if target_nation and target_nation.is_player and state.player_nation == target_nation.id:
            if any(p["id"] == event["id"] for p in state.pending_events):
                return messages
            state.pending_events.append(
                {
                    "id": event["id"],
                    "title": event["title"],
                    "text": event["text"],
                    "target": target,
                    "created_turn": state.turn,
                    "expires_turn": state.turn + 2,
                    "default_option": event.get("default_option", options[0]["id"]),
                    "options": [
                        {
                            "id": option["id"],
                            "label": option["label"],
                            "description": option.get("description", ""),
                        }
                        for option in options
                    ],
                }
            )
            message = f"Decision en attente : {event['title']}."
            state.add_log("evenement", message)
            messages.append({"category": "evenement", "message": message})
            return messages
        option = _choose_ai_option(event, rng)
        _apply_effects(state, option.get("effects", []), target)
        _schedule(state, event, option, target)
        message = f"{event['title']} : {option.get('label', 'decision automatique')}."
        state.add_log("evenement", message)
        messages.append({"category": "evenement", "message": message})
    else:
        _apply_effects(state, event.get("effects", []), target)
        message = f"{event['title']}."
        state.add_log("evenement", message)
        messages.append({"category": "evenement", "message": message})
    state.fired_events.append(event["id"])
    return messages


def resolve_pending_events(
    state: GameState,
    choices: dict[str, str],
    rng: random.Random,
) -> list[dict[str, Any]]:
    """Applique les choix du joueur et les decisions par defaut arrivees a echeance."""
    messages: list[dict[str, Any]] = []
    catalog = event_catalog()
    remaining: list[dict[str, Any]] = []
    for pending in state.pending_events:
        event = catalog.get(pending["id"])
        if not event:
            continue
        choice_id = choices.get(pending["id"])
        if choice_id is None and state.turn <= int(pending.get("expires_turn", state.turn)):
            remaining.append(pending)
            continue
        if choice_id is None:
            choice_id = pending.get("default_option")
        option = next((o for o in event.get("options", []) if o["id"] == choice_id), None)
        if option is None:
            option = next((o for o in event.get("options", []) if o["id"] == pending.get("default_option")), event.get("options", [{}])[0])
        _apply_effects(state, option.get("effects", []), pending.get("target"))
        _schedule(state, event, option, pending.get("target"))
        message = f"{event['title']} : {option.get('label', choice_id)}."
        state.add_log("evenement", message)
        messages.append({"category": "evenement", "message": message})
    state.pending_events = remaining
    return messages


def trigger_events(state: GameState, rng: random.Random) -> list[dict[str, Any]]:
    messages: list[dict[str, Any]] = []
    catalog = event_catalog()

    due = [entry for entry in state.scheduled_events if int(entry["turn"]) <= state.turn]
    state.scheduled_events = [entry for entry in state.scheduled_events if int(entry["turn"]) > state.turn]
    for entry in due:
        event = catalog.get(entry["event"])
        if not event:
            continue
        target = entry.get("target") or _pick_target(state, event, rng)
        if not _conditions_met(state, event, target):
            continue
        messages.extend(_fire_event(state, event, target, rng))

    for event in catalog.values():
        trigger = event.get("trigger", {})
        if trigger.get("scheduled"):
            continue
        if event["id"] in state.fired_events and trigger.get("once", True):
            continue
        if "turn" in trigger:
            if state.turn != int(trigger["turn"]):
                continue
        elif "chance" in trigger:
            if state.turn < 1:
                continue
            cooldown = int(trigger.get("cooldown", 0))
            if state.turn < int(state.event_cooldowns.get(event["id"], 0)):
                continue
            if rng.random() > float(trigger["chance"]):
                continue
        else:
            continue
        target = _pick_target(state, event, rng)
        if target is None or target not in state.nations or state.nations[target].eliminated:
            continue
        if not _conditions_met(state, event, target):
            continue
        messages.extend(_fire_event(state, event, target, rng))
        if "chance" in trigger:
            state.event_cooldowns[event["id"]] = state.turn + int(trigger.get("cooldown", 0))

    return messages
