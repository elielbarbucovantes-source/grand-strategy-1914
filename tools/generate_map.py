#!/usr/bin/env python3
"""Génère l'atlas provisoire hexagonal du MVP.

Le tracé est volontairement stylisé : il ne remplace pas l'atlas définitif
à valider par le propriétaire (H-002). Le script est déterministe et ne
dépend que de la bibliothèque standard.
"""
from __future__ import annotations

import json
import unicodedata
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "game" / "data" / "map.json"

COLS = 38
ROWS = 26

# Polygones de pays en coordonnées normalisées (x ouest->est, y nord->sud).
# L'ordre de priorité va des petits pays vers les grands, pour que les
# enclaves et les pays tampons ne soient pas absorbés.
COUNTRIES: dict[str, list[tuple[float, float]]] = {
    "luxembourg": [(32.5, 38.5), (35.5, 38.5), (35.5, 41.5), (32.5, 41.5)],
    "belgium": [(30, 34), (34, 34), (35, 38), (31, 39), (29, 37)],
    "netherlands": [(31, 27), (36, 27), (38, 32), (35, 35), (31, 33)],
    "denmark": [(36, 25), (40, 25), (41, 30), (38, 32), (35, 29)],
    "switzerland": [(31, 45), (37, 45), (39, 51), (35, 54), (30, 51)],
    "portugal": [(3, 68), (7, 68), (7, 80), (4, 82), (2, 76)],
    "montenegro": [(47.5, 63.5), (51.5, 63.5), (51.5, 67.5), (47.5, 67.5)],
    "albania": [(49, 68), (53, 68), (54, 72), (50, 73), (48, 70)],
    "serbia": [(51, 57), (56, 57), (57, 63), (53, 66), (50, 62), (49, 59)],
    "greece": [(53, 73), (59, 73), (61, 79), (58, 85), (54, 83), (52, 78)],
    "bulgaria": [(56, 61), (62, 61), (64, 66), (61, 70), (57, 69), (55, 65)],
    "romania": [(56, 47), (62, 46), (65, 51), (64, 57), (60, 60), (56, 57), (54, 52)],
    "italy": [(35, 55), (39, 55), (41, 60), (44, 66), (43, 73), (39, 79), (36, 76), (34, 68), (33, 61)],
    "italy_sicily": [(37, 82), (41, 82), (41, 85), (37, 85)],
    "italy_sardinia": [(30, 71), (32, 71), (32, 75), (30, 75)],
    "austria": [(43, 43), (50, 41), (56, 42), (60, 47), (59, 54), (55, 60), (48, 62), (43, 57), (41, 50)],
    "austria_bohemia": [(41, 41), (46, 41), (47, 46), (42, 47)],
    "germany": [(35, 25), (43, 24), (45, 31), (47, 38), (45, 45), (39, 48), (34, 44), (32, 37), (33, 30)],
    "germany_east_prussia": [(47, 23), (52, 22), (54, 28), (50, 31), (46, 28)],
    "uk": [(13, 20), (19, 19), (22, 25), (21, 33), (18, 38), (14, 36), (12, 30), (11, 24)],
    "ireland": [(7, 25), (11, 25), (12, 31), (9, 34), (6, 31), (5, 27)],
    "france": [(20, 37), (29, 36), (33, 41), (34, 48), (32, 55), (28, 61), (21, 62), (17, 56), (16, 49), (17, 43)],
    "france_brittany": [(14, 45), (18, 46), (17, 51), (13, 49)],
    "spain": [(8, 63), (21, 62), (24, 69), (22, 78), (17, 84), (11, 85), (6, 78), (6, 70)],
    "norway": [(36, 6), (42, 4), (46, 10), (45, 18), (42, 24), (38, 26), (34, 22), (33, 14), (34, 9)],
    "sweden": [(43, 4), (50, 4), (53, 10), (52, 18), (49, 25), (44, 26), (41, 22), (43, 14), (42, 8)],
    "russia": [(54, 12), (100, 10), (100, 52), (80, 54), (70, 50), (64, 46), (60, 42), (58, 36), (56, 30), (54, 24), (52, 18)],
    "russia_finland": [(50, 4), (57, 3), (60, 10), (58, 18), (54, 22), (49, 20), (48, 12)],
    "russia_caucasus": [(70, 55), (85, 55), (88, 62), (80, 65), (70, 62)],
    "ottoman": [(61, 67), (68, 65), (76, 66), (83, 70), (85, 78), (80, 85), (72, 88), (64, 86), (60, 79), (59, 72)],
    "ottoman_thrace": [(58, 67), (62, 67), (62, 71), (58, 71)],
}

