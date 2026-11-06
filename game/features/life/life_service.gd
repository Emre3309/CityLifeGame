extends RefCounted

const Calendar = preload("res://core/calendar.gd")
const Factory = preload("res://core/world_factory.gd")

# Daily ageing has a fixed deadline; event deaths call end_life directly with a cause.
static func tick(world: RefCounted) -> void:
	if world == null: return
	for actor in world.characters.values():
		if actor.death_day != -1: continue
		if world.day_index >= actor.lifespan_end_day:
			end_life(world, actor.id, "lifespan")
		elif actor.imprisoned_until >= 0 and actor.imprisoned_until <= world.day_index:
			actor.imprisoned_until = -1
			world.history.append({"type":"release","day":world.day_index,"character_id":actor.id,"reason":"Hapis süresi tamamlandı; kişi serbest bırakıldı."})

static func end_life(world: RefCounted, character_id: String, cause: String) -> void:
	if world == null or not world.characters.has(character_id): return
	var actor: Dictionary = world.characters[character_id]
	if actor.death_day != -1: return
	actor.death_day = world.day_index
	world.history.append({"type":"death","day":world.day_index,"character_id":character_id,"cause":cause})
	if character_id == world.player_id:
		if not world.active_focus.is_empty():
			world.history.append({"type":"focus_cancelled","day":world.day_index,"character_id":character_id,"focus_id":world.active_focus.id,"reason":"Hayat sona erdi; odak ödülü uygulanmadı."})
		world.active_focus = {}
		world.pending_events.clear()

static func start_next_life(world: RefCounted, route: String) -> Dictionary:
	if world == null or not world.characters.has(world.player_id): return {"ok":false,"reason":"Önce bir hayata başla."}
	if world.characters[world.player_id].death_day == -1: return {"ok":false,"reason":"Yeni hayat yalnızca önceki hayat sona erdiğinde başlayabilir."}
	if route not in ["light","dark"]: return {"ok":false,"reason":"Başlangıç yolu geçersiz."}
	var previous: String = world.player_id
	var number := 1
	while world.characters.has("player_%d" % number): number += 1
	var id := "player_%d" % number
	var date := Calendar.date_on(world.day_index)
	var birth_month: int = date.year * 12 + date.month - 1 - 210
	var year: int = birth_month / 12
	var month: int = birth_month % 12 + 1
	var birth := {"year":year,"month":month,"day":mini(date.day,Calendar.days_in_month(year,month))}
	world.characters[id] = Factory.create_player(id,route,birth,world.day_index)
	world.player_id = id
	world.active_focus = {}
	world.completed_focuses.clear()
	world.pending_events.clear()
	world.resolved_event_ids.clear()
	world.history.append({"type":"life_started","day":world.day_index,"character_id":id,"previous_character_id":previous,"route":route})
	return {"ok":true,"reason":"Aynı şehirde yeni bir hayat başladı. Önceki hayatın kayıtları ve şehirdeki etkileri korundu."}

static func prison_status(world: RefCounted) -> String:
	var actor: Dictionary = world.characters[world.player_id]
	if actor.imprisoned_until <= world.day_index: return ""
	var reason := "Hapis cezası"
	for entry in world.history:
		if entry.type == "conviction" and entry.character_id == world.player_id: reason = entry.reason
	return "Hapiste · Serbest kalma: %s · %s" % [Calendar.format_date(Calendar.date_on(actor.imprisoned_until)),reason]

static func summary(world: RefCounted) -> String:
	var actor: Dictionary = world.characters[world.player_id]
	var cause := ""
	var career: Array[String] = ["Son görev: " + {"citizen":"Vatandaş","governor":"Vali","police_chief":"Emniyet müdürü","gang_leader":"Ağ lideri","gang_member":"Ağ üyesi"}.get(actor.role,actor.role)]
	var changes: Array[String] = []
	for entry in world.history:
		if entry.get("character_id",entry.get("actor_id","")) != actor.id: continue
		if entry.type == "death": cause = "Ömür tamamlandı" if entry.cause == "lifespan" else entry.cause
		if entry.type == "focus_completed": career.append("Tamamlanan odak: " + entry.focus_id)
		if entry.type in ["authority_action","conviction","event_resolved"]: changes.append(entry.reason)
	var relations: Array[String] = []
	for id in actor.relationships: relations.append("%s: %d/100" % [world.characters[id].name,actor.relationships[id]])
	var lines: Array[String] = ["%s · Hayatın sona erdi" % actor.name,"Neden: " + cause,"Kariyer\n" + "\n".join(career),"İlişkiler\n" + ("\n".join(relations) if not relations.is_empty() else "Kayıtlı yakın ilişki yok."),"Kalıcı dünya kayıtları\n" + ("\n".join(changes) if not changes.is_empty() else "Önceki kişi ve geçmişi şehir kayıtlarında korunur.")]
	for district in world.districts.values(): lines.append("Mahalle %s · Refah %d · Güven %d · Suç baskısı %d · Ağ etkisi %d" % [district.id,district.prosperity,district.trust,district.crime_pressure,district.influence.get("harbor_network",0)])
	return "\n\n".join(lines)
