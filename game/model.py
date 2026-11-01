"""Modeles de donnees du MVP Grand Strategy-1914.

Toutes les structures sont serialisables en JSON afin que la sauvegarde et le
chargement ne dependent d'aucune base de donnees. Les valeurs numeriques
proviennent de ``game/data/`` et sont des hypotheses (voir DECISIONS_PENDING.md).
"""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any

MONTHS = (
    "janvier", "fevrier", "mars", "avril", "mai", "juin",
    "juillet", "aout", "septembre", "octobre", "novembre", "decembre",
)


def _as_set(value: Any) -> set[str]:
    return set(value or [])


@dataclass
class Province:
    id: str
    name: str
    owner: str
    controller: str
    terrain: str
    resource: dict[str, int]
    industry: int
    fortification: int
    port: bool
    city: str
    strategic: int
    hexes: list[list[int]]
    unrest: float = 0.0

    def to_dict(self) -> dict[str, Any]:
        return {
            "id": self.id,
            "name": self.name,
            "owner": self.owner,
            "controller": self.controller,
            "terrain": self.terrain,
            "resource": dict(self.resource),
            "industry": self.industry,
            "fortification": self.fortification,
            "port": self.port,
            "city": self.city,
            "strategic": self.strategic,
            "hexes": [list(h) for h in self.hexes],
            "unrest": self.unrest,
        }

    @classmethod
    def from_dict(cls, data: dict[str, Any]) -> "Province":
        return cls(
            id=data["id"],
            name=data["name"],
            owner=data["owner"],
            controller=data.get("controller", data["owner"]),
            terrain=data["terrain"],
            resource=dict(data["resource"]),
            industry=int(data["industry"]),
            fortification=int(data["fortification"]),
            port=bool(data["port"]),
            city=data["city"],
            strategic=int(data["strategic"]),
            hexes=[list(h) for h in data["hexes"]],
            unrest=float(data.get("unrest", 0.0)),
        )


@dataclass
class Army:
    id: str
    name: str
    nation: str
    province: str
    infantry: int
    artillery: int
    cavalry: int
    supply: float = 100.0
    morale: float = 100.0
    entrenchment: float = 0.0
    moved: bool = False

    @property
    def regiments(self) -> int:
        return self.infantry + self.artillery + self.cavalry

    def to_dict(self) -> dict[str, Any]:
        return {
            "id": self.id,
            "name": self.name,
            "nation": self.nation,
            "province": self.province,
            "infantry": self.infantry,
            "artillery": self.artillery,
            "cavalry": self.cavalry,
            "supply": round(self.supply, 2),
            "morale": round(self.morale, 2),
            "entrenchment": round(self.entrenchment, 2),
            "moved": self.moved,
        }

    @classmethod
    def from_dict(cls, data: dict[str, Any]) -> "Army":
        return cls(
            id=data["id"],
            name=data["name"],
            nation=data["nation"],
            province=data["province"],
            infantry=int(data["infantry"]),
            artillery=int(data["artillery"]),
            cavalry=int(data["cavalry"]),
            supply=float(data.get("supply", 100.0)),
            morale=float(data.get("morale", 100.0)),
            entrenchment=float(data.get("entrenchment", 0.0)),
            moved=bool(data.get("moved", False)),
        )


@dataclass
class Treaty:
    id: str
    type: str
    a: str
    b: str
    signed_turn: int
    active: bool = True

    def involves(self, nation: str) -> bool:
        return nation in (self.a, self.b)

    def other(self, nation: str) -> str:
        return self.b if nation == self.a else self.a

    def to_dict(self) -> dict[str, Any]:
        return {
            "id": self.id,
            "type": self.type,
            "a": self.a,
            "b": self.b,
            "signed_turn": self.signed_turn,
            "active": self.active,
        }

    @classmethod
    def from_dict(cls, data: dict[str, Any]) -> "Treaty":
        return cls(
            id=data["id"],
            type=data["type"],
            a=data["a"],
            b=data["b"],
            signed_turn=int(data["signed_turn"]),
            active=bool(data.get("active", True)),
        )