# Corrections manuelles de couverture : comble les trous entre polygones qui
# coupent des frontieres importantes (ici la frontiere Alsace-Bade).
MANUAL_HEXES: dict[tuple[int, int], str] = {
    (12, 11): "germany",
}

# Priorité d'attribution : les petits pays d'abord.
PRIORITY = [
    "luxembourg", "belgium", "netherlands", "denmark", "switzerland",
    "portugal", "montenegro", "albania", "serbia", "greece", "bulgaria",
    "romania", "italy_sicily", "italy_sardinia", "italy",
    "austria_bohemia", "austria", "germany_east_prussia", "germany",
    "ireland", "uk", "france_brittany", "france", "spain",
    "norway", "sweden", "russia_finland", "russia_caucasus", "russia",
    "ottoman_thrace", "ottoman",
]

# Graines de provinces : (nom, x, y, terrain, fortification, ville, stratégique)
SEEDS: dict[str, list[tuple[str, float, float, str, int, str, int]]] = {
    "germany": [
        ("Brandebourg", 40, 31, "plains", 1, "Berlin", 5),
        ("Poméranie", 44, 27, "coastal", 0, "Stettin", 3),
        ("Silésie", 46, 37, "hills", 1, "Breslau", 4),
        ("Saxe", 39, 37, "hills", 0, "Dresde", 3),
        ("Rhénanie", 34, 36, "urban", 2, "Cologne", 5),
        ("Westphalie", 36, 33, "urban", 0, "Essen", 4),
        ("Bavière", 39, 43, "hills", 1, "Munich", 4),
        ("Wurtemberg", 36, 41, "forest", 0, "Stuttgart", 3),
        ("Prusse-Orientale", 50, 26, "plains", 1, "Königsberg", 4),
        ("Schleswig-Holstein", 37, 27, "coastal", 0, "Kiel", 3),
    ],
    "uk": [
        ("Londres", 18, 30, "urban", 2, "Londres", 5),
        ("Sud-Est", 19, 34, "plains", 0, "Douvres", 4),
        ("Midlands", 17, 28, "urban", 0, "Birmingham", 4),
        ("Pays de Galles", 15, 30, "hills", 0, "Cardiff", 2),
        ("Nord de l'Angleterre", 17, 25, "hills", 0, "Manchester", 4),
        ("Écosse", 15, 21, "hills", 0, "Édimbourg", 3),
        ("Irlande", 8, 29, "plains", 0, "Dublin", 2),
    ],
    "france": [
        ("Île-de-France", 24, 43, "urban", 1, "Paris", 5),
        ("Normandie", 20, 42, "coastal", 0, "Rouen", 3),
        ("Bretagne", 15, 47, "coastal", 0, "Brest", 3),
        ("Champagne", 27, 42, "plains", 1, "Reims", 3),
        ("Alsace-Lorraine", 31, 42, "forest", 3, "Metz", 5),
        ("Bourgogne", 26, 47, "hills", 0, "Dijon", 2),
        ("Aquitaine", 21, 54, "plains", 0, "Bordeaux", 3),
        ("Occitanie", 24, 58, "hills", 0, "Toulouse", 2),
        ("Provence", 30, 57, "coastal", 1, "Marseille", 3),
        ("Rhône", 28, 51, "plains", 0, "Lyon", 3),
    ],
    "russia": [
        ("Saint-Pétersbourg", 58, 20, "coastal", 2, "Saint-Pétersbourg", 5),
        ("Moscou", 68, 24, "urban", 1, "Moscou", 5),
        ("Pologne", 55, 34, "plains", 2, "Varsovie", 5),
        ("Baltique", 56, 28, "forest", 0, "Riga", 3),
        ("Biélorussie", 62, 32, "marsh", 0, "Minsk", 2),
        ("Ukraine", 68, 40, "plains", 0, "Kiev", 4),
        ("Crimée", 72, 48, "coastal", 1, "Sébastopol", 4),
        ("Bessarabie", 64, 47, "plains", 0, "Kichinev", 2),
        ("Finlande", 55, 12, "forest", 0, "Helsinki", 2),
        ("Caucase", 78, 58, "mountains", 1, "Tiflis", 3),
    ],
    "austria": [
        ("Bohême", 44, 44, "hills", 1, "Prague", 4),
        ("Vienne", 48, 48, "urban", 1, "Vienne", 5),
        ("Tyrol", 43, 52, "mountains", 1, "Innsbruck", 3),
        ("Hongrie", 53, 51, "plains", 0, "Budapest", 5),
        ("Slovaquie", 51, 46, "hills", 0, "Bratislava", 2),
        ("Transylvanie", 57, 53, "mountains", 1, "Cluj", 3),
        ("Croatie", 51, 57, "hills", 0, "Zagreb", 3),
        ("Bosnie", 52, 61, "mountains", 1, "Sarajevo", 4),
        ("Galicie", 57, 44, "plains", 1, "Lemberg", 3),
        ("Dalmatie", 49, 61, "coastal", 0, "Split", 2),
    ],
    "italy": [
        ("Piémont", 36, 58, "hills", 1, "Turin", 4),
        ("Lombardie", 39, 58, "urban", 1, "Milan", 5),
        ("Vénétie", 41, 61, "plains", 1, "Venise", 4),
        ("Toscane", 39, 65, "hills", 0, "Florence", 3),
        ("Rome", 40, 70, "urban", 1, "Rome", 5),
        ("Naples", 42, 75, "coastal", 1, "Naples", 4),
        ("Sicile", 39, 83, "coastal", 0, "Palerme", 2),
        ("Sardaigne", 31, 73, "hills", 0, "Cagliari", 1),
    ],
    "ottoman": [
        ("Constantinople", 60, 69, "urban", 2, "Constantinople", 5),
        ("Thrace", 60, 72, "plains", 1, "Andrinople", 3),
        ("Anatolie", 69, 74, "hills", 0, "Ankara", 4),
        ("Smyrne", 66, 79, "coastal", 1, "Smyrne", 4),
        ("Syrie", 72, 84, "coastal", 0, "Damas", 3),
        ("Mésopotamie", 80, 83, "plains", 0, "Bagdad", 3),
        ("Palestine", 74, 88, "coastal", 0, "Jérusalem", 2),
    ],
    "spain": [
        ("Madrid", 14, 72, "plains", 1, "Madrid", 4),
        ("Catalogne", 20, 69, "coastal", 1, "Barcelone", 4),
        ("Andalousie", 13, 80, "plains", 0, "Séville", 3),
        ("Galice", 8, 68, "coastal", 0, "La Corogne", 2),
        ("Pays basque", 17, 67, "hills", 0, "Bilbao", 3),
        ("Valence", 18, 75, "coastal", 0, "Valence", 2),
    ],
    "portugal": [
        ("Lisbonne", 5, 74, "coastal", 1, "Lisbonne", 4),
        ("Porto", 4, 69, "hills", 0, "Porto", 2),
    ],
    "belgium": [
        ("Flandres", 32, 36, "urban", 1, "Bruxelles", 4),
        ("Wallonie", 33, 38, "hills", 1, "Liège", 3),
    ],
    "netherlands": [
        ("Hollande", 34, 30, "coastal", 1, "Amsterdam", 4),
        ("Brabant", 35, 33, "plains", 0, "Rotterdam", 3),
    ],
    "switzerland": [
        ("Berne", 34, 48, "mountains", 2, "Berne", 3),
        ("Zurich", 37, 48, "mountains", 1, "Zurich", 2),
    ],
    "denmark": [
        ("Jutland", 37, 28, "coastal", 0, "Copenhague", 3),
        ("Zélande", 39, 30, "plains", 0, "Aarhus", 2),
    ],
    "sweden": [
        ("Stockholm", 47, 12, "coastal", 1, "Stockholm", 4),
        ("Göteborg", 44, 18, "forest", 0, "Göteborg", 2),
        ("Norrland", 49, 7, "forest", 0, "Luleå", 1),
    ],
    "norway": [
        ("Oslo", 39, 14, "coastal", 0, "Oslo", 3),
        ("Bergen", 36, 18, "mountains", 0, "Bergen", 2),
        ("Trondheim", 40, 8, "forest", 0, "Trondheim", 1),
    ],
    "serbia": [
        ("Belgrade", 53, 59, "plains", 1, "Belgrade", 4),
        ("Niš", 55, 63, "hills", 0, "Niš", 2),
    ],
    "romania": [
        ("Valachie", 59, 54, "plains", 1, "Bucarest", 4),
        ("Moldavie", 62, 49, "hills", 0, "Iași", 2),
    ],
    "bulgaria": [
        ("Sofia", 59, 64, "hills", 1, "Sofia", 4),
        ("Roumelie", 62, 67, "plains", 0, "Plovdiv", 2),
    ],
    "greece": [
        ("Athènes", 57, 78, "coastal", 1, "Athènes", 4),
        ("Thessalie", 55, 75, "hills", 0, "Larissa", 2),
        ("Péloponnèse", 55, 82, "hills", 0, "Patras", 2),
    ],
    "montenegro": [("Cetinje", 49, 65, "mountains", 0, "Cetinje", 1)],
    "albania": [("Tirana", 51, 70, "mountains", 0, "Tirana", 1)],
    "luxembourg": [("Luxembourg", 34, 40, "hills", 1, "Luxembourg", 2)],
}

