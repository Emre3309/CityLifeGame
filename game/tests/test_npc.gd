extends RefCounted

func run() -> Array[String]:
	var failures := test_npcs_act_without_player_focus()
	failures.append_array(test_weekly_tick_is_once_and_succession_is_coherent())
	failures.append_array(test_successor_must_be_qualified_adult())
	return failures

func test_npcs_act_without_player_focus() -> Array[String]:
	if not ResourceLoader.exists("res://features/npc/npc_service.gd"): return ["test_npcs_act_without_player_focus: NPC service missing"]
	var f: Array[String] = []
	var w = load("res://core/world_factory.gd").create("light",1)
	var sim = load("res://core/simulation.gd").new()
	var before: Dictionary = w.districts.duplicate(true)
	sim.advance_days(w,7)
	var acted := false
	for e in w.history:
		if e.type == "authority_action" and e.actor_id != w.player_id: acted = true
	if not acted or w.districts == before or not w.active_focus.is_empty(): f.append("test_npcs_act_without_player_focus: weekly decisions must affect districts")
	# Consumes event risk rather than inventing detection, and keeps zero-risk citizens untouched.
	w = load("res://core/world_factory.gd").create("dark",1)
	w.characters.player_1.investigation_risk = 25
	sim.advance_days(w,7)
	if not w.organizations.police.investigations.has("player_1") or w.organizations.police.investigations.has("nermin"): f.append("police must investigate actual risk only")
	# Catches a dead official acting before end-of-day death marker, and incoherent district ownership.
	w = load("res://core/world_factory.gd").create("light",1)
	w.characters.kemal.lifespan_end_day = 7
	w.characters.selim.death_day = 0
	w.characters.riza.death_day = 0
	sim.advance_days(w,7)
	for org_id in ["governorship","police","harbor_network"]:
		var id: String = w.organizations[org_id].leader_id
		if id in ["kemal","selim","riza"]: f.append("dead office holder must be vacated or replaced")
	for d in w.districts.values():
		if d.official_owner_id != w.organizations.governorship.leader_id: f.append("district owner must match governor office")
	for e in w.history:
		if e.type == "authority_action" and e.actor_id in ["kemal","selim","riza"]: f.append("dead NPC cannot act")
	w = load("res://core/world_factory.gd").create("light",1)
	for o in w.organizations.values(): o.budget = 0
	before = w.districts.duplicate(true)
	sim.advance_days(w,7)
	var skipped := false
	for e in w.history:
		if e.type == "npc_skipped" and not e.reason.is_empty(): skipped = true
	if not skipped or before != w.districts: f.append("insufficient resources must preserve district and record reason")
	return f

# Catches duplicate weekly spending, fabricated successors, and inheritance of a dead governor's wealth.
func test_weekly_tick_is_once_and_succession_is_coherent() -> Array[String]:
	var service = load("res://features/npc/npc_service.gd")
	if service == null: return ["NPC service missing"]
	var w = load("res://core/world_factory.gd").create("light",1)
	w.day_index = 7
	service.tick(w)
	var before: Dictionary = w.to_dict()
	service.tick(w)
	if w.to_dict()!=before: return ["weekly NPC decisions must execute once even on repeated tick"]
	w = load("res://core/world_factory.gd").create("light",1)
	w.characters.kemal.death_day = 0
	w.characters.aylin.role = "governor"
	w.characters.aylin.education = "university_graduate"
	w.characters.aylin.birth_date.year = 1924
	service.tick(w)
	if w.organizations.governorship.leader_id != "aylin" or w.characters.aylin.money != 120 or w.characters.kemal.money != 1600: return ["eligible living successor must inherit office, never personal money"]
	for d in w.districts.values():
		if d.official_owner_id != "aylin": return ["successor must own all official districts coherently"]
	return []

func test_successor_must_be_qualified_adult() -> Array[String]:
	var service = load("res://features/npc/npc_service.gd")
	for kind in ["child","untrained"]:
		var w = load("res://core/world_factory.gd").create("light",2)
		w.characters.kemal.death_day = 0
		w.characters.aylin.role = "governor"
		w.characters.aylin.birth_date.year = 1950 if kind == "child" else 1920
		w.characters.aylin.education = "university_graduate" if kind == "child" else "primary_school"
		service.tick(w)
		if w.organizations.governorship.leader_id != "": return ["unqualified or child successor must leave office vacant: " + kind]
	return []
