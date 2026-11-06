extends RefCounted

func run() -> Array[String]:
	if not ResourceLoader.exists("res://features/careers/authority_service.gd"):
		return ["test_authority_matrix: authority service missing"]
	var f: Array[String] = []
	f.append_array(test_authority_matrix())
	f.append_array(test_dead_official_cannot_issue_orders())
	f.append_array(test_police_can_delay_operation())
	f.append_array(test_budget_cannot_go_negative())
	f.append_array(test_scenarios_and_panel())
	f.append_array(test_role_actions_change_real_state())
	f.append_array(test_malformed_payload_never_spends())
	return f

func test_authority_matrix() -> Array[String]:
	var service = load("res://features/careers/authority_service.gd")
	var w = load("res://core/world_factory.gd").create("light", 1)
	var roles := {"citizen":[], "governor":["set_security_priority","allocate_budget"], "police_chief":["open_investigation","assign_patrol","launch_operation"], "gang_leader":["assign_member","expand_influence"]}
	var actions := ["set_security_priority","allocate_budget","open_investigation","assign_patrol","launch_operation","assign_member","expand_influence"]
	for role in roles:
		w.characters.player_1.role = role
		for action in actions:
			if service.allowed(w, "player_1", action) != (action in roles[role]): return ["test_authority_matrix: role boundary " + role + ":" + action]
	return []

# Catches mutations, RNG consumption, spoofed actor, dead officials and invalid targets on denial.
func test_dead_official_cannot_issue_orders() -> Array[String]:
	var f: Array[String] = []
	var commands = load("res://core/command_service.gd")
	for kind in ["dead","lifespan","prison","spoof","role","district","amount","target","target_dead","member","unknown"]:
		var scenario := "police_demo" if kind in ["target","target_dead"] else ("gang_demo" if kind == "member" else "governor_demo")
		var w = load("res://core/world_factory.gd").create_scenario(scenario, 4)
		if w == null: return ["development scenario factory missing"]
		var c := {"type":"authority", "actor_id":w.player_id, "action":"allocate_budget", "payload":{"organization_id":"police", "amount":100}}
		match kind:
			"dead": w.characters[w.player_id].death_day = 0
			"lifespan": w.characters[w.player_id].lifespan_end_day = 0
			"prison": w.characters[w.player_id].imprisoned_until = 1
			"spoof": c.actor_id = "selim"
			"role": c.action = "launch_operation"
			"district":
				c.action = "set_security_priority"
				c.payload = {"district_id":"missing"}
			"amount": c.payload.amount = -100
			"target":
				w.characters[w.player_id].role = "police_chief"
				c.action = "open_investigation"
				c.payload = {"target_id":"missing"}
			"target_dead":
				w.characters[w.player_id].role = "police_chief"
				w.characters.riza.death_day = 0
				c.action = "open_investigation"
				c.payload = {"target_id":"riza"}
			"member":
				w.characters[w.player_id].role = "gang_leader"
				c.action = "assign_member"
				c.payload = {"target_id":"nermin", "district_id":"liman"}
			"unknown": c.action = "execute_script"
		var before: Dictionary = w.to_dict()
		var result: Dictionary = commands.execute(w,c)
		if result.ok or result.reason.is_empty() or w.to_dict() != before: f.append("test_dead_official_cannot_issue_orders / atomic rejection: " + kind)
	return f

func test_police_can_delay_operation() -> Array[String]:
	var a = load("res://features/careers/authority_service.gd")
	var w = load("res://core/world_factory.gd").create_scenario("police_demo", 2)
	if w == null: return ["police scenario missing"]
	w.characters.riza.investigation_risk = 25
	if not a.apply(w,w.player_id,"open_investigation",{"target_id":"riza"}).ok: return ["police must open investigation"]
	var before: Dictionary = w.to_dict()
	if a.apply(w,w.player_id,"launch_operation",{"target_id":"riza"}).ok or w.to_dict() != before: return ["insufficient evidence must allow delay with no cost"]
	var sim = load("res://core/simulation.gd").new()
	sim.advance_days(w,14)
	if w.characters.riza.imprisoned_until > w.day_index: return ["NPC cannot use player police office to auto-arrest"]
	if w.organizations.police.investigations.riza.evidence < 60: return ["risk must meaningfully accumulate investigation evidence"]
	w.organizations.police.capacity = 0
	before = w.to_dict()
	if a.apply(w,w.player_id,"launch_operation",{"target_id":"riza"}).ok or w.to_dict() != before: return ["operation requires capacity before spending"]
	w.organizations.police.capacity = 3
	var result: Dictionary = a.apply(w,w.player_id,"launch_operation",{"target_id":"riza"})
	if not result.ok or w.characters.riza.imprisoned_until != w.day_index + 30 or w.characters.riza.death_day != -1: return ["evidence + capacity yields conviction and prison time, never death"]
	var found := false
	for e in w.history:
		if e.type == "conviction" and e.character_id == "riza": found = true
	return [] if found else ["prison must start with explicit conviction history"]

