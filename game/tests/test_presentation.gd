extends RefCounted

const Factory = preload("res://core/world_factory.gd")
const Authority = preload("res://features/careers/authority_service.gd")

func run() -> Array[String]:
	var failures: Array[String] = []
	failures.append_array(test_refresh_does_not_mutate_world())
	failures.append_array(test_district_readout_matches_state())
	failures.append_array(test_patrol_representation_and_pause())
	failures.append_array(test_institution_text_is_readable())
	return failures

func _city():
	var city = load("res://city/city.tscn").instantiate()
	(Engine.get_main_loop() as SceneTree).root.add_child(city)
	city.configure(JSON.parse_string(FileAccess.get_file_as_string("res://content/city.json")))
	return city

# Catches accidental simulation ticks, dictionary writes or RNG use during rendering.
func test_refresh_does_not_mutate_world() -> Array[String]:
	var city = _city()
	if not city.has_method("refresh"):
		city.free()
		return ["test_refresh_does_not_mutate_world: CityView.refresh missing"]
	var world = Factory.create("light", 77)
	var before := world.to_dict()
	city.refresh(world)
	city.refresh(world)
	var failures: Array[String] = []
	if world.to_dict() != before: failures.append("refresh must not mutate world or RNG")
	city.free()
	return failures

# Catches static guide values, stale selection after events, or conflating criminal influence with office.
func test_district_readout_matches_state() -> Array[String]:
	var hud = load("res://ui/hud.tscn").instantiate()
	(Engine.get_main_loop() as SceneTree).root.add_child(hud)
	hud.configure(JSON.parse_string(FileAccess.get_file_as_string("res://content/city.json")))
	var world = Factory.create("light", 77)
	world.districts.liman.trust = 73
	world.districts.liman.prosperity = 64
	world.districts.liman.crime_pressure = 19
	world.districts.liman.influence.harbor_network = 82
	hud.refresh_world(world, true, 1)
	hud.show_district("liman")
	var failures: Array[String] = []
	for expected in ["Güven: 73/100", "Suç baskısı: 19/100", "Refah: 64/100", "Resmî yönetici: Kemal", "Liman Çevresi: 82/100"]:
		if not hud.description.text.contains(expected): failures.append("district readout missing real state: " + expected)
	world.districts.liman.trust = 81
	hud.refresh_world(world, true, 1)
	if not hud.description.text.contains("Güven: 81/100"): failures.append("selected district must update without another click")
	hud.show_building("liman_cafe")
	if not hud.description.text.contains("Güven: 81/100"): failures.append("building detail must include its district state")
	hud.free()
	return failures

# Catches missing district patrols, frame-driven domain decisions, and motion continuing while paused.
func test_patrol_representation_and_pause() -> Array[String]:
	var city = _city()
	if not city.has_method("refresh"):
		city.free()
		return ["patrol representation: CityView.refresh missing"]
	var world = Factory.create_scenario("police_demo", 77)
	Authority.apply(world, world.player_id, "assign_patrol", {"district_id":"liman"})
	city.refresh(world)
	var crowd = city.get_node_or_null("Crowd")
	var failures: Array[String] = []
	if crowd == null:
		failures.append("city must show representative crowd")
	else:
		var patrols: Array = []
		for agent in crowd.get_children():
			if agent.get_meta("kind", "") == "police": patrols.append(agent)
		if patrols.size() != 1 or patrols[0].get_meta("district_id") != "liman": failures.append("assigned patrol must be represented in liman only")
		if crowd.get_child_count() < 7 or crowd.get_child_count() > 24: failures.append("bounded pedestrian and car population required")
		var before := world.to_dict()
		var agent: Node3D = crowd.get_child(0)
		var start := agent.position
		crowd.set_paused(true)
		crowd._process(1.0)
		if agent.position != start: failures.append("paused visual agents must not move")
		crowd.set_paused(false)
		crowd._process(1.0)
		if agent.position == start: failures.append("unpaused visual agents must move")
		if world.to_dict() != before: failures.append("crowd animation must not change domain state")
		city.refresh(world)
		if crowd.get_child_count() > 24: failures.append("refresh must not duplicate crowd")
		world.day_index += 8
		city.refresh(world)
		for item in crowd.get_children():
			if item.get_meta("kind", "") == "police": failures.append("old patrol markers must expire")
	city.free()
	return failures

# Catches inheriting the engine's white label text on the cream institution panel.
func test_institution_text_is_readable() -> Array[String]:
	var hud = load("res://ui/hud.tscn").instantiate()
	(Engine.get_main_loop() as SceneTree).root.add_child(hud)
	var color: Color = hud.authority_panel.status.get_theme_color("font_color")
	hud.free()
	if color.get_luminance() > 0.35: return ["institution text must be dark enough to read on cream panels"]
	return []
