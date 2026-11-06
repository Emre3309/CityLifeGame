extends RefCounted

func run() -> Array[String]:
	var failures: Array[String] = []
	failures.append_array(test_family_choice_updates_money_and_relationship())
	failures.append_array(test_event_cannot_resolve_twice())
	failures.append_array(test_dead_participant_and_invalid_choice_rejected())
	failures.append_array(test_seeded_outcome_repeats())
	failures.append_array(test_trigger_and_romance_prerequisites())
	failures.append_array(test_content_validation())
	failures.append_array(test_scene_choices_and_relationship_readout())
	return failures

func _world(route: String = "light", seed_value: int = 42):
	return load("res://core/world_factory.gd").create(route, seed_value)

func _offer(world, template_id: String) -> String:
	var participants := [world.player_id, "nermin"]
	if template_id == "port_offer": participants = [world.player_id, "riza", "nermin"]
	if template_id in ["romance_meeting", "romance_visit"]: participants = [world.player_id, "aylin"]
	var id: String = world.player_id + ":" + template_id
	world.pending_events.append({"instance_id":id, "template_id":template_id, "actor_id":world.player_id, "participant_ids":participants, "created_day":world.day_index})
	return id

func _resolve(world, id: String, choice: String) -> Dictionary:
	return load("res://core/command_service.gd").execute(world, {"type":"resolve_event", "event_id":id, "choice_id":choice})

# Catches missing transfers, one-sided relationships, negative money and inaccurate deltas.
func test_family_choice_updates_money_and_relationship() -> Array[String]:
	var failures: Array[String] = []
	for row in [["ask_help",40,-40,5],["part_time_work",25,0,8],["help_family",-30,30,12]]:
		var world = _world()
		world.day_index = 3
		var id := _offer(world, "family_support")
		var result := _resolve(world, id, row[0])
		if not result.ok:
			failures.append("test_family_choice_updates_money_and_relationship: valid family choice rejected: " + row[0])
			continue
		if world.characters.player_1.money != 100 + row[1] or world.characters.nermin.money != 300 + row[2] or world.characters.player_1.relationships.nermin != 70 + row[3] or world.characters.nermin.relationships.player_1 != 70 + row[3]:
			failures.append("family choice must apply its real money and reciprocal relationship changes: " + row[0])
		if result.get("deltas", {}).get("money", 0) != row[1] or not result.reason.contains("Para") or not result.reason.contains("Nermin"):
			failures.append("result must describe actual money/relationship deltas and cause")
	# Report clamped real changes rather than claiming an impossible +12.
	var capped = _world()
	capped.day_index = 3
	capped.characters.player_1.relationships.nermin = 98
	capped.characters.nermin.relationships.player_1 = 98
	var result := _resolve(capped, _offer(capped, "family_support"), "help_family")
	if not result.ok or result.deltas.relationships.nermin != 2 or not result.reason.contains("+2"):
		failures.append("relationship feedback must use actual clamped delta")
	return failures

# Catches repeated reward from duplicate clicks and re-triggering a completed template.
func test_event_cannot_resolve_twice() -> Array[String]:
	var world = _world()
	world.day_index = 3
	var id := _offer(world, "family_support")
	var first := _resolve(world, id, "part_time_work")
	var before: Dictionary = world.to_dict()
	var second := _resolve(world, id, "part_time_work")
	if not first.ok or second.ok or world.to_dict() != before or world.resolved_event_ids.count(id) != 1 or not world.pending_events.is_empty():
		return ["test_event_cannot_resolve_twice: only first click may reward and remove pending instance"]
	if ResourceLoader.exists("res://features/events/event_service.gd"):
		load("res://features/events/event_service.gd").trigger(world)
		for pending in world.pending_events:
			if pending.instance_id == id: return ["completed template must not respawn for same actor"]
	return []

