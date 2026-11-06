extends RefCounted

func run() -> Array[String]:
	for file in ["calendar", "world_state", "world_factory", "simulation", "command_service", "content_catalog"]:
		if not ResourceLoader.exists("res://core/%s.gd" % file):
			return ["test_start_age_and_route: missing world/calendar implementation (%s)" % file]
	var failures: Array[String] = []
	failures.append_array(test_start_age_and_route())
	failures.append_array(test_calendar_boundaries())
	failures.append_array(test_invalid_route_has_no_world())
	failures.append_array(test_content_identity_validation())
	failures.append_array(test_pause_produces_zero_ticks())
	failures.append_array(test_batch_equals_daily())
	failures.append_array(test_world_snapshot_is_independent())
	failures.append_array(test_start_panel_command_and_readout())
	return failures

# Catches incorrect birth/start dates, swapped route histories and unbounded lifespans.
func test_start_age_and_route() -> Array[String]:
	var factory = load("res://core/world_factory.gd")
	var calendar = load("res://core/calendar.gd")
	var failures: Array[String] = []
	for route in ["light", "dark"]:
		var world = factory.create(route, 42)
		var actor: Dictionary = world.characters[world.player_id]
		if calendar.age_on(actor.birth_date, {"year":1962,"month":9,"day":1}) != {"years":17,"months":6}:
			failures.append("test_start_age_and_route: start age must be 17 years 6 months")
		var expected := "high_school_graduate" if route == "light" else "high_school_dropout"
		if actor.education != expected or actor.route != route or actor.role != "citizen" or actor.background.is_empty():
			failures.append("test_start_age_and_route: route must seed known history and education as a citizen")
		for character in world.characters.values():
			if character.lifespan_end_day <= 0 or character.death_day != -1:
				failures.append("every initial actor needs a finite future lifespan")
	return failures

# Catches year rollover, leap years/centuries and incomplete birth months.
func test_calendar_boundaries() -> Array[String]:
	var calendar = load("res://core/calendar.gd")
	var failures: Array[String] = []
	for row in [[{"year":1963,"month":12,"day":31},1,{"year":1964,"month":1,"day":1}], [{"year":1964,"month":2,"day":28},1,{"year":1964,"month":2,"day":29}], [{"year":1900,"month":2,"day":28},1,{"year":1900,"month":3,"day":1}], [{"year":2000,"month":2,"day":28},1,{"year":2000,"month":2,"day":29}], [{"year":1964,"month":3,"day":1},-1,{"year":1964,"month":2,"day":29}]]:
		if calendar.add_days(row[0], row[1]) != row[2]:
			failures.append("test_calendar_boundaries: incorrect calendar boundary")
	if calendar.age_on({"year":1945,"month":3,"day":1},{"year":1962,"month":8,"day":31}) != {"years":17,"months":5}:
		failures.append("age must count completed months")
	return failures

# Catches a fallback route or a second start command replacing the live identity.
func test_invalid_route_has_no_world() -> Array[String]:
	var factory = load("res://core/world_factory.gd")
	var commands = load("res://core/command_service.gd")
	var failures: Array[String] = []
	if factory.create("unknown", 42) != null:
		failures.append("invalid route must not create a world")
	var start: Dictionary = commands.execute(null, {"type":"start_world","route":"light","seed":42})
	if not start.ok:
		return ["valid start command must create a world"]
	var world = start.world
	var before: Dictionary = world.to_dict()
	if commands.execute(world, {"type":"start_world","route":"dark"}).ok or world.to_dict() != before:
		failures.append("route cannot be reselected after start")
	if commands.execute(world, {"type":"unknown"}).ok or world.to_dict() != before:
		failures.append("unknown commands must leave world unchanged")
	return failures

# Catches duplicate identities and missing district/character references before world construction.
func test_content_identity_validation() -> Array[String]:
	var catalog = load("res://core/content_catalog.gd")
	var loaded: Dictionary = catalog.load_all("res://content")
	if not loaded.ok:
		return ["valid shipped catalog rejected: " + str(loaded.errors)]
	var failures: Array[String] = []
	var bad: Dictionary = loaded.data.duplicate(true)
	bad.characters.append(bad.characters[0].duplicate(true))
	if catalog.validate(bad).is_empty():
		failures.append("duplicate character ids must be rejected")
	bad = loaded.data.duplicate(true)
	bad.city.buildings[0].district_id = "missing"
	if catalog.validate(bad).is_empty():
		failures.append("dangling building district must be rejected")
	bad = loaded.data.duplicate(true)
	bad.characters[0].district_id = "missing"
	if catalog.validate(bad).is_empty():
		failures.append("dangling actor district must be rejected")
	bad = loaded.data.duplicate(true)
	bad.organizations[0].leader_id = "missing"
	if catalog.validate(bad).is_empty():
		failures.append("dangling organization leader must be rejected")
	return failures

