extends RefCounted


func run() -> Array[String]:
	return test_main_scene_loads()


func test_main_scene_loads() -> Array[String]:
	var failures: Array[String] = []
	var main_path: String = ProjectSettings.get_setting("application/run/main_scene", "")
	if main_path.is_empty() or not ResourceLoader.exists(main_path):
		return ["test_main_scene_loads: configured main scene is missing."]
	var packed_scene = load(main_path)
	if not packed_scene is PackedScene:
		return ["test_main_scene_loads: main resource must be a PackedScene."]
	var scene = packed_scene.instantiate()
	if not scene is Node3D:
		failures.append("test_main_scene_loads: main scene root must be Node3D.")
	else:
		var tree := Engine.get_main_loop() as SceneTree
		tree.root.add_child(scene)
		if not scene.is_inside_tree():
			failures.append("test_main_scene_loads: main scene must enter the tree.")
	scene.free()
	return failures