@dataclass
class Nation:
    id: str
    name: str
    short: str
    adjective: str
    playable: bool
    color: str
    capital: str
    population: float
    stats: dict[str, int]
    personality: str
    ambitions: list[str]
    colonies: dict[str, int]
    army_quality: float
    navy_quality: float
    starting_alliances: list[str] = field(default_factory=list)
    relations: dict[str, int] = field(default_factory=dict)
    alliances: set[str] = field(default_factory=set)
    wars: set[str] = field(default_factory=set)
    stock: dict[str, float] = field(default_factory=dict)
    manpower: float = 0.0
    stability: float = 60.0
    prestige: float = 0.0
    intelligence: float = 20.0
    techs: list[str] = field(default_factory=list)
    research_tech: str | None = None
    research_progress: float = 0.0
    construction: list[dict[str, Any]] = field(default_factory=list)
    recruits: list[dict[str, Any]] = field(default_factory=list)
    eliminated: bool = False
    is_player: bool = False

    def at_war_with(self, other: str) -> bool:
        return other in self.wars

    def relation(self, other: str) -> int:
        return int(self.relations.get(other, 0))

    def has_tech(self, tech_id: str) -> bool:
        return tech_id in self.techs

    def to_dict(self) -> dict[str, Any]:
        return {
            "id": self.id,
            "name": self.name,
            "short": self.short,
            "adjective": self.adjective,
            "playable": self.playable,
            "color": self.color,
            "capital": self.capital,
            "population": self.population,
            "stats": dict(self.stats),
            "personality": self.personality,
            "ambitions": list(self.ambitions),
            "colonies": dict(self.colonies),
            "army_quality": self.army_quality,
            "navy_quality": self.navy_quality,
            "starting_alliances": list(self.starting_alliances),
            "relations": dict(self.relations),
            "alliances": sorted(self.alliances),
            "wars": sorted(self.wars),
            "stock": {k: round(v, 2) for k, v in self.stock.items()},
            "manpower": round(self.manpower, 1),
            "stability": round(self.stability, 1),
            "prestige": round(self.prestige, 1),
            "intelligence": round(self.intelligence, 1),
            "techs": list(self.techs),
            "research_tech": self.research_tech,
            "research_progress": round(self.research_progress, 2),
            "construction": [dict(item) for item in self.construction],
            "recruits": [dict(item) for item in self.recruits],
            "eliminated": self.eliminated,
            "is_player": self.is_player,
        }

    @classmethod
    def from_dict(cls, data: dict[str, Any]) -> "Nation":
        return cls(
            id=data["id"],
            name=data["name"],
            short=data["short"],
            adjective=data["adjective"],
            playable=bool(data["playable"]),
            color=data["color"],
            capital=data["capital"],
            population=float(data["population"]),
            stats={k: int(v) for k, v in data["stats"].items()},
            personality=data["personality"],
            ambitions=list(data["ambitions"]),
            colonies={k: int(v) for k, v in data["colonies"].items()},
            army_quality=float(data["army_quality"]),
            navy_quality=float(data["navy_quality"]),
            starting_alliances=list(data.get("starting_alliances", [])),
            relations={k: int(v) for k, v in data.get("relations", {}).items()},
            alliances=_as_set(data.get("alliances")),
            wars=_as_set(data.get("wars")),
            stock={k: float(v) for k, v in data.get("stock", {}).items()},
            manpower=float(data.get("manpower", 0.0)),
            stability=float(data.get("stability", 60.0)),
            prestige=float(data.get("prestige", 0.0)),
            intelligence=float(data.get("intelligence", 20.0)),
            techs=list(data.get("techs", [])),
            research_tech=data.get("research_tech"),
            research_progress=float(data.get("research_progress", 0.0)),
            construction=[dict(item) for item in data.get("construction", [])],
            recruits=[dict(item) for item in data.get("recruits", [])],
            eliminated=bool(data.get("eliminated", False)),
            is_player=bool(data.get("is_player", False)),
        )


