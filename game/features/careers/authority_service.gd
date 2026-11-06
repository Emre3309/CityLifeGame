extends RefCounted

const ACTIONS := {"governor":["set_security_priority","allocate_budget"], "police_chief":["open_investigation","assign_patrol","launch_operation"], "gang_leader":["assign_member","expand_influence"]}
const PAYLOAD_FIELDS := {"set_security_priority":["district_id"], "allocate_budget":["organization_id","amount"], "assign_patrol":["district_id"], "open_investigation":["target_id"], "launch_operation":["target_id"], "assign_member":["target_id","district_id"], "expand_influence":["district_id"]}
const OFFICES := {"governor":"governorship", "police_chief":"police", "gang_leader":"harbor_network"}

static func available_actor(world: RefCounted, actor_id: String) -> bool:
	if world == null or not world.characters.has(actor_id): return false
	var actor: Dictionary = world.characters[actor_id]
	return actor.death_day == -1 and world.day_index < actor.lifespan_end_day and actor.imprisoned_until <= world.day_index

static func allowed(world: RefCounted, actor_id: String, action: String) -> bool:
	return available_actor(world,actor_id) and action in ACTIONS.get(world.characters[actor_id].role, [])

# Read-only preflight; used by both commands and panel. No RNG is consumed on denial.
static func availability(world: RefCounted, actor_id: String, action: String, payload: Dictionary) -> Dictionary:
	if not allowed(world,actor_id,action): return _deny("Bu makamın yetkisi yok veya kişi ölü/hapiste.")
	var fields: Array = PAYLOAD_FIELDS[action]
	if payload.size() != fields.size(): return _deny("Emir alanları eksik veya bilinmeyen alan içeriyor.")
	for field in payload:
		if field not in fields: return _deny("Bilinmeyen emir alanı.")
	var office: String = OFFICES[world.characters[actor_id].role]
	if not world.organizations.has(office) or world.organizations[office].leader_id != actor_id: return _deny("Bu kurumun görevdeki yöneticisi değilsin.")
	var org: Dictionary = world.organizations[office]
	var district = payload.get("district_id", "")
	var target = payload.get("target_id", "")
	if action in ["set_security_priority","assign_patrol","assign_member","expand_influence"]:
		if not district is String or not world.districts.has(district): return _deny("Geçerli bir mahalle seç.")
	if action in ["open_investigation","launch_operation","assign_member"]:
		if not target is String or not available_actor(world,target) or target == actor_id: return _deny("Hedef kişi geçersiz, ölü, hapiste veya kendin.")
	var cost := 0
	var capacity := 0
	match action:
		"set_security_priority": cost = 20
		"allocate_budget":
			if payload.get("organization_id") != "police" or not world.organizations.has("police"): return _deny("Bütçe yalnızca emniyete aktarılabilir.")
			if not payload.get("amount") is int or payload.amount <= 0: return _deny("Aktarım pozitif tam sayı olmalı.")
			cost = payload.amount
		"assign_patrol":
			cost = 50
			capacity = 1
		"open_investigation":
			if world.characters[target].get("investigation_risk",0) < 20: return _deny("Soruşturma için en az 20/100 risk kaydı gerekli.")
			if org.get("investigations",{}).has(target): return _deny("Bu kişi için açık dosya zaten var.")
			cost = 50
			capacity = 1
		"launch_operation":
			var case_data: Dictionary = org.get("investigations",{}).get(target,{})
			if case_data.get("evidence",0) < 60 or case_data.get("progress",0) < 50: return _deny("Operasyonu ertele: en az 60 delil ve 50 ilerleme gerekli.")
			cost = 100
			capacity = 2
		"assign_member":
			if target not in org.get("member_ids",[]): return _deny("Yalnızca bu ağın yaşayan üyesi atanabilir.")
			cost = 20
			capacity = 1
		"expand_influence":
			cost = 50
			capacity = 1
	if org.budget < cost: return _deny("Kurum bütçesi yetersiz; para kişisel servetten alınmaz.")
	if org.get("capacity",0) < capacity: return _deny("Personel kapasitesi yetersiz; yeni haftayı bekle.")
	return {"ok":true,"reason":"Uygulanabilir.","office":office,"cost":cost,"capacity":capacity}

static func apply(world: RefCounted, actor_id: String, action: String, payload: Dictionary) -> Dictionary:
	var checked := availability(world,actor_id,action,payload)
	if not checked.ok: return checked
	var org: Dictionary = world.organizations[checked.office]
	org.budget -= checked.cost
	org.capacity = org.get("capacity",0) - checked.capacity
	var target: String = payload.get("target_id", "")
	var district: String = payload.get("district_id", "")
	var reason := ""
	match action:
		"set_security_priority":
			org.security_priority = district
			reason = "Güvenlik önceliği: " + district + ". Devriye kararı emniyete aittir."
		"allocate_budget":
			world.organizations.police.budget += checked.cost
			reason = "Valilik hazinesinden emniyete %d aktarıldı." % checked.cost
		"assign_patrol":
			var d: Dictionary = world.districts[district]
			d.crime_pressure = maxi(0,d.crime_pressure - 4)
			d.trust = mini(100,d.trust + 2)
			reason = district + " devriyesi: suç baskısı −4, güven +2 (0–100 sınırında)."
		"open_investigation":
			org.investigations[target] = {"target_id":target,"progress":0,"evidence":int(world.characters[target].investigation_risk),"opened_day":world.day_index}
			reason = "Dosya açıldı: " + world.characters[target].name + ". Risk başlangıç delilidir; haftalık inceleme gerekir."
		"launch_operation":
			# Prototype conviction rule is deterministic and transparent, never a death roll.
			world.characters[target].imprisoned_until = world.day_index + 30
			world.characters[target].investigation_risk = 0
			org.investigations.erase(target)
			world.history.append({"type":"conviction","day":world.day_index,"character_id":target,"imprisoned_until":world.day_index + 30,"reason":"En az 60 delil, 50 ilerleme ve 2 personelle prototip mahkûmiyet kararı; 30 gün hapis."})
			reason = world.characters[target].name + ": delil ve kapasite yeterli; mahkûmiyet, 30 gün hapis."
		"assign_member":
			org.assignments[target] = district
			reason = world.characters[target].name + " üyesi " + district + " bölgesine atandı."
		"expand_influence":
			var d: Dictionary = world.districts[district]
			var bonus := 0
			for id in org.get("assignments",{}):
				if org.assignments[id] == district and available_actor(world,id): bonus += 1
			d.influence.harbor_network = mini(100,int(d.influence.get("harbor_network",0)) + 3 + mini(bonus,2))
			d.crime_pressure = mini(100,d.crime_pressure + 2)
			reason = district + ": ağ etkisi arttı; suç baskısı +2."
	reason += "\nKurum gideri: %d · Kalan bütçe: %d · Kalan personel: %d" % [checked.cost,org.budget,org.capacity]
	world.history.append({"type":"authority_action","day":world.day_index,"actor_id":actor_id,"action":action,"payload":payload.duplicate(true),"reason":reason})
	return {"ok":true,"reason":reason}

static func _deny(reason: String) -> Dictionary:
	return {"ok":false,"reason":reason}
