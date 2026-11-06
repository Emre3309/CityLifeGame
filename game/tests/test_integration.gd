extends RefCounted

const Factory = preload("res://core/world_factory.gd")
const Commands = preload("res://core/command_service.gd")
const Sim = preload("res://core/simulation.gd")
var failures: Array[String] = []

func run() -> Array[String]:
	test_full_life_flow()
	test_dark_risk_has_causes_and_no_instant_punishment()
	test_police_evidence_and_authority_flow()
	return failures

# Catches broken scene wiring, premature/missing graduation, missing NPC ticks,
# partial save restoration, and inheritance or date reset on the next identity.
func test_full_life_flow() -> void:
	var scene = load("res://main.tscn").instantiate()
	(Engine.get_main_loop() as SceneTree).root.add_child(scene)
	scene.set_process(false)
	scene.save_path = "user://saves/integration.json"
	scene.hud.start_panel.route_chosen.emit("light")
	var w = scene.world
	if w == null: failures.append("full_life: route signal did not create world"); scene.free(); return
	if not scene.simulation.paused or w.characters.player_1.education != "high_school_graduate": failures.append("full_life: light start must be paused graduate")
	scene.hud.show_district("liman")
	if scene.hud.selected_district_id != "liman" or scene.hud.description.text.is_empty(): failures.append("full_life: district readout missing")
	scene.hud.focus_button.pressed.emit()
	scene.hud.focus_panel.start_buttons.university_prep.pressed.emit()
	if w.active_focus.get("id","") != "university_prep" or w.characters.player_1.money != 60: failures.append("full_life: focus signal must start and charge once")
	scene._process(10.0)
	if w.day_index != 0: failures.append("full_life: paused time advanced")
	scene.hud.speed_requested.emit(12)
	scene.hud.pause_requested.emit()
	scene._process(2.25)
	if w.day_index != 27 or w.characters.player_1.education != "high_school_graduate": failures.append("full_life: day 27 must remain in preparation")
	scene.hud.speed_requested.emit(1)
	scene._process(1.0)
	scene.hud.pause_requested.emit()
	if w.day_index != 28 or w.characters.player_1.education != "university_enrolled" or w.characters.player_1.knowledge.get("study",0) != 10 or w.completed_focuses.count("university_prep") != 1: failures.append("full_life: day 28 university entry must reward once")
	if w.characters.player_1.role != "citizen": failures.append("full_life: university entry must not award office")
	var npc_actions: Array = w.history.filter(func(e): return e.type == "authority_action" and e.actor_id != w.player_id)
	if npc_actions.is_empty() or w.districts.liman.influence.harbor_network <= 20: failures.append("full_life: independent NPC must change city")
	scene.hud.events_button.pressed.emit()
	var key := "player_1:family_support:part_time_work"
	if not scene.hud.event_panel.choice_buttons.has(key): failures.append("full_life: family choice absent"); scene.free(); return
	scene.hud.event_panel.choice_buttons[key].pressed.emit()
	if w.characters.player_1.money != 85 or w.characters.player_1.relationships.nermin != 78 or w.characters.nermin.relationships.player_1 != 78: failures.append("full_life: family decision must update real money and both relationships")
	var snapshot: Dictionary = w.to_dict()
	scene.hud.save_requested.emit()
	scene.simulation.advance_days(w,2)
	scene.hud.load_requested.emit()
	if scene.world == w or scene.world.to_dict() != snapshot or not scene.simulation.paused: failures.append("full_life: load must replace complete snapshot and pause")
	w = scene.world
	# Controlled lifespan fixture reaches actual daily death logic, without waiting 65 years.
	w.characters.player_1.lifespan_end_day = 29
	scene.hud.pause_requested.emit()
	scene._process(5.0)
	if w.day_index != 29 or not scene.simulation.paused or not scene.hud.life_summary_panel.visible or w.characters.player_1.death_day != 29: failures.append("full_life: death must stop time and show summary")
	var old: Dictionary = w.characters.player_1.duplicate(true)
	var districts: Dictionary = w.districts.duplicate(true)
	var history: Array = w.history.duplicate(true)
	scene.hud.life_summary_panel.next_life_requested.emit("dark")
	if w.player_id != "player_2" or w.day_index != 29 or w.characters.player_1 != old or w.districts != districts or not scene.simulation.paused or scene.hud.life_summary_panel.visible: failures.append("full_life: next life must preserve date and world, close summary and stay paused")
	for entry in history:
		if entry not in w.history: failures.append("full_life: history erased")
	var actor: Dictionary = w.characters[w.player_id]
	if actor.route != "dark" or actor.money != 100 or actor.role != "citizen" or not actor.knowledge.is_empty() or not actor.relationships.is_empty() or not w.completed_focuses.is_empty(): failures.append("full_life: new person inherited old personal progress")
	scene.hud.save_requested.emit()
	scene.hud.load_requested.emit()
	if scene.world.player_id != "player_2" or scene.world.characters.player_1 != old: failures.append("full_life: new-life persistence lost identities")
	scene.free()

