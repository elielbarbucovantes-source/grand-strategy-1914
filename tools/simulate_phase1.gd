extends SceneTree
## B3 : simulation longue déterministe — deux IA en guerre (Lorraine), 8 tours, graine fixe.
## Journal des opérations (objectifs, approches, postures, batailles, résultats) imprimé sur stdout.
## Usage : godot --headless --path . --script tools/simulate_phase1.gd [-- <tours>]
## Aucun fichier du dépôt n'est modifié pendant l'exécution.

const TURNS := 8
const SEED := 19140101
const A := "german_empire"
const B := "france"


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var turns := TURNS
	if args.size() > 0:
		turns = maxi(2, int(args[0]))
	var s := GameSession.create()
	s.new_game("united_kingdom", 1, 1914)
	s.state.seed_value = SEED
	s.state.wars.append({"id": "w_sim", "a": A, "b": B, "since_turn": 0})
	print("SIM seed=%d tours=%d formations_initiales=%d" % [SEED, turns, s.state.formations.size()])
	for t in turns:
		var report := s.end_turn()
		if report.has("error"):
			print("T%02d ERREUR %s" % [t + 1, report["error"]])
			break
		_log_turn(s, t + 1, report)
		_resolve_auto_battles(s)
	print("SIM FIN tour=%d formations=%d batailles=%d evenements=%d" % [
		s.state.turn, s.state.formations.size(), s.state.battles.size(), s.state.events.size()])
	quit()


func _resolve_auto_battles(s: GameSession) -> void:
	for b: Dictionary in BattleManager.queue(s.state):
		if (b["humans"] as Array).is_empty():
			BattleManager.run_to_end(b, s.rules["combat"], true)
			BattleManager.finish(s.state, s.world, s.rules["combat"], b)


func _log_turn(s: GameSession, turn: int, report: Dictionary) -> void:
	var hist: Dictionary = s.state.orders_history[s.state.orders_history.size() - 1]
	var moves: Array = []
	for nid: String in [A, B]:
		for o: Dictionary in hist.get("orders", []):
			if str(o.get("nation", "")) != nid or str(o.get("type", "")) != "move":
				continue
			moves.append("%s:%s→%s/%s" % [nid.substr(0, 3), str(o.get("formation", "")).substr(0, 14),
				str(o.get("target", "")), str(o.get("approach", "assault"))])
	var postures: Array = []
	for nid: String in [A, B]:
		for o: Dictionary in hist.get("orders", []):
			if str(o.get("nation", "")) != nid or str(o.get("type", "")) != "defensive_posture":
				continue
			postures.append("%s:%s=%s" % [nid.substr(0, 3), str(o.get("army", "")).substr(0, 12), str(o.get("posture", ""))])
	var new_battles := 0
	for b: Dictionary in s.state.battles:
		if int(b.get("turn", -1)) == s.state.turn - 1:
			new_battles += 1
	print("T%02d date=%s ordres=%d attaques=[%s] postures=[%s] batailles=%d" % [
		turn, s.state.date_label(), (hist.get("orders", []) as Array).size(),
		", ".join(PackedStringArray(moves)), ", ".join(PackedStringArray(postures)), new_battles])
