extends SceneTree
## Runs every tests/test_*.gd file and prints three numbers per run.
## Run from the project folder (import first):
##   godot --headless --path . --import
##   godot --headless --path . -s res://tests/run_tests.gd
## Render tests need a real renderer; under --headless they are skipped and
## counted as skipped. Run without --headless (a desktop, or Xvfb) to run them.
## Exit code: 0 when nothing failed and the counts match, 1 otherwise.

## Stated before any run (godotsmith L1): a script that fails to parse is
## dropped silently, so the counts are checked exactly.
const EXPECTED_SCRIPTS := 3
const EXPECTED_TESTS := 30

const TEST_DIR := "res://tests"


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var files: Array[String] = []
	for f in DirAccess.get_files_at(TEST_DIR):
		if f.begins_with("test_") and f.ends_with(".gd") and f != "test_case.gd":
			files.append(f)
	files.sort()
	var scripts := 0
	var tests := 0
	var passed := 0
	var failed := 0
	var skipped := 0
	for f in files:
		var script := load(TEST_DIR + "/" + f) as GDScript
		if script == null or not script.can_instantiate():
			print("SCRIPT FAILED TO LOAD: ", f)
			failed += 1
			continue
		scripts += 1
		var names: Array[String] = []
		for m in script.get_script_method_list():
			var n: String = m.name
			if n.begins_with("test_") and not names.has(n):
				names.append(n)
		names.sort()
		for n in names:
			var t: RefCounted = script.new()
			t.tree = self
			await t.call(n)
			tests += 1
			if not t.failures.is_empty():
				failed += 1
				print("FAIL  %s::%s" % [f, n])
				for msg in t.failures:
					print("      ", msg)
			elif t.skipped:
				skipped += 1
				print("SKIP  %s::%s (needs a renderer)" % [f, n])
			else:
				passed += 1
				print("PASS  %s::%s" % [f, n])
	var renderer := DisplayServer.get_name() + " / " + RenderingServer.get_video_adapter_name()
	print("")
	print("renderer: ", renderer)
	print("scripts=%d (expected %d) tests=%d (expected %d) passed=%d failed=%d skipped=%d" % [
		scripts, EXPECTED_SCRIPTS, tests, EXPECTED_TESTS, passed, failed, skipped])
	var ok := failed == 0 and scripts == EXPECTED_SCRIPTS and tests == EXPECTED_TESTS
	if scripts != EXPECTED_SCRIPTS or tests != EXPECTED_TESTS:
		print("COUNT MISMATCH: a test file was dropped or the expected totals are stale")
	quit(0 if ok else 1)