# Profils de ressources par terrain : (nourriture, matières premières, richesse)
TERRAIN_RESOURCES = {
    "plains": (3, 1, 2),
    "farmland": (3, 1, 2),
    "forest": (2, 2, 1),
    "hills": (1, 3, 2),
    "mountains": (1, 2, 2),
    "marsh": (2, 1, 1),
    "coastal": (2, 1, 3),
    "urban": (1, 2, 3),
}

TERRAIN_INDUSTRY = {
    "plains": 1,
    "farmland": 1,
    "forest": 1,
    "hills": 2,
    "mountains": 0,
    "marsh": 0,
    "coastal": 2,
    "urban": 3,
}

COUNTRY_CODES = {
    "germany": "G", "uk": "U", "france": "F", "russia": "R",
    "austria": "A", "italy": "I", "ottoman": "O",
    "belgium": "b", "netherlands": "n", "switzerland": "s",
    "spain": "e", "portugal": "p", "sweden": "w", "norway": "y",
    "denmark": "d", "serbia": "v", "romania": "m", "bulgaria": "l",
    "greece": "h", "montenegro": "c", "albania": "a", "luxembourg": "x",
}


def slug(text: str) -> str:
    out = unicodedata.normalize("NFKD", text).encode("ascii", "ignore").decode("ascii")
    out = out.lower()
    for char in " '-":
        out = out.replace(char, "_")
    return out


