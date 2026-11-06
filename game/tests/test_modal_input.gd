extends RefCounted

var failures: Array[String] = []
var tree: SceneTree
var scene

func click(point: Vector2, down: bool) -> void:
	var event := InputEventMouseButton.new()
	event.position = point
	event.global_position = point
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = down
	tree.root.push_input(event, true)

func frames() -> void:
	await tree.process_frame
	await tree.process_frame

func run() -> Array[String]:
	tree = Engine.get_main_loop() as SceneTree
	tree.root.size = Vector2i(1280, 720)
	scene = load("res://main.tscn").instantiate()
	tree.root.add_child(scene)
	scene.set_process(false)
	scene._start_world("light")
	scene.simulation.advance_days(scene.world, 3)
	scene._refresh_hud()
	await frames()
	for panel in [scene.hud.focus_panel, scene.hud.event_panel, scene.hud.relationships_panel, scene.hud.authority_panel, scene.hud.save_panel]:
		scene.simulation.set_speed(12)
		scene.simulation.set_paused(false)
		scene.hud._show_personal_panel(panel)
		var day: int = scene.world.day_index
		scene._process(1.0)
		if not scene.simulation.paused or scene.world.day_index != day: failures.append("modal opening must pause at 12 days/sec: " + panel.name)
		panel.hide()
		if not scene.simulation.paused: failures.append("closing modal must remain paused: " + panel.name)
	scene.simulation.set_paused(false)
	scene.hud._show_personal_panel(scene.hud.event_panel)
	await frames()
	var button: Button = scene.hud.event_panel.choice_buttons["player_1:family_support:part_time_work"]
	var point := button.get_global_rect().get_center()
	var day: int = scene.world.day_index
	click(point, true)
	scene._process(1.0)
	await frames()
	click(point, false)
	await frames()
	if scene.world.day_index != day or scene.world.characters.player_1.money != 125: failures.append("routed event click across elapsed time must execute once with frozen date")
	scene.hud.event_panel.hide()
	scene.world = null
	scene._start_scenario("police_demo")
	scene.simulation.set_speed(12)
	scene.simulation.set_paused(false)
	scene.hud._show_personal_panel(scene.hud.authority_panel)
	await frames()
	button = scene.hud.authority_panel.action_buttons["open_investigation"]
	point = button.get_global_rect().get_center()
	day = scene.world.day_index
	var budget: int = scene.world.organizations.police.budget
	click(point, true)
	scene._process(1.0)
	await frames()
	click(point, false)
	await frames()
	if scene.world.day_index != day or scene.world.organizations.police.budget != budget - 50 or scene.world.organizations.police.investigations.size() != 1: failures.append("routed authority click across elapsed time must execute once with frozen date")
	scene.free()
	return failures