@dataclass
class GameState:
    version: int
    seed: int
    turn: int
    year: int
    month: int
    player_nation: str | None
    nations: dict[str, Nation]
    provinces: dict[str, Province]
    armies: dict[str, Army]
    adjacency: dict[str, list[str]]
    treaties: list[Treaty] = field(default_factory=list)
    scheduled_events: list[dict[str, Any]] = field(default_factory=list)
    pending_events: list[dict[str, Any]] = field(default_factory=list)
    fired_events: list[str] = field(default_factory=list)
    event_cooldowns: dict[str, int] = field(default_factory=dict)
    flags: dict[str, Any] = field(default_factory=dict)
    log: list[dict[str, Any]] = field(default_factory=list)
    report: list[dict[str, Any]] = field(default_factory=list)
    victory: dict[str, Any] | None = None
    economic_leader_streak: dict[str, int] = field(default_factory=dict)

    def date_label(self) -> str:
        return f"{MONTHS[self.month - 1]} {self.year}"

    def next_month(self) -> None:
        self.turn += 1
        self.month += 1
        if self.month > 12:
            self.month = 1
            self.year += 1

    def nation_armies(self, nation: str) -> list[Army]:
        return [a for a in self.armies.values() if a.nation == nation]

    def provinces_of(self, nation: str) -> list[Province]:
        return [p for p in self.provinces.values() if p.owner == nation]

    def controlled_by(self, nation: str) -> list[Province]:
        return [p for p in self.provinces.values() if p.controller == nation]

    def add_log(self, category: str, message: str) -> None:
        self.log.append({"turn": self.turn, "date": self.date_label(), "category": category, "message": message})
        if len(self.log) > 400:
            del self.log[:100]

    def to_dict(self) -> dict[str, Any]:
        return {
            "version": self.version,
            "seed": self.seed,
            "turn": self.turn,
            "year": self.year,
            "month": self.month,
            "player_nation": self.player_nation,
            "nations": {k: v.to_dict() for k, v in self.nations.items()},
            "provinces": {k: v.to_dict() for k, v in self.provinces.items()},
            "armies": {k: v.to_dict() for k, v in self.armies.items()},
            "adjacency": {k: list(v) for k, v in self.adjacency.items()},
            "treaties": [t.to_dict() for t in self.treaties],
            "scheduled_events": [dict(e) for e in self.scheduled_events],
            "pending_events": [dict(e) for e in self.pending_events],
            "fired_events": list(self.fired_events),
            "event_cooldowns": dict(self.event_cooldowns),
            "flags": dict(self.flags),
            "log": list(self.log),
            "report": list(self.report),
            "victory": dict(self.victory) if self.victory else None,
            "economic_leader_streak": dict(self.economic_leader_streak),
        }

    @classmethod
    def from_dict(cls, data: dict[str, Any]) -> "GameState":
        return cls(
            version=int(data.get("version", 1)),
            seed=int(data["seed"]),
            turn=int(data["turn"]),
            year=int(data["year"]),
            month=int(data["month"]),
            player_nation=data.get("player_nation"),
            nations={k: Nation.from_dict(v) for k, v in data["nations"].items()},
            provinces={k: Province.from_dict(v) for k, v in data["provinces"].items()},
            armies={k: Army.from_dict(v) for k, v in data["armies"].items()},
            adjacency={k: list(v) for k, v in data["adjacency"].items()},
            treaties=[Treaty.from_dict(t) for t in data.get("treaties", [])],
            scheduled_events=[dict(e) for e in data.get("scheduled_events", [])],
            pending_events=[dict(e) for e in data.get("pending_events", [])],
            fired_events=list(data.get("fired_events", [])),
            event_cooldowns={k: int(v) for k, v in data.get("event_cooldowns", {}).items()},
            flags=dict(data.get("flags", {})),
            log=list(data.get("log", [])),
            report=list(data.get("report", [])),
            victory=dict(data["victory"]) if data.get("victory") else None,
            economic_leader_streak={k: int(v) for k, v in data.get("economic_leader_streak", {}).items()},
        )
