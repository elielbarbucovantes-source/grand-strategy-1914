"""Economie mensuelle, construction et recrutement (H-003, H-004, H-020)."""

from __future__ import annotations

from typing import Any

from .effects import industry_total, manpower_modifier, production_modifier
from .model import Army, GameState, Nation
from .scenario import ROMAN, load_config


def can_pay(nation: Nation, cost: dict[str, float]) -> bool:
    for resource, amount in cost.items():
        if resource == "manpower":
            if nation.manpower < amount:
                return False
        elif nation.stock.get(resource, 0.0) < amount:
            return False
    return True


def pay(nation: Nation, cost: dict[str, float]) -> None:
    for resource, amount in cost.items():
        if resource == "manpower":
            nation.manpower -= amount
        else:
            nation.stock[resource] = nation.stock.get(resource, 0.0) - amount


def refund(nation: Nation, cost: dict[str, float]) -> None:
    for resource, amount in cost.items():
        if resource == "manpower":
            nation.manpower += amount
        else:
            nation.stock[resource] = nation.stock.get(resource, 0.0) + amount


def province_output(state: GameState, province) -> dict[str, float]:
    factor = 1.0 if province.controller == province.owner else 0.5
    return {
        "food": province.resource.get("food", 0) * factor,
        "raw": province.resource.get("raw", 0) * factor,
        "wealth": (province.resource.get("wealth", 0) + province.industry * 0.5) * factor,
    }


def national_production(state: GameState, nation: Nation) -> dict[str, float]:
    totals = {"food": 0.0, "raw": 0.0, "wealth": 0.0}
    for province in state.provinces.values():
        if province.controller != nation.id:
            continue
        output = province_output(state, province)
        for key in totals:
            totals[key] += output[key]
    for key in totals:
        totals[key] += float(nation.colonies.get(key, 0)) * 2.0
    modifier = production_modifier(state, nation)
    for key in totals:
        totals[key] *= modifier
    return totals


def national_consumption(state: GameState, nation: Nation) -> dict[str, float]:
    config = load_config()["economy"]
    regiments = sum(a.regiments for a in state.nation_armies(nation.id))
    return {
        "food": nation.population * config["food_per_population_million"] + regiments * config["food_per_regiment"],
        "raw": industry_total(state, nation) * config["raw_per_industry"],
        "wealth": regiments * config["army_upkeep_per_regiment"],
    }


def process_economy(state: GameState, nation: Nation) -> list[dict[str, Any]]:
    config = load_config()
    messages: list[dict[str, Any]] = []
    if nation.eliminated:
        return messages
    production = national_production(state, nation)
    consumption = national_consumption(state, nation)
    for resource in ("food", "raw", "wealth"):
        nation.stock[resource] = nation.stock.get(resource, 0.0) + production[resource] - consumption[resource]
        if nation.stock[resource] < 0:
            deficit = -nation.stock[resource]
            nation.stock[resource] = 0.0
            nation.stability = max(0.0, nation.stability - config["stability"]["shortage_penalty"])
            message = f"{nation.short} manque de {resource} ({deficit:.0f}). Stabilite en baisse."
            state.add_log("economie", message)
            messages.append({"category": "economie", "message": message})
    regen = nation.population * config["economy"]["manpower_per_million"] * config["economy"]["manpower_regen"] * manpower_modifier(state, nation)
    nation.manpower += regen
    return messages


def queue_construction(state: GameState, nation: Nation, province_id: str, kind: str) -> tuple[bool, str]:
    config = load_config()["economy"]
    province = state.provinces.get(province_id)
    if not province or province.controller != nation.id:
        return False, "Province non controlee."
    if kind not in ("industry", "fortification"):
        return False, "Type de construction inconnu."
    if len(nation.construction) >= config["max_construction_queue"]:
        return False, "File de construction pleine."
    if kind == "industry" and province.industry >= 6:
        return False, "Industrie deja au maximum dans cette province."
    if kind == "fortification" and province.fortification >= 4:
        return False, "Fortification deja au maximum dans cette province."
    cost = config["construction_cost"][kind]
    if not can_pay(nation, cost):
        return False, "Ressources insuffisantes."
    pay(nation, cost)
    nation.construction.append(
        {
            "province": province_id,
            "kind": kind,
            "turns_left": config["construction_turns"],
            "cost": dict(cost),
        }
    )
    return True, f"Construction lancee : {kind} a {province.name}."


