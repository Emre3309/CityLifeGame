extends RefCounted

const Factory = preload("res://core/world_factory.gd")
const Commands = preload("res://core/command_service.gd")
const Sim = preload("res://core/simulation.gd")
const Calendar = preload("res://core/calendar.gd")
var failures: Array[String] = []

func run() -> Array[String]:
	test_imprisonment_consumes_days_and_blocks_focus()
	test_frame_stops_at_death_and_domain_can_continue()
	test_summary_and_next_life_ui()
	if not ResourceLoader.exists("res://features/life/life_service.gd"):
		failures.append_array(["test_death_is_idempotent_and_stops_personal_actions: lifecycle missing", "test_next_life_preserves_world_without_inheritance: lifecycle missing", "test_imprisonment_consumes_days_and_blocks_focus: lifecycle missing"])
		return failures
	test_death_is_idempotent_and_stops_personal_actions()
	test_next_life_preserves_world_without_inheritance()
	test_death_and_next_life_roundtrip()
	test_prison_date_is_bounded_before_hud_calendar()
	return failures

# Repeating an event death must neither duplicate history nor leave a personal reward alive.
func test_death_is_idempotent_and_stops_personal_actions() -> void:
	var world = Factory.create("dark", 7)
	var life = load("res://features/life/life_service.gd")
	Commands.execute(world,{"type":"start_focus","focus_id":"street_connections"})
	Sim.new().advance_days(world,3)
	life.end_life(world,world.player_id,"Olay sonucu")
	var snapshot: Dictionary = world.to_dict()
	life.end_life(world,world.player_id,"Tekrar")
	if world.to_dict() != snapshot or world.characters.player_1.death_day != 3 or not world.active_focus.is_empty() or not world.pending_events.is_empty(): failures.append("death must be idempotent and clear personal focus/events")
	if Commands.execute(world,{"type":"start_focus","focus_id":"street_connections"}).ok or Commands.execute(world,{"type":"resolve_event","event_id":"player_1:port_offer","choice_id":"accept"}).ok: failures.append("dead player must not act")
	var deadline = Factory.create("dark",7)
	Commands.execute(deadline,{"type":"start_focus","focus_id":"street_connections"})
	deadline.characters.player_1.lifespan_end_day = deadline.active_focus.end_day
	Sim.new().advance_days(deadline,deadline.active_focus.end_day)
	if not deadline.completed_focuses.is_empty() or not deadline.characters.player_1.knowledge.is_empty() or deadline.characters.player_1.death_day != deadline.day_index: failures.append("lifespan deadline must cancel same-day focus reward")

# A changed identity must not inherit old office, wealth, knowledge, completed focuses or event locks.
func test_next_life_preserves_world_without_inheritance() -> void:
	var world = Factory.create("dark",7)
	var life = load("res://features/life/life_service.gd")
	var before: Dictionary = world.to_dict()
	if Commands.execute(world,{"type":"start_next_life","route":"light"}).ok or world.to_dict() != before: failures.append("living player cannot start another life")
	world.day_index = 365
	world.characters.player_1.money = 9000
	world.characters.player_1.role = "gang_leader"
	world.characters.player_1.knowledge = {"street":90}
	world.completed_focuses.append("street_connections")
	world.resolved_event_ids.append("player_1:port_offer")
	world.districts.liman.influence.harbor_network = 83
	life.end_life(world,"player_1","Olay sonucu")
	var old: Dictionary = world.characters.player_1.duplicate(true)
	var history: Array = world.history.duplicate(true)
	var districts: Dictionary = world.districts.duplicate(true)
	var orgs: Dictionary = world.organizations.duplicate(true)
	var result: Dictionary = Commands.execute(world,{"type":"start_next_life","route":"light"})
	if not result.ok: failures.append("next life rejected: " + result.reason); return
	var actor: Dictionary = world.characters[world.player_id]
	if world.player_id == "player_1" or world.characters.player_1 != old or world.day_index != 365 or world.districts != districts or world.organizations != orgs: failures.append("new life must preserve old character, date, institutions and district effects")
	for entry in history:
		if entry not in world.history: failures.append("new life erased old history")
	if actor.birth_date != {"year":1946,"month":3,"day":1} or Calendar.age_on(actor.birth_date,Calendar.date_on(world.day_index)) != {"years":17,"months":6}: failures.append("next life must begin age 17y6m from current date")
	if actor.money != 100 or actor.role != "citizen" or not actor.knowledge.is_empty() or not actor.relationships.is_empty() or actor.get("unlocked_actions",[]) != [] or not world.completed_focuses.is_empty() or not world.resolved_event_ids.is_empty() or not world.active_focus.is_empty() or not world.pending_events.is_empty(): failures.append("new life inherited personal progress or privilege")
	# March 31 minus 210 calendar months is September 30, not an invalid September 31.
	world.day_index = 211
	life.end_life(world,world.player_id,"Kontrollü test")
	life.start_next_life(world,"dark")
	if world.characters[world.player_id].birth_date != {"year":1945,"month":9,"day":30}: failures.append("calendar month subtraction must clamp month-end births")
	world.characters.cem.death_day = 1
	Sim.new().advance_days(world,1)
	for event in world.pending_events:
		if "cem" in event.participant_ids: failures.append("new-life event must not queue a preserved dead NPC")

