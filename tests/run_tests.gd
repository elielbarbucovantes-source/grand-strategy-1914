extends SceneTree
## Lanceur de tests sans interface :
##   godot --headless --path . --script tests/run_tests.gd
## Exécute chaque méthode `test_*` des scripts de tests/unit/. Code de sortie 1 en cas d'échec.

var failures: int = 0
var passed: int = 0


func _init() -> void:
	var dir := DirAccess.open("res://tests/unit")
	var files := dir.get_files()
	files.sort()
	for file in files:
		if not file.ends_with(".gd"):
			continue
		var script: GDScript = load("res://tests/unit/" + file)
		if script == null or not script.can_instantiate():
			failures += 1
			printerr("  FAIL  %s : script de test illisible (erreur d'analyse)" % file)
			continue
		var suite: Object = script.new()
		suite.set("runner", self)
		for method: Dictionary in script.get_script_method_list():
			var name: String = method["name"]
			if not name.begins_with("test_"):
				continue
			var before := failures
			suite.call(name)
			if failures == before:
				passed += 1
				print("  PASS  %s::%s" % [file, name])
			else:
				print("  FAIL  %s::%s" % [file, name])
	print("RÉSULTAT : %d test(s) réussi(s), %d échec(s)" % [passed, failures])
	quit(1 if failures > 0 else 0)


func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		printerr("    ✗ " + message)
