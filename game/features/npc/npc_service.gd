extends RefCounted

const Calendar = preload("res://core/calendar.gd")
const Authority = preload("res://features/careers/authority_service.gd")
const ROLES := {"governorship":"governor","police":"police_chief","harbor_network":"gang_leader"}

static func tick(world: RefCounted) -> void:
	if world == null: return
	_reconcile_offices(world)
	if world.day_index <= 0 or world.day_index % 7 != 0: return
	for entry in world.history:
		if entry.type == "npc_week" and entry.day == world.day_index: return
	world.history.append({"type":"npc_week","day":world.day_index,"reason":"Haftalık kurum kararları ve personel yenilemesi."})
	# Capacity is reusable weekly staff time, not money. No free treasury refill.
	for org in world.organizations.values(): org.capacity = int(org.get("capacity_max",3))
	_review_cases(world)
	for office in ROLES:
		var actor_id: String = world.organizations[office].leader_id
		if actor_id == world.player_id or not Authority.available_actor(world,actor_id): continue
		match office:
			"governorship": _attempt(world,actor_id,"set_security_priority",{"district_id":_priority_district(world)})
			"police":
				_attempt(world,actor_id,"assign_patrol",{"district_id":world.organizations.governorship.get("security_priority","liman")})
				for id in world.characters:
					if Authority.available_actor(world,id) and world.characters[id].get("investigation_risk",0) >= 20 and not world.organizations.police.investigations.has(id):
						_attempt(world,actor_id,"open_investigation",{"target_id":id})
						break
				# Opening and reviewing remain distinct; the chief may wait for sufficient evidence.
				for id in world.organizations.police.investigations.keys():
					var case_data: Dictionary = world.organizations.police.investigations[id]
					if case_data.evidence >= 60 and case_data.progress >= 50:
						_attempt(world,actor_id,"launch_operation",{"target_id":id})
						break
			"harbor_network": _attempt(world,actor_id,"expand_influence",{"district_id":"liman"})

static func _attempt(world: RefCounted, actor_id: String, action: String, payload: Dictionary) -> void:
	var result := Authority.apply(world,actor_id,action,payload)
	if not result.ok: world.history.append({"type":"npc_skipped","day":world.day_index,"actor_id":actor_id,"action":action,"reason":result.reason})

static func _priority_district(world: RefCounted) -> String:
	var chosen := "liman"
	for id in world.districts:
		if world.districts[id].crime_pressure > world.districts[chosen].crime_pressure: chosen = id
	return chosen

static func _review_cases(world: RefCounted) -> void:
	var org: Dictionary = world.organizations.police
	if not Authority.available_actor(world,org.leader_id): return
	for id in org.investigations.keys():
		if not Authority.available_actor(world,id): continue
		if org.budget < 25:
			world.history.append({"type":"npc_skipped","day":world.day_index,"actor_id":org.leader_id,"action":"review_investigation","reason":"Dosya incelemesi için 25 kurum bütçesi gerekli."})
			continue
		org.budget -= 25
		var data: Dictionary = org.investigations[id]
		data.progress = mini(100,data.progress + 25)
		data.evidence = mini(100,data.evidence + mini(25,int(world.characters[id].get("investigation_risk",0))))
		world.history.append({"type":"investigation_progress","day":world.day_index,"character_id":id,"reason":"Haftalık dosya incelemesi: gider 25, ilerleme %d/100, delil %d/100." % [data.progress,data.evidence]})

static func _reconcile_offices(world: RefCounted) -> void:
	for office in ROLES:
		var org: Dictionary = world.organizations[office]
		var id: String = org.leader_id
		# Imprisonment suspends orders but does not silently replace a living elected/appointed holder.
		var valid: bool = _qualified(world,id,ROLES[office]) and world.characters[id].death_day == -1 and world.day_index < world.characters[id].lifespan_end_day
		if valid: continue
		var successor := ""
		for candidate in world.characters:
			if candidate != id and _qualified(world,candidate,ROLES[office]) and Authority.available_actor(world,candidate):
				successor = candidate
				break
		if id != successor:
			org.leader_id = successor
			world.history.append({"type":"office_succession","day":world.day_index,"organization_id":office,"leader_id":successor,"reason":"Makam boş." if successor.is_empty() else "Yaşayan uygun görevli atandı: " + world.characters[successor].name})
	for district in world.districts.values(): district.official_owner_id = world.organizations.governorship.leader_id

static func _qualified(world: RefCounted, id: String, role: String) -> bool:
	if not world.characters.has(id): return false
	var actor: Dictionary = world.characters[id]
	if actor.role != role or Calendar.age_on(actor.birth_date,Calendar.date_on(world.day_index)).years < 18: return false
	if role == "governor": return actor.education == "university_graduate"
	if role == "police_chief": return actor.education == "police_training"
	return true
