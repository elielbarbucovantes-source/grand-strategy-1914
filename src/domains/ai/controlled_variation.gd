class_name ControlledVariation
extends RefCounted
## RESTORATION 01 — variabilité contrôlée et reproductible.
## Le bruit dépend de la graine, du tour, de l'État et d'un sel : deux campagnes avec la même
## graine et les mêmes actions produisent exactement les mêmes résultats ; deux graines
## différentes peuvent diverger sans transformer la décision en loterie (amplitude ±1).

static func variation(seed_value: int, turn: int, key: String, salt: String = "") -> float:
	var raw := "%d|%d|%s|%s" % [seed_value, turn, key, salt]
	var h := raw.sha256_text().substr(0, 8).hex_to_int()
	return float(h % 2001) / 1000.0 - 1.0


static func jitter(state: GameState, key: String, salt: String = "") -> float:
	return variation(state.seed_value, state.turn, key, salt)


static func from_view(view: Dictionary, key: String, salt: String = "") -> float:
	return variation(int(view.get("seed", 1914)), int(view.get("turn", 0)), key, salt)


static func chance_view(view: Dictionary, key: String, salt: String = "") -> float:
	return (from_view(view, key, salt) + 1.0) * 0.5