# Prison blocks normal actions but not days/age, and release opens focus eligibility.
func test_imprisonment_consumes_days_and_blocks_focus() -> void:
	var world = Factory.create("dark",7)
	world.characters.player_1.imprisoned_until = 3
	world.history.append({"type":"conviction","day":0,"character_id":"player_1","imprisoned_until":3,"reason":"Delilli operasyon"})
	if Commands.execute(world,{"type":"start_focus","focus_id":"street_connections"}).ok: failures.append("prison must block focus")
	Sim.new().advance_days(world,3)
	if world.day_index != 3 or world.characters.player_1.imprisoned_until != -1 or not Commands.execute(world,{"type":"start_focus","focus_id":"street_connections"}).ok: failures.append("prison must consume days and release on its deadline")
	var releases: Array = world.history.filter(func(entry): return entry.type == "release")
	if releases.size() != 1: failures.append("release must be recorded exactly once")

func test_frame_stops_at_death_and_domain_can_continue() -> void:
	var world = Factory.create("light",7)
	world.characters.player_1.lifespan_end_day = 2
	var sim = Sim.new()
	sim.set_speed(12)
	sim.set_paused(false)
	sim.advance_frame(world,10.0)
	if world.day_index != 2 or not sim.paused: failures.append("frame batch must pause exactly at player death")
	sim.advance_frame(world,10.0)
	if world.day_index != 2: failures.append("dead UI player cannot accumulate days")
	sim.advance_days(world,7)
	if world.day_index != 9: failures.append("direct domain batch may continue NPC history after player death")

func test_death_and_next_life_roundtrip() -> void:
	var world = Factory.create("dark",7)
	var life = load("res://features/life/life_service.gd")
	var saves = load("res://persistence/save_service.gd").new()
	world.characters.player_1.imprisoned_until = 1
	Sim.new().advance_days(world,1)
	life.end_life(world,world.player_id,"Olay sonucu")
	for next in [false,true]:
		if next: life.start_next_life(world,"light")
		var saved: Dictionary = saves.save_world(world,"user://saves/life_test.json")
		var loaded: Dictionary = saves.load_world("user://saves/life_test.json")
		if not saved.ok or not loaded.ok or loaded.world.to_dict() != world.to_dict(): failures.append("death/new-life roundtrip failed: " + str(saved))

# Real scene signals exercise the summary and continuation without GUI automation.
func test_summary_and_next_life_ui() -> void:
	var scene = load("res://main.tscn").instantiate()
	(Engine.get_main_loop() as SceneTree).root.add_child(scene)
	scene.set_process(false)
	scene.hud.start_requested.emit("dark")
	scene.world.characters.player_1.imprisoned_until = 3
	scene.world.history.append({"type":"conviction","day":0,"character_id":"player_1","imprisoned_until":3,"reason":"Delilli operasyon"})
	scene._refresh_hud()
	if not scene.hud.age_label.text.contains("04.09.1962") or not scene.hud.age_label.text.contains("Delilli operasyon"): failures.append("HUD must show prison release date and reason")
	scene.world.characters.player_1.lifespan_end_day = 1
	scene.simulation.set_paused(false)
	scene._process(10.0)
	var panel = scene.hud.get("life_summary_panel")
	if panel == null: failures.append("life summary panel missing"); scene.free(); return
	if not panel.visible or not scene.simulation.paused or not panel.entries.text.contains("Kariyer") or not panel.entries.text.contains("İlişkiler") or not panel.entries.text.contains("Mahalle"): failures.append("death must show career, relationships and lasting world summary")
	panel.next_life_requested.emit("light")
	if scene.world.player_id == "player_1" or panel.visible or not scene.simulation.paused: failures.append("summary new-life route must replace player and keep pause")
	scene.hud.show_district("liman")
	if scene.hud.description.text.is_empty() or not scene.world.characters.has("player_1"): failures.append("old world effects must remain inspectable after continuation")
	scene.free()

# Prison end dates now reach the calendar HUD; reject enormous values before scene refresh.
func test_prison_date_is_bounded_before_hud_calendar() -> void:
	var world = Factory.create("dark",7)
	world.characters.player_1.imprisoned_until = 9007199254740991
	var saves = load("res://persistence/save_service.gd").new()
	if saves.save_world(world,"user://saves/life_invalid_test.json").ok: failures.append("prison release date must be bounded before calendar display")
