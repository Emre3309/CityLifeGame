extends RefCounted

func run() -> Array[String]:
	if not ResourceLoader.exists("res://features/focus/focus_service.gd"):
		return ["test_university_focus_completes_once: focus service is missing"]
	var failures: Array[String] = []
	failures.append_array(test_university_focus_completes_once())
	failures.append_array(test_focus_guards())
	failures.append_array(test_content_is_safe_and_connected())
	failures.append_array(test_dark_progression_and_lifecycle())
	failures.append_array(test_panel_matches_domain_and_28_day_scene_flow())
	return failures

# Catches early/late completion, repeat rewards and skipping a due day in a batch.
func test_university_focus_completes_once() -> Array[String]:
	var world = load("res://core/world_factory.gd").create("light", 42)
	var commands = load("res://core/command_service.gd")
	var simulation = load("res://core/simulation.gd").new()
	var started: Dictionary = commands.execute(world, {"type":"start_focus", "focus_id":"university_prep"})
	if not started.ok:
		return ["test_university_focus_completes_once: university preparation must start"]
	var failures: Array[String] = []
	if world.active_focus.start_day != 0 or world.active_focus.end_day != 28 or world.active_focus.actor_id != world.player_id:
		failures.append("focus must record owner and exact 28-day interval")
	if world.characters[world.player_id].money != 60:
		failures.append("focus start must charge its displayed cost once")
	simulation.advance_days(world, 27)
	if world.characters[world.player_id].education != "high_school_graduate" or not world.completed_focuses.is_empty():
		failures.append("university preparation must not finish after only 27 days")
	simulation.advance_days(world, 1)
	if world.characters[world.player_id].education != "university_enrolled" or world.characters[world.player_id].knowledge.get("study", 0) != 10 or world.completed_focuses != ["university_prep"] or not world.active_focus.is_empty():
		failures.append("day 28 must enroll the player and award knowledge exactly once")
	var after: Dictionary = world.to_dict()
	simulation.advance_days(world, 1)
	after.day_index = 29
	if world.to_dict() != after:
		failures.append("day 29 must not repeat any reward or completion history")
	var batch = load("res://core/world_factory.gd").create("light", 42)
	commands.execute(batch, {"type":"start_focus", "focus_id":"university_prep"})
	simulation.advance_days(batch, 29)
	if world.to_dict() != batch.to_dict():
		failures.append("batch must retain the same single completion as daily stepping")
	return failures

# Every denial must agree with availability and leave a deep world snapshot unchanged.
func test_focus_guards() -> Array[String]:
	var factory = load("res://core/world_factory.gd")
	var service = load("res://features/focus/focus_service.gd")
	var commands = load("res://core/command_service.gd")
	var failures: Array[String] = []
	for kind in ["route", "prerequisite", "active", "money", "completed", "dead", "imprisoned", "future", "unknown", "lifespan"]:
		var world = factory.create("dark" if kind == "route" else "light", 5)
		var focus_id := "public_service_prep" if kind == "prerequisite" else "university_prep"
		match kind:
			"active": commands.execute(world, {"type":"start_focus", "focus_id":"university_prep"})
			"money": world.characters[world.player_id].money = 39
			"completed": world.completed_focuses.append("university_prep")
			"dead": world.characters[world.player_id].death_day = 0
			"imprisoned": world.characters[world.player_id].imprisoned_until = 1
			"lifespan": world.characters[world.player_id].lifespan_end_day = 0
			"future": focus_id = "university_graduation"
			"unknown": focus_id = "missing"
		var before: Dictionary = world.to_dict()
		var eligibility: Dictionary = service.availability(world, focus_id)
		var result: Dictionary = commands.execute(world, {"type":"start_focus", "focus_id":focus_id})
		if result.ok or eligibility.ok or result.reason.is_empty() or result.reason != eligibility.reason or world.to_dict() != before:
			failures.append("test_focus_guards: denied %s must explain without mutation" % kind)
	var fresh = factory.create("light", 5)
	var before: Dictionary = fresh.to_dict()
	if commands.execute(null, {"type":"start_focus", "focus_id":"university_prep"}).ok or commands.execute(fresh, {"type":"start_focus", "focus_id":7}).ok or fresh.to_dict() != before:
		failures.append("focus requires a started world and a string identifier")
	# Release day is playable; yesterday's imprisonment cannot lock the player forever.
	fresh.characters[fresh.player_id].imprisoned_until = 0
	if not service.start(fresh, "university_prep").ok:
		failures.append("a released player must be eligible")
	return failures

