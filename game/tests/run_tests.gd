extends SceneTree


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var suite := "all"
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--suite="):
			suite = argument.trim_prefix("--suite=")
	var files: Array[String] = []
	if suite == "all":
		for file_name in DirAccess.get_files_at("res://tests"):
			if file_name.begins_with("test_") and file_name.ends_with(".gd"):
				files.append(file_name)
		files.sort()
	elif suite.is_valid_identifier():
		files.append("test_%s.gd" % suite)
	var failures: Array[String] = []
	if files.is_empty():
		failures.append("No test files found for suite '%s'." % suite)
	for file_name in files:
		var path := "res://tests/%s" % file_name
		if not ResourceLoader.exists(path):
			failures.append("Test suite does not exist: %s" % path)
			continue
		var test_script = load(path)
		if test_script == null or not test_script.can_instantiate():
			failures.append("Cannot load test suite: %s" % path)
			continue
		var test = test_script.new()
		if not test.has_method("run"):
			failures.append("Test suite has no run() method: %s" % path)
			continue
		var result = test.run()
		if not result is Array:
			failures.append("Test suite run() must return an Array[String]: %s" % path)
			continue
		for failure in result:
			failures.append("%s: %s" % [file_name, str(failure)])
	for failure in failures:
		print("  %s" % failure)
	if failures.is_empty():
		print("PASS %s" % suite)
		quit(0)
	else:
		print("FAIL %s" % suite)
		quit(1)