func test_budget_cannot_go_negative() -> Array[String]:
	var a = load("res://features/careers/authority_service.gd")
	var w = load("res://core/world_factory.gd").create_scenario("governor_demo", 3)
	if w == null: return ["governor scenario missing"]
	w.organizations.governorship.budget = 40
	var before: Dictionary = w.to_dict()
	if a.apply(w,w.player_id,"allocate_budget",{"organization_id":"police","amount":41}).ok or w.to_dict()!=before: return ["test_budget_cannot_go_negative"]
	if not a.apply(w,w.player_id,"allocate_budget",{"organization_id":"police","amount":40}).ok or w.organizations.governorship.budget != 0 or w.organizations.police.budget != 1240: return ["allocation must transfer existing treasury money"]
	w.organizations.governorship.budget = 20
	if not a.apply(w,w.player_id,"set_security_priority",{"district_id":"liman"}).ok: return ["governor priority must work"]
	for actor in w.characters.values():
		if actor.imprisoned_until > 0: return ["governor cannot auto-arrest"]
	return []

func test_scenarios_and_panel() -> Array[String]:
	var factory = load("res://core/world_factory.gd")
	var w = factory.create("light", 1)
	if w.characters.player_1.role != "citizen" or factory.create("governor_demo",1) != null: return ["normal route must remain citizen"]
	if factory.create_scenario("missing",1) != null: return ["invalid scenario must be rejected"]
	var scene = load("res://main.tscn").instantiate()
	(Engine.get_main_loop() as SceneTree).root.add_child(scene)
	scene.set_process(false)
	if not scene.hud.start_panel.has_signal("scenario_chosen"):
		scene.free()
		return ["separate development scenario menu missing"]
	scene.hud.start_panel.scenario_chosen.emit("governor_demo")
	if scene.world == null:
		scene.free()
		return ["scenario menu must create world"]
	scene.hud.authority_button.pressed.emit()
	var panel = scene.hud.authority_panel
	var before: int = scene.world.organizations.governorship.budget
	panel.action_buttons.allocate_budget.pressed.emit()
	var failures: Array[String] = []
	if scene.world.organizations.governorship.budget != before - 100 or panel.feedback.text.is_empty(): failures.append("authority panel must issue command with resource feedback")
	var snapshot: Dictionary = scene.world.to_dict()
	panel.refresh(scene.world)
	if scene.world.to_dict()!=snapshot: failures.append("panel refresh read only")
	if load("res://core/command_service.gd").execute(scene.world,{"type":"start_scenario","scenario_id":"gang_demo","seed":1}).ok: failures.append("scenario cannot replace running career")
	scene.free()
	return failures

# Catches no-op patrol/member/expansion implementations and cross-office spending.
func test_role_actions_change_real_state() -> Array[String]:
	var a = load("res://features/careers/authority_service.gd")
	var factory = load("res://core/world_factory.gd")
	var w = factory.create_scenario("police_demo",2)
	var result: Dictionary = a.apply(w,w.player_id,"assign_patrol",{"district_id":"cinar"})
	if not result.ok or w.districts.cinar.crime_pressure != 26 or w.districts.cinar.trust != 52 or w.organizations.police.budget != 1150 or w.organizations.police.capacity != 2: return ["patrol must spend emniyet resources and change selected district"]
	w = factory.create_scenario("gang_demo",2)
	if not a.apply(w,w.player_id,"assign_member",{"target_id":"cem","district_id":"cinar"}).ok or w.organizations.harbor_network.assignments.cem != "cinar": return ["gang leader must assign real network member"]
	if not a.apply(w,w.player_id,"expand_influence",{"district_id":"cinar"}).ok or w.districts.cinar.influence.harbor_network != 9 or w.organizations.harbor_network.budget != 730 or w.organizations.harbor_network.capacity != 1: return ["assigned member must support paid district influence attempt"]
	var snapshot: Dictionary = w.to_dict()
	if a.apply(w,w.player_id,"assign_member",{"target_id":"nermin","district_id":"liman"}).ok or w.to_dict() != snapshot: return ["gang cannot command an arbitrary citizen"]
	return []

# Catches ignored malformed extra fields later being read after treasury deduction.
func test_malformed_payload_never_spends() -> Array[String]:
	var a = load("res://features/careers/authority_service.gd")
	var w = load("res://core/world_factory.gd").create_scenario("governor_demo",3)
	for payload in [{"district_id":"liman","target_id":[]},{"district_id":42},{"district_id":"liman","execute_script":"x"}]:
		var before: Dictionary = w.to_dict()
		if a.availability(w,w.player_id,"set_security_priority",payload).ok: return ["malformed or extra payload fields must fail preflight"]
		if a.apply(w,w.player_id,"set_security_priority",payload).ok or w.to_dict()!=before: return ["malformed payload must preserve world, budget and RNG"]
	return []