# Catches unsafe effects, duplicate ids and broken links before any world can mutate.
func test_content_is_safe_and_connected() -> Array[String]:
	var service = load("res://features/focus/focus_service.gd")
	var definitions: Array = service.definitions()
	if definitions.size() < 9:
		return ["both route trees and explicitly locked future nodes must ship"]
	var failures: Array[String] = []
	for kind in ["effect", "duplicate", "prerequisite", "cycle", "duration"]:
		var bad: Array = definitions.duplicate(true)
		match kind:
			"effect": bad[0].effects.append({"type":"execute_script", "code":"oops"})
			"duplicate": bad.append(bad[0].duplicate(true))
			"prerequisite": bad[0].prerequisites.append("missing")
			"cycle": bad[0].prerequisites.append(bad[0].id)
			"duration": bad[0].duration_days = -1
		if service.validate(bad).is_empty():
			failures.append("focus catalog must reject invalid " + kind)
	return failures

# Catches omitted unlock effects, accidental office promotion and rewards transferred to a new/dead player.
func test_dark_progression_and_lifecycle() -> Array[String]:
	var factory = load("res://core/world_factory.gd")
	var service = load("res://features/focus/focus_service.gd")
	var simulation = load("res://core/simulation.gd").new()
	var world = factory.create("dark", 2)
	for focus_id in ["street_connections", "petty_crime_opportunity", "gang_connections"]:
		if not service.start(world, focus_id).ok:
			return ["dark focus chain must allow " + focus_id]
		simulation.advance_days(world, 28)
	if world.characters[world.player_id].role != "citizen" or not world.characters[world.player_id].get("unlocked_actions", []).has("gang_contact") or world.characters[world.player_id].knowledge.get("underworld", 0) != 10:
		return ["dark chain must unlock opportunities and knowledge without granting an office"]
	var failures: Array[String] = []
	for kind in ["dead", "imprisoned", "changed_player"]:
		world = factory.create("light", 2)
		service.start(world, "university_prep")
		if kind == "dead": world.characters[world.player_id].death_day = 1
		if kind == "imprisoned": world.characters[world.player_id].imprisoned_until = 40
		if kind == "changed_player": world.player_id = "aylin"
		simulation.advance_days(world, 28)
		if not world.completed_focuses.is_empty() or not world.active_focus.is_empty() or world.characters.player_1.education != "high_school_graduate":
			failures.append("unavailable or replaced player must not receive a pending focus reward: " + kind)
	return failures

# Exercises the actual UI→command→simulation→readout route, including the 27/28 day boundary.
func test_panel_matches_domain_and_28_day_scene_flow() -> Array[String]:
	if not ResourceLoader.exists("res://features/focus/focus_panel.gd"):
		return ["focus panel is missing"]
	var scene = load("res://main.tscn").instantiate()
	var tree := Engine.get_main_loop() as SceneTree
	tree.root.add_child(scene)
	scene.set_process(false)
	var failures: Array[String] = []
	if scene.hud.focus_button.disabled == false:
		failures.append("focus tree cannot open before choosing a life")
	scene.hud.start_panel.route_chosen.emit("light")
	scene.hud.focus_button.pressed.emit()
	var panel = scene.hud.focus_panel
	if not panel.visible or panel.start_buttons.university_prep.disabled or not panel.start_buttons.public_service_prep.disabled or not panel.start_buttons.university_graduation.disabled:
		failures.append("tree must show available preparation and locked prerequisite/future nodes")
	var before: Dictionary = scene.world.to_dict()
	panel.refresh(scene.world)
	if scene.world.to_dict() != before:
		failures.append("drawing the tree must never mutate the world")
	panel.start_buttons.university_prep.pressed.emit()
	if scene.world.active_focus.is_empty() or not panel.start_buttons.university_prep.disabled:
		failures.append("focus button must dispatch a validated command and immediately refresh")
	scene.simulation.advance_days(scene.world, 27)
	scene._refresh_hud()
	if not panel.summary.text.contains("1 gün"):
		failures.append("active focus must display one remaining day at day 27")
	scene.simulation.advance_days(scene.world, 1)
	scene._refresh_hud()
	if not panel.summary.text.contains("Üniversiteye kayıtlı") or not panel.start_buttons.university_prep.disabled or panel.start_buttons.public_service_prep.disabled:
		failures.append("day 28 must show enrolled education, completed preparation and next branch eligibility")
	var service = load("res://features/focus/focus_service.gd")
	for focus_id in panel.start_buttons:
		var eligibility: Dictionary = service.availability(scene.world, focus_id)
		if panel.start_buttons[focus_id].disabled == eligibility.ok or panel.lock_labels[focus_id].text != eligibility.reason:
			failures.append("panel eligibility must match domain for " + focus_id)
	scene.free()
	return failures