# Every denial, including preflight failures after a valid instance was queued, is atomic.
func test_dead_participant_and_invalid_choice_rejected() -> Array[String]:
	var failures: Array[String] = []
	for kind in ["choice", "missing_instance", "dead", "expired_lifespan", "missing_person", "changed_player", "money", "family_money", "imprisoned", "duplicate", "forged", "future_day", "early", "route", "romance_prerequisite", "romance_age"]:
		var world = _world("dark" if kind == "route" else "light")
		world.day_index = 20
		var template_id := "romance_visit" if kind == "romance_prerequisite" else ("romance_meeting" if kind == "romance_age" else "family_support")
		var id := _offer(world, template_id)
		var choice := "meet" if kind == "romance_age" else ("visit" if kind == "romance_prerequisite" else "help_family")
		match kind:
			"choice": choice = "missing"
			"missing_instance": id = "missing"
			"dead": world.characters.nermin.death_day = 19
			"expired_lifespan": world.characters.nermin.lifespan_end_day = 20
			"missing_person": world.characters.erase("nermin")
			"changed_player": world.player_id = "aylin"
			"money": world.characters.player_1.money = 29
			"family_money":
				world.characters.nermin.money = 39
				choice = "ask_help"
			"imprisoned": world.characters.player_1.imprisoned_until = 21
			"duplicate": world.pending_events.append(world.pending_events[0].duplicate(true))
			"forged": world.pending_events[0].participant_ids = [world.player_id, "riza"]
			"future_day": world.pending_events[0].created_day = 21
			"early": world.day_index = 1
			"route":
				world.pending_events.clear()
				id = _offer(world, "port_offer")
				world.characters.player_1.route = "light"
				choice = "accept"
			"romance_age": world.characters.aylin.birth_date.year = 1920
		var before: Dictionary = world.to_dict()
		var denied := _resolve(world, id, choice)
		if denied.ok or denied.reason.is_empty() or world.to_dict() != before:
			failures.append("denied event must explain and preserve entire snapshot including RNG: " + kind)
	var world = _world()
	var before: Dictionary = world.to_dict()
	var commands = load("res://core/command_service.gd")
	if commands.execute(null, {"type":"resolve_event", "event_id":"a", "choice_id":"b"}).ok or commands.execute(world, {"type":"resolve_event", "event_id":7,"choice_id":[]}).ok or world.to_dict() != before:
		failures.append("event command must validate world and identifier types")
	return failures

# Catches global RNG use, ignoring saved RNG state, and risk/benefit feedback discrepancies.
func test_seeded_outcome_repeats() -> Array[String]:
	var failures: Array[String] = []
	var outcomes: Dictionary = {}
	for seed_value in range(1, 25):
		var a = _world("dark", seed_value)
		var b = _world("dark", seed_value)
		a.day_index = 7
		b.day_index = 7
		var old_state: int = a.rng_state
		var result_a := _resolve(a, _offer(a, "port_offer"), "accept")
		var result_b := _resolve(b, _offer(b, "port_offer"), "accept")
		if not result_a.ok or result_a != result_b or a.to_dict() != b.to_dict():
			failures.append("test_seeded_outcome_repeats: equal seeds and commands must have equal results")
			break
		var risk: int = a.characters.player_1.investigation_risk
		outcomes[risk] = true
		if a.rng_state == old_state or a.characters.player_1.money != 200 or a.characters.player_1.relationships.nermin != 58 or result_a.deltas.investigation_risk != risk or not result_a.reason.contains("Soruşturma riski"):
			failures.append("port offer must consume world RNG and report its real benefit, risk and relationship cost")
	if outcomes.size() != 2:
		failures.append("seeded port outcomes must include both detection and no detection")
	if not ResourceLoader.exists("res://features/events/event_service.gd"): return failures
	var a = _world("dark", 81)
	var rng := RandomNumberGenerator.new()
	rng.seed = a.rng_seed
	rng.state = a.rng_state
	rng.randf()
	a.rng_state = rng.state
	var restored = load("res://core/world_state.gd").from_dict(a.to_dict())
	a.day_index = 7
	restored.day_index = 7
	var expected_detected := rng.randf() < 0.45
	var result_a := _resolve(a, _offer(a, "port_offer"), "accept")
	var result_b := _resolve(restored, _offer(restored, "port_offer"), "accept")
	if not result_a.ok or result_a != result_b or a.rng_state != rng.state or a.characters.player_1.investigation_risk != (25 if expected_detected else 0):
		failures.append("restored RNG state must be resumed, never restarted from seed")
	return failures