# Catches banked pause time, residual fractions, incorrect speed and nonpositive day mutation.
func test_pause_produces_zero_ticks() -> Array[String]:
	var world = load("res://core/world_factory.gd").create("light", 7)
	var simulation = load("res://core/simulation.gd").new()
	var failures: Array[String] = []
	var before: Dictionary = world.to_dict()
	simulation.advance_frame(world, 90.0)
	simulation.advance_days(world, 0)
	simulation.advance_days(world, -5)
	if world.to_dict() != before:
		failures.append("paused or nonpositive steps must not mutate world")
	simulation.set_paused(false)
	simulation.advance_frame(world, 0.9)
	simulation.set_paused(true)
	simulation.advance_frame(world, 100.0)
	simulation.set_paused(false)
	simulation.advance_frame(world, 0.2)
	if world.day_index != 0:
		failures.append("pause must discard partial elapsed time")
	simulation.advance_frame(world, 0.8)
	if world.day_index != 1:
		failures.append("one second at normal speed must advance one day")
	for speed in [4,12]:
		simulation.set_speed(speed)
		simulation.advance_frame(world, 1.0)
	if world.day_index != 17:
		failures.append("4 and 12 days/second speeds must apply")
	return failures

# Catches skipping daily stages in large advances, including expiry on an intermediate day.
func test_batch_equals_daily() -> Array[String]:
	var factory = load("res://core/world_factory.gd")
	var simulation = load("res://core/simulation.gd").new()
	var batch = factory.create("dark", 99)
	var daily = factory.create("dark", 99)
	batch.characters[batch.player_id].lifespan_end_day = 3
	daily.characters[daily.player_id].lifespan_end_day = 3
	simulation.advance_days(batch, 10)
	for day in range(10):
		simulation.advance_days(daily, 1)
	if batch.to_dict() != daily.to_dict() or batch.day_index != 10 or batch.characters[batch.player_id].death_day != 3:
		return ["batch must execute every day, including life checks on day 3"]
	if batch.history.size() != 1:
		return ["lifespan death must be recorded once"]
	return []

# Catches aliasing between snapshots and live state; later save/load relies on this boundary.
func test_world_snapshot_is_independent() -> Array[String]:
	var world = load("res://core/world_factory.gd").create("light", 123)
	var snapshot: Dictionary = world.to_dict()
	var restored = load("res://core/world_state.gd").from_dict(snapshot)
	restored.characters[restored.player_id].money = 0
	if world.characters[world.player_id].money == 0 or snapshot.characters[snapshot.player_id].money == 0:
		return ["world snapshots and restored worlds must not alias live dictionaries"]
	return []

# Catches disconnected route buttons and stale calendar/age/pause readouts in the real scene.
func test_start_panel_command_and_readout() -> Array[String]:
	var scene = load("res://main.tscn").instantiate()
	var tree := Engine.get_main_loop() as SceneTree
	tree.root.add_child(scene)
	scene.set_process(false)
	var failures: Array[String] = []
	if scene.world != null or not scene.hud.start_panel.visible:
		failures.append("new game must wait for a route choice")
	scene.hud.start_panel.route_chosen.emit("light")
	if scene.world == null:
		failures.append("route choice must create the live world")
	else:
		if scene.hud.start_panel.visible or not scene.hud.date_label.text.contains("01.09.1962") or not scene.hud.age_label.text.contains("17 yıl 6 ay"):
			failures.append("HUD must display initial date/age and dismiss route panel")
		scene.hud.pause_button.pressed.emit()
		scene._process(1.0)
		if scene.world.day_index != 1 or not scene.hud.date_label.text.contains("02.09.1962"):
			failures.append("pause button must connect to frame stepping and refresh HUD date")
	scene.free()
	return failures
