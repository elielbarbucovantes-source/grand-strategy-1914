class_name GameCalendar
extends RefCounted
## Calendrier stratégique mensuel (VALIDÉ : un tour = un mois, D-006).
## Mois de départ : janvier 1914 pour la campagne historique (T-057, tranche R-13) ; libre dans le bac à sable.

const MONTHS_FR: PackedStringArray = ["janvier", "février", "mars", "avril", "mai", "juin", "juillet",
	"août", "septembre", "octobre", "novembre", "décembre"]


static func label(year: int, month: int) -> String:
	return "%s %d" % [MONTHS_FR[month - 1], year]


static func next(year: int, month: int) -> Vector2i:
	return Vector2i(year + 1, 1) if month == 12 else Vector2i(year, month + 1)


static func is_valid_month(month: int) -> bool:
	return month >= 1 and month <= 12
