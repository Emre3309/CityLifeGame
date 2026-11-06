extends RefCounted

const PATH := "user://saves/test_slot.json"
var failures: Array[String] = []

func run() -> Array[String]:
	if not ResourceLoader.exists("res://persistence/save_service.gd"):
		return ["test_roundtrip_preserves_pending_focus_event_rng: SaveService missing", "test_corrupt_save_keeps_live_world: SaveService missing", "test_save_write_failure_preserves_previous_file: SaveService missing"]
	test_roundtrip_preserves_pending_focus_event_rng()
	test_rejects_invalid_saves()
	test_save_write_failure_preserves_previous_file()
	test_nested_state_and_rng_boundaries()
	test_personal_actors_must_match_player()
	test_supported_day_limits_do_not_replace_live_world()
	test_corrupt_save_keeps_live_world()
	return failures

func _world():
	var world = load("res://core/world_factory.gd").create("dark", -9223372036854775807)
	load("res://features/focus/focus_service.gd").start(world, "street_connections")
	load("res://core/simulation.gd").new().advance_days(world, 7)
	return world

func _write(data: Variant) -> void:
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.close()

# Dropping any active state or rounding/restarting RNG changes the restored snapshot or continuation.
func test_roundtrip_preserves_pending_focus_event_rng() -> void:
	var service = load("res://persistence/save_service.gd").new()
	var world = _world()
	var saved: Dictionary = service.save_world(world, PATH)
	var restored: Dictionary = service.load_world(PATH)
	if not saved.ok or not restored.ok:
		failures.append("roundtrip rejected: " + str(saved) + str(restored)); return
	if restored.world.to_dict() != world.to_dict():
		failures.append("roundtrip must preserve full pending focus/event/history/RNG snapshot")
	var encoded: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if not encoded.rng_seed is String or not encoded.rng_state is String: failures.append("RNG signed64 values must be decimal strings")
	for next in [world, restored.world]:
		var result: Dictionary = load("res://features/events/event_service.gd").resolve(next, "player_1:port_offer", "accept")
		if not result.ok: failures.append("restored pending RNG event must remain playable")
		load("res://core/simulation.gd").new().advance_days(next, 14)
	if restored.world.to_dict() != world.to_dict(): failures.append("14 day continuation must match uninterrupted world exactly")
	# All institution variants and valid vacant offices must remain loadable.
	for scenario in ["governor_demo", "police_demo", "gang_demo"]:
		var demo = load("res://core/world_factory.gd").create_scenario(scenario, 9)
		load("res://core/simulation.gd").new().advance_days(demo, 21)
		if not service.save_world(demo, PATH).ok or not service.load_world(PATH).ok: failures.append("institution roundtrip failed: " + scenario)

# Signed64 endpoints must not saturate or wrap, and nested institution data must survive.
func test_nested_state_and_rng_boundaries() -> void:
	var service = load("res://persistence/save_service.gd").new()
	var world = _world()
	world.organizations.police.investigations.riza = {"target_id":"riza","progress":50,"evidence":65,"opened_day":3}
	world.organizations.harbor_network.assignments.cem = "cinar"
	world.organizations.governorship.leader_id = ""
	world.districts.cinar.official_owner_id = ""
	world.characters.kemal.death_day = 3
	for value in ["-9223372036854775808","9223372036854775807","0"]:
		world.rng_seed = int(value)
		world.rng_state = int(value)
		var saved: Dictionary = service.save_world(world,PATH)
		var restored: Dictionary = service.load_world(PATH)
		if not saved.ok or not restored.ok or restored.world.to_dict() != world.to_dict():
			failures.append("signed64 endpoint/nested institution roundtrip failed: " + value)
	var before: Dictionary = world.to_dict()
	world.characters.player_1.money = -1
	var old_bytes := FileAccess.get_file_as_string(PATH)
	if service.save_world(world,PATH).ok or FileAccess.get_file_as_string(PATH) != old_bytes:
		failures.append("invalid live world must not overwrite valid save")
	world.characters.player_1.money = before.characters.player_1.money

# Catches permissive casts, dangling nested references, unknown schemas, and duplicate identities.
func test_rejects_invalid_saves() -> void:
	var service = load("res://persistence/save_service.gd").new()
	service.save_world(_world(), PATH)
	var valid: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	for kind in ["duplicate", "reference", "fraction", "numeric_string", "bool", "range", "rng_overflow", "rng_number", "rng_plus", "rng_negative_overflow", "rng_leading_zero", "missing", "version", "organization", "investigation", "assignment", "history", "focus", "event", "unknown"]:
		var bad := valid.duplicate(true)
		match kind:
			"duplicate": bad.characters.append(bad.characters[0].duplicate(true))
			"reference": bad.characters[0].relationships.missing = 30
			"fraction": bad.day_index = 7.5
			"numeric_string": bad.characters[0].money = "2"
			"bool": bad.day_index = true
			"range": bad.characters[0].health = 101
			"rng_overflow": bad.rng_state = "9223372036854775808"
			"rng_number": bad.rng_state = 12
			"rng_plus": bad.rng_state = "+12"
			"rng_negative_overflow": bad.rng_state = "-9223372036854775809"
			"rng_leading_zero": bad.rng_state = "01"
			"missing": bad.erase("pending_events")
			"version": bad.schema_version = 2
			"organization": bad.organizations[0].leader_id = "missing"
			"investigation": bad.organizations[1].investigations = {"missing":{"target_id":"missing","progress":0,"evidence":30,"opened_day":1}}
			"assignment": bad.organizations[2].assignments = {"cem":"missing"}
			"history": bad.history.append({"type":"death","day":1,"character_id":"missing","cause":"lifespan"})
			"focus": bad.active_focus.actor_id = "missing"
			"event": bad.pending_events[0].participant_ids.append("missing")
			"unknown": bad.surprise = 1
		_write(bad)
		var result: Dictionary = service.load_world(PATH)
		if result.ok or result.reason.is_empty() or result.get("world") != null: failures.append("invalid save accepted: " + kind)
	for fixture in ["res://tests/fixtures/invalid.json", "res://tests/fixtures/unsupported_version.json", "user://saves/missing_save_test.json"]:
		if service.load_world(fixture).ok: failures.append("invalid/missing fixture accepted: " + fixture)