def process_construction(state: GameState, nation: Nation) -> list[dict[str, Any]]:
    messages: list[dict[str, Any]] = []
    remaining: list[dict[str, Any]] = []
    for order in nation.construction:
        province = state.provinces.get(order["province"])
        if not province or province.controller != nation.id:
            refund(nation, order.get("cost", {}))
            message = f"Construction annulee a {order['province']} : province perdue."
            state.add_log("construction", message)
            messages.append({"category": "construction", "message": message})
            continue
        order["turns_left"] = int(order["turns_left"]) - 1
        if order["turns_left"] <= 0:
            if order["kind"] == "industry":
                province.industry = min(6, province.industry + 1)
            else:
                province.fortification = min(4, province.fortification + 1)
            message = f"{nation.short} acheve {order['kind']} a {province.name}."
            state.add_log("construction", message)
            messages.append({"category": "construction", "message": message})
        else:
            remaining.append(order)
    nation.construction = remaining
    return messages


def recruit_cost(unit: str) -> dict[str, float]:
    return dict(load_config()["economy"]["recruit_cost"][unit])


def queue_recruit(state: GameState, nation: Nation, province_id: str, unit: str, count: int = 1) -> tuple[bool, str]:
    config = load_config()["economy"]
    province = state.provinces.get(province_id)
    if not province or province.controller != nation.id:
        return False, "Province non controlee."
    if unit not in config["recruit_cost"]:
        return False, "Type d'unite inconnu."
    count = max(1, min(6, int(count)))
    if len(nation.recruits) + count > config["max_recruit_queue"]:
        return False, "File de recrutement pleine."
    total = {key: value * count for key, value in recruit_cost(unit).items()}
    if not can_pay(nation, total):
        return False, "Ressources ou main-d'oeuvre insuffisantes."
    pay(nation, total)
    nation.recruits.append(
        {
            "province": province_id,
            "unit": unit,
            "count": count,
            "turns_left": config["recruit_turns"],
            "cost": total,
        }
    )
    return True, f"Recrutement lance : {count} {unit} a {province.name}."


def _new_army(state: GameState, nation: Nation, province_id: str) -> Army:
    index = len(state.nation_armies(nation.id)) + 1
    army_id = f"{nation.id}_corps_{index}"
    while army_id in state.armies:
        index += 1
        army_id = f"{nation.id}_corps_{index}"
    army = Army(
        id=army_id,
        name=f"{ROMAN[(index - 1) % len(ROMAN)]}e corps",
        nation=nation.id,
        province=province_id,
        infantry=0,
        artillery=0,
        cavalry=0,
        supply=100.0,
        morale=80.0,
    )
    state.armies[army_id] = army
    return army


def process_recruits(state: GameState, nation: Nation) -> list[dict[str, Any]]:
    messages: list[dict[str, Any]] = []
    remaining: list[dict[str, Any]] = []
    for order in nation.recruits:
        province = state.provinces.get(order["province"])
        if not province or province.controller != nation.id:
            refund(nation, order.get("cost", {}))
            message = f"Recrutement annule a {order['province']} : province perdue."
            state.add_log("armee", message)
            messages.append({"category": "armee", "message": message})
            continue
        order["turns_left"] = int(order["turns_left"]) - 1
        if order["turns_left"] <= 0:
            armies = [a for a in state.nation_armies(nation.id) if a.province == order["province"]]
            army = armies[0] if armies else _new_army(state, nation, order["province"])
            count = int(order["count"])
            if order["unit"] == "infantry":
                army.infantry += count
            elif order["unit"] == "artillery":
                army.artillery += count
            else:
                army.cavalry += count
            message = f"{nation.short} incorpore {count} {order['unit']} a {province.name}."
            state.add_log("armee", message)
            messages.append({"category": "armee", "message": message})
        else:
            remaining.append(order)
    nation.recruits = remaining
    return messages


def development_index(state: GameState, nation: Nation) -> float:
    controlled = state.controlled_by(nation.id)
    if not controlled:
        return 0.0
    wealth = sum(p.resource.get("wealth", 0) + p.industry * 0.5 for p in controlled)
    wealth += float(nation.colonies.get("wealth", 0)) * 2
    per_capita = wealth / max(1.0, nation.population)
    industry = industry_total(state, nation)
    industry_ratio = min(1.0, industry / max(1.0, nation.population * 0.5))
    tech_ratio = min(1.0, len(nation.techs) / 20.0)
    stability_ratio = nation.stability / 100.0
    return round(
        0.35 * min(1.0, per_capita / 2.0)
        + 0.25 * stability_ratio
        + 0.25 * tech_ratio
        + 0.15 * industry_ratio,
        4,
    )