COUNTRY_ALIASES = {
    "ireland": "uk",
    "italy_sicily": "italy",
    "italy_sardinia": "italy",
    "austria_bohemia": "austria",
    "germany_east_prussia": "germany",
    "france_brittany": "france",
    "russia_finland": "russia",
    "russia_caucasus": "russia",
    "ottoman_thrace": "ottoman",
}

PORT_CITIES = {
    "Londres", "Douvres", "Brest", "Marseille", "Rouen", "Bordeaux",
    "Amsterdam", "Rotterdam", "Copenhague", "Aarhus",
    "Stockholm", "Göteborg", "Oslo", "Bergen", "Saint-Pétersbourg",
    "Riga", "Sébastopol", "Helsinki", "Constantinople", "Smyrne", "Athènes",
    "Patras", "Naples", "Palerme", "Cagliari", "Barcelone", "Séville",
    "Valence", "Lisbonne", "Porto", "Venise", "Split",
}


def point_in_polygon(x: float, y: float, poly: list[tuple[float, float]]) -> bool:
    inside = False
    j = len(poly) - 1
    for i, (xi, yi) in enumerate(poly):
        xj, yj = poly[j]
        if ((yi > y) != (yj > y)) and (x < (xj - xi) * (y - yi) / (yj - yi) + xi):
            inside = not inside
        j = i
    return inside


def hex_center(q: int, r: int) -> tuple[float, float]:
    x = (q + 0.5 * (r & 1) + 0.5) / COLS * 100.0
    y = (r + 0.5) / ROWS * 100.0
    return x, y