# Across real seeded daily runs both detection outcomes occur; risk alone is never instant prison/death.
func test_dark_risk_has_causes_and_no_instant_punishment() -> void:
	var outcomes: Dictionary = {}
	for seed_value in range(1,25):
		var w = Factory.create("dark",seed_value)
		if not Commands.execute(w,{"type":"start_focus","focus_id":"street_connections"}).ok: failures.append("dark: start focus rejected"); return
		Sim.new().advance_days(w,7)
		var result: Dictionary = Commands.execute(w,{"type":"resolve_event","event_id":"player_1:port_offer","choice_id":"accept"})
		if not result.ok: failures.append("dark: triggered port offer rejected"); return
		var risk: int = w.characters.player_1.investigation_risk
		outcomes[risk] = true
		if risk not in [0,25] or w.characters.player_1.money != 200 or w.characters.player_1.relationships.nermin != 58 or w.characters.player_1.imprisoned_until != -1 or w.characters.player_1.death_day != -1 or not result.reason.contains("Soruşturma riski"): failures.append("dark: money, relationship, risk and punishment causal contract failed")
		Sim.new().advance_days(w,7)
		if w.characters.player_1.knowledge.get("street",0) != 10 or w.completed_focuses.count("street_connections") != 1: failures.append("dark: focus failed across event decision")
	if outcomes.size() != 2: failures.append("dark: detection and no-detection outcomes both required")

# A chief cannot allocate governor money; cases need evidence/time, then explicit operation and release.
func test_police_evidence_and_authority_flow() -> void:
	var w = Factory.create_scenario("police_demo",9)
	var before: Dictionary = w.to_dict()
	if _order(w,"allocate_budget",{"organization_id":"police","amount":100}).ok or w.to_dict() != before: failures.append("police: governor power leaked to chief")
	if not _order(w,"open_investigation",{"target_id":"riza"}).ok: failures.append("police: case opening rejected"); return
	before = w.to_dict()
	if _order(w,"launch_operation",{"target_id":"riza"}).ok or w.to_dict() != before: failures.append("police: insufficient evidence must leave world unchanged")
	Sim.new().advance_days(w,14)
	var case_data: Dictionary = w.organizations.police.investigations.riza
	if case_data.evidence < 60 or case_data.progress < 50 or w.characters.riza.imprisoned_until != -1: failures.append("police: review must accumulate evidence without taking player decision")
	var budget: int = w.organizations.police.budget
	if not _order(w,"launch_operation",{"target_id":"riza"}).ok or w.organizations.police.budget != budget-100 or w.characters.riza.imprisoned_until != 44 or w.characters.riza.death_day != -1: failures.append("police: explicit operation must spend institutional budget and convict for 30 days")
	var convictions: Array = w.history.filter(func(e): return e.type == "conviction" and e.character_id == "riza")
	if convictions.size() != 1: failures.append("police: conviction cause missing or duplicated")
	Sim.new().advance_days(w,30)
	if w.day_index != 44 or w.characters.riza.imprisoned_until != -1: failures.append("police: prison term must consume dates and release")

func _order(w, action: String, payload: Dictionary) -> Dictionary:
	return Commands.execute(w,{"type":"authority","actor_id":w.player_id,"action":action,"payload":payload})
