extends SceneTree
## Lanceur de tests sans interface :
##   godot --headless --path . --script tests/run_tests.gd
## Exécute chaque méthode `test_*` des scripts de tests/unit/. Code de sortie 1 en cas d'échec.

var failures: int = 0
var passed: int = 0


func _init() -> void:
	var files := _gd_files("res://tests/unit")
	files.append_array(_gd_files("res://tests/integration"))
	files.sort()
	for path in files:
		var file: String = path.substr(path.rfind("/") + 1)
		var script: GDScript = load(path)
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


func _gd_files(dir_path: String) -> Array:
	var out: Array = []
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return out
	for file: String in dir.get_files():
		if file.ends_with(".gd"):
			out.append(dir_path + "/" + file)
	return out


func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		printerr("    ✗ " + message)