# Existing identities are insufficient: personal focus/events must belong to the current player.
func test_personal_actors_must_match_player() -> void:
	var service = load("res://persistence/save_service.gd").new()
	service.save_world(_world(),PATH)
	var valid: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	for kind in ["focus_npc", "event_npc"]:
		var bad := valid.duplicate(true)
		if kind == "focus_npc":
			bad.active_focus.actor_id = "cem"
		else:
			var event: Dictionary = bad.pending_events[0]
			event.actor_id = "cem"
			event.instance_id = "cem:" + event.template_id
			event.participant_ids[0] = "cem"
		_write(bad)
		var result: Dictionary = service.load_world(PATH)
		if result.ok or result.world != null or result.reason.is_empty(): failures.append("personal state must reject existing non-player actor: " + kind)

# Out-of-range days must fail before Calendar.date_on can loop on untrusted huge values.
func test_supported_day_limits_do_not_replace_live_world() -> void:
	var service = load("res://persistence/save_service.gd").new()
	service.save_world(_world(),PATH)
	var valid: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	valid.active_focus = {}
	valid.pending_events = []
	var scene = load("res://main.tscn").instantiate()
	(Engine.get_main_loop() as SceneTree).root.add_child(scene)
	scene.set_process(false)
	scene.hud.start_requested.emit("light")
	scene.save_path = PATH
	var live = scene.world
	var snapshot: Dictionary = live.to_dict()
	for day in [365251, 9007199254740991]:
		var bad := valid.duplicate(true)
		bad.day_index = day
		_write(bad)
		var result: Dictionary = service.load_world(PATH)
		if result.ok:
			# Do not dispatch a known unsafe load into Calendar during the RED run.
			failures.append("unsupported day_index accepted: " + str(day))
			continue
		if result.world != null or not result.reason.contains("365250"): failures.append("unsupported date must explain supported day limit")
		scene.hud.load_requested.emit()
		if scene.world != live or live.to_dict() != snapshot or not scene.hud.save_feedback.text.contains("365250"):
			failures.append("unsupported day must preserve live world and show date-range error")
	# The supported endpoint must still load and render the HUD calendar.
	valid.day_index = 365250
	_write(valid)
	scene.hud.load_requested.emit()
	if scene.world == live or scene.world.day_index != 365250 or not scene.simulation.paused or scene.hud.date_label.text.is_empty():
		failures.append("maximum supported date must load, refresh HUD and pause")
	scene.free()

# Only the IO boundary fails; real save code must leave the existing slot bytes loadable.
func test_save_write_failure_preserves_previous_file() -> void:
	var service = load("res://persistence/save_service.gd").new()
	var world = _world()
	service.save_world(world, PATH)
	var previous := FileAccess.get_file_as_string(PATH)
	for stage in ["write", "backup", "install"]:
		var broken = FailingIO.new(stage)
		var saving = load("res://persistence/save_service.gd").new(broken)
		world.day_index += 1
		if saving.save_world(world, PATH).ok or FileAccess.get_file_as_string(PATH) != previous or not service.load_world(PATH).ok:
			failures.append("test_save_write_failure_preserves_previous_file: " + stage)

# Real HUD signal wiring must refresh every panel only on successful load and pause time.
func test_corrupt_save_keeps_live_world() -> void:
	var scene = load("res://main.tscn").instantiate()
	(Engine.get_main_loop() as SceneTree).root.add_child(scene)
	scene.set_process(false)
	scene.hud.start_requested.emit("dark")
	if not scene.hud.has_signal("save_requested"):
		failures.append("save/load HUD signals missing"); scene.free(); return
	scene.save_path = PATH
	scene.hud.save_requested.emit()
	var old = scene.world
	var snapshot: Dictionary = old.to_dict()
	scene.simulation.advance_days(old, 3)
	scene.simulation.set_paused(false)
	scene.hud.load_requested.emit()
	if scene.world == old or scene.world.to_dict() != snapshot or not scene.simulation.paused or scene.hud.focus_panel._world != scene.world:
		failures.append("successful load must replace references, refresh panels and pause")
	var live = scene.world
	var before: Dictionary = live.to_dict()
	_write({"schema_version":99})
	scene.hud.load_requested.emit()
	if scene.world != live or live.to_dict() != before or scene.hud.save_feedback.text.is_empty(): failures.append("corrupt save must preserve live world and explain error")
	scene.free()

class FailingIO:
	extends RefCounted
	var stage: String
	func _init(value: String): stage = value
	func write_file(path: String, text: String) -> Error:
		if stage == "write": return ERR_FILE_CANT_WRITE
		var file := FileAccess.open(path, FileAccess.WRITE)
		if file == null: return FileAccess.get_open_error()
		file.store_string(text)
		file.close()
		return OK
	func rename_file(from: String, to: String) -> Error:
		if (stage == "backup" and to.ends_with(".bak")) or (stage == "install" and from.ends_with(".tmp")): return ERR_CANT_CREATE
		return DirAccess.rename_absolute(from, to)