def neighbors(q: int, r: int) -> list[tuple[int, int]]:
    if r & 1:
        deltas = [(1, 0), (0, -1), (-1, -1), (-1, 0), (-1, 1), (0, 1)]
    else:
        deltas = [(1, 0), (1, -1), (0, -1), (-1, 0), (0, 1), (1, 1)]
    return [(q + dq, r + dr) for dq, dr in deltas if 0 <= q + dq < COLS and 0 <= r + dr < ROWS]


def main() -> None:
    hex_country: dict[tuple[int, int], str] = {}
    for r in range(ROWS):
        for q in range(COLS):
            x, y = hex_center(q, r)
            for key in PRIORITY:
                if point_in_polygon(x, y, COUNTRIES[key]):
                    hex_country[(q, r)] = COUNTRY_ALIASES.get(key, key)
                    break
    for cell, country in MANUAL_HEXES.items():
        hex_country[cell] = country

    # Attribution des hexes aux provinces par plus proche graine du pays.
    province_hexes: dict[str, list[tuple[int, int]]] = {}
    province_meta: dict[str, dict] = {}
    for country, seeds in SEEDS.items():
        cells = [c for c, owner in hex_country.items() if owner == country]
        if not cells:
            continue
        for name, sx, sy, terrain, fort, city, strategic in seeds:
            province_hexes[f"{country}:{name}"] = []
            province_meta[f"{country}:{name}"] = {
                "name": name, "terrain": terrain, "fort": fort,
                "city": city, "strategic": strategic,
            }
        for q, r in cells:
            x, y = hex_center(q, r)
            best = min(
                seeds,
                key=lambda s: (x - s[1]) ** 2 + (y - s[2]) ** 2,
            )
            province_hexes[f"{country}:{best[0]}"].append((q, r))

    provinces = []
    for key, cells in province_hexes.items():
        if not cells:
            continue
        country, name = key.split(":", 1)
        meta = province_meta[key]
        terrain = meta["terrain"]
        food, raw, wealth = TERRAIN_RESOURCES[terrain]
        province_id = f"{country}_{slug(name)}"
        coastal = any(hex_country.get(n) is None for cell in cells for n in neighbors(*cell))
        provinces.append({
            "id": province_id,
            "name": name,
            "owner": country,
            "terrain": terrain,
            "hexes": [[q, r] for q, r in cells],
            "resource": {"food": food, "raw": raw, "wealth": wealth},
            "industry": TERRAIN_INDUSTRY[terrain] + (1 if meta["strategic"] >= 5 else 0),
            "fortification": meta["fort"],
            "port": bool(meta["city"] in PORT_CITIES and coastal),
            "city": meta["city"],
            "strategic": meta["strategic"],
        })

    # Index des hexes -> province.
    hex_to_province = {}
    for prov in provinces:
        for q, r in prov["hexes"]:
            hex_to_province[(q, r)] = prov["id"]

    # Adjacence par contact de hexes.
    adjacency: dict[str, set[str]] = {p["id"]: set() for p in provinces}
    for (q, r), pid in hex_to_province.items():
        for n in neighbors(q, r):
            other = hex_to_province.get(n)
            if other and other != pid:
                adjacency[pid].add(other)
    for pid in adjacency:
        adjacency[pid] = sorted(adjacency[pid])

    # Carte ASCII de contrôle.
    print("Carte ASCII (G=Allemagne, U=RU, F=France, R=Russie, A=Autriche, I=Italie, O=Ottoman, .=mer)")
    for r in range(ROWS):
        line = ""
        for q in range(COLS):
            country = hex_country.get((q, r))
            line += COUNTRY_CODES.get(country, ".") if country else "."
            line += " " if r & 1 else ""
        print(line)

    data = {
        "version": 1,
        "provisional": True,
        "note": "Atlas hexagonal provisoire du MVP (H-002). Tracé non définitif.",
        "grid": {"cols": COLS, "rows": ROWS},
        "provinces": sorted(provinces, key=lambda p: p["id"]),
        "adjacency": {k: v for k, v in sorted(adjacency.items())},
    }
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"\n{len(provinces)} provinces écrites dans {OUT}")


if __name__ == "__main__":
    main()