# Catches skipped daily trigger integration, duplicate instances, and unearned romantic follow-ups.
func test_trigger_and_romance_prerequisites() -> Array[String]:
	if not ResourceLoader.exists("res://features/events/event_service.gd"):
		return ["test_trigger_and_romance_prerequisites: event service missing"]
	var service = load("res://features/events/event_service.gd")
	var simulation = load("res://core/simulation.gd").new()
	var world = _world()
	simulation.advance_days(world, 10)
	var count: int = world.pending_events.size()
	service.trigger(world)
	if count != 2 or world.pending_events.size() != count:
		return ["daily trigger must queue family and peer meeting exactly once"]
	var visit_id: String = world.player_id + ":romance_visit"
	for pending in world.pending_events:
		if pending.instance_id == visit_id: return ["visit requires accepted first meeting"]
	var meeting_id: String = world.player_id + ":romance_meeting"
	if not _resolve(world, meeting_id, "meet").ok: return ["age-appropriate meeting must be playable"]
	simulation.advance_days(world, 4)
	if not _resolve(world, visit_id, "visit").ok or world.characters.player_1.relationships.aylin != 35:
		return ["meeting then public conversation must advance mutual relationship"]
	# No personal events for a dead, unavailable or replacement actor.
	var dead = _world()
	dead.characters.player_1.death_day = 0
	simulation.advance_days(dead, 20)
	if not dead.pending_events.is_empty(): return ["dead actor must not receive events"]
	return []

func test_content_validation() -> Array[String]:
	if not ResourceLoader.exists("res://features/events/event_service.gd"): return ["event catalog validation missing"]
	var service = load("res://features/events/event_service.gd")
	var rows: Array = service.definitions()
	var failures: Array[String] = []
	if rows.size() != 4: return ["family, port, meeting and visit templates must ship"]
	for kind in ["duplicate", "choice", "effect", "participant", "chance", "prerequisite"]:
		var bad := rows.duplicate(true)
		match kind:
			"duplicate": bad.append(bad[0].duplicate(true))
			"choice": bad[0].choices.append(bad[0].choices[0].duplicate(true))
			"effect": bad[0].choices[0].effects.append({"type":"execute_script"})
			"participant": bad[0].participants.append("missing")
			"chance": bad[1].choices[0].risk_chance = 2
			"prerequisite": bad[0].requires = {"template_id":"missing", "choice_id":"meet"}
		if service.validate(bad, ["nermin","aylin","riza","kemal","selim"]).is_empty():
			failures.append("event catalog must reject unsafe " + kind)
	return failures

# Exercises actual scene signals, command mutation, repeated click, and read-only panel refresh.
func test_scene_choices_and_relationship_readout() -> Array[String]:
	if not ResourceLoader.exists("res://features/events/event_panel.gd") or not ResourceLoader.exists("res://features/life/relationships_panel.gd"):
		return ["event/relationships panels missing"]
	var scene = load("res://main.tscn").instantiate()
	(Engine.get_main_loop() as SceneTree).root.add_child(scene)
	scene.set_process(false)
	scene.hud.start_panel.route_chosen.emit("light")
	scene.simulation.advance_days(scene.world, 3)
	scene._refresh_hud()
	scene.hud.events_button.pressed.emit()
	var panel = scene.hud.event_panel
	var failures: Array[String] = []
	var id: String = scene.world.player_id + ":family_support"
	var key := id + ":part_time_work"
	if not panel.visible or not panel.choice_buttons.has(key):
		scene.free()
		return ["event button must open queued choices"]
	var old_button: Button = panel.choice_buttons[key]
	old_button.pressed.emit()
	var after: Dictionary = scene.world.to_dict()
	old_button.pressed.emit()
	if scene.world.to_dict() != after or scene.world.characters.player_1.money != 125 or not panel.feedback.text.contains("+25"):
		failures.append("UI must dispatch once and preserve readable result on repeated click")
	scene.hud.relationships_button.pressed.emit()
	var relationships = scene.hud.relationships_panel
	if not relationships.visible or not relationships.summary.text.contains("125") or not relationships.entries.text.contains("Nermin") or not relationships.entries.text.contains("78") or relationships.entries.text.contains("kapsam dışı"):
		failures.append("relationships panel must show actual money, names, relationship values and prototype scope")
	panel.refresh(scene.world)
	relationships.refresh(scene.world)
	if scene.world.to_dict() != after: failures.append("panel refresh must be read-only")
	scene.free()
	return failures
