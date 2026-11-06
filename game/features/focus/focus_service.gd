extends RefCounted

# A leaf service: no factory/catalog imports, keeping the core dependency graph acyclic.
static func definitions() -> Array:
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string("res://content/focuses.json")) != OK:
		return []
	return parser.data if validate(parser.data).is_empty() else []

static func validate(rows: Variant) -> Array[String]:
	var errors: Array[String] = []
	if not rows is Array or rows.is_empty():
		return ["Odak listesi gerekli."]
	var indexed: Dictionary = {}
	for row in rows:
		if not row is Dictionary or not row.get("id") is String or not row.id.is_valid_identifier() or indexed.has(row.id):
			errors.append("Odak kimliği geçersiz veya tekrarlı.")
			continue
		indexed[row.id] = row
		if not row.get("name") is String or not row.get("description") is String or row.get("route", "") not in ["light", "dark"] or not row.get("future") is bool:
			errors.append("Odak adı, açıklaması veya yolu geçersiz.")
		if not _whole(row.get("cost")) or not _whole(row.get("duration_days")) or (not row.get("future", false) and row.get("duration_days", 0) <= 0):
			errors.append("Odak süresi ve bedeli geçersiz.")
		if not row.get("prerequisites") is Array or not row.get("effects") is Array:
			errors.append("Odak ön koşulları ve etkileri liste olmalı.")
			continue
		for effect in row.effects:
			if not _valid_effect(effect):
				errors.append("Odak etkisi izin verilen listede değil veya geçersiz.")
		if row.get("future", false) and not row.effects.is_empty():
			errors.append("Gelecek odaklar ödül veremez.")
	for row in indexed.values():
		if not row.get("prerequisites") is Array:
			continue
		var seen: Array = []
		for required in row.prerequisites:
			if not required is String or not indexed.has(required) or required in seen:
				errors.append("Odak ön koşulu bilinmiyor veya tekrarlı.")
			elif indexed[required].get("route") != row.get("route"):
				errors.append("Odak ön koşulu aynı yolda olmalı.")
			seen.append(required)
	if errors.is_empty():
		for id in indexed:
			if _has_cycle(id, indexed, []):
				errors.append("Odak bağlantılarında döngü var.")
				break
	return errors

static func _whole(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and value >= 0 and floor(value) == value

static func _valid_effect(effect: Variant) -> bool:
	if not effect is Dictionary:
		return false
	match effect.get("type", ""):
		"set_education": return effect.get("value", "") in ["university_enrolled"]
		"add_knowledge": return effect.get("key") is String and effect.key.is_valid_identifier() and _whole(effect.get("amount")) and effect.amount <= 100
		"unlock_action": return effect.get("action") is String and effect.action.is_valid_identifier()
	return false

static func _has_cycle(id: String, indexed: Dictionary, path: Array) -> bool:
	if id in path:
		return true
	var next := path.duplicate()
	next.append(id)
	for required in indexed[id].prerequisites:
		if _has_cycle(required, indexed, next):
			return true
	return false

static func _find(rows: Array, id: String) -> Dictionary:
	for row in rows:
		if row.id == id:
			return row
	return {}

# This read-only result is the sole eligibility policy used by the panel and command.
static func availability(world: RefCounted, focus_id: String) -> Dictionary:
	return _availability(world, focus_id, definitions())

static func _availability(world: RefCounted, focus_id: String, rows: Array) -> Dictionary:
	if world == null or not world.characters.has(world.player_id):
		return {"ok":false, "reason":"Önce bir hayata başla."}
	if rows.is_empty():
		return {"ok":false, "reason":"Odak içeriği okunamadı."}
	var focus := _find(rows, focus_id)
	if focus.is_empty():
		return {"ok":false, "reason":"Bu odak bulunamadı."}
	var actor: Dictionary = world.characters[world.player_id]
	if actor.death_day != -1 or world.day_index >= actor.lifespan_end_day:
		return {"ok":false, "reason":"Hayatı sona eren kişi odak başlatamaz."}
	if actor.imprisoned_until > world.day_index:
		return {"ok":false, "reason":"Hapisteyken odak başlatılamaz."}
	if focus.future:
		return {"ok":false, "reason":"Gelecek içerik · Bu prototipte kilitli."}
	if focus_id in world.completed_focuses:
		return {"ok":false, "reason":"Tamamlandı · Tekrar başlatılamaz."}
	if not world.active_focus.is_empty():
		return {"ok":false, "reason":"Önce etkin odağını tamamla."}
	if actor.route != focus.route:
		return {"ok":false, "reason":"Bu odak seçtiğin başlangıç yoluna ait değil."}
	for required in focus.prerequisites:
		if required not in world.completed_focuses:
			return {"ok":false, "reason":"Ön koşul eksik: " + _find(rows, required).name}
	if actor.money < focus.cost:
		return {"ok":false, "reason":"Yetersiz para · %d gerekli." % int(focus.cost)}
	return {"ok":true, "reason":"Başlatılabilir."}

static func start(world: RefCounted, focus_id: String) -> Dictionary:
	var rows := definitions()
	var result := _availability(world, focus_id, rows)
	if not result.ok:
		return result
	var focus := _find(rows, focus_id)
	world.characters[world.player_id].money -= int(focus.cost)
	world.active_focus = {"id":focus_id, "actor_id":world.player_id, "start_day":world.day_index, "end_day":world.day_index + int(focus.duration_days)}
	world.history.append({"type":"focus_started", "day":world.day_index, "character_id":world.player_id, "focus_id":focus_id})
	return {"ok":true, "reason":focus.name + " başladı."}

static func tick(world: RefCounted) -> void:
	if world == null or world.active_focus.is_empty():
		return
	var active: Dictionary = world.active_focus
	var actor_id: String = active.get("actor_id", "")
	var actor: Dictionary = world.characters.get(actor_id, {})
	# Stop a disrupted focus rather than transfer its reward to a successor.
	if actor_id != world.player_id or actor.is_empty() or actor.death_day != -1 or world.day_index >= actor.lifespan_end_day or actor.imprisoned_until > world.day_index:
		world.history.append({"type":"focus_cancelled", "day":world.day_index, "character_id":actor_id, "focus_id":active.get("id", ""), "reason":"Kişi odağa devam edemiyor."})
		world.active_focus = {}
		return
	if world.day_index < active.get("end_day", 0):
		return
	var focus := _find(definitions(), active.get("id", ""))
	if focus.is_empty() or focus.future:
		return
	# Mark before applying, and never reward an already completed focus again.
	world.active_focus = {}
	if focus.id in world.completed_focuses:
		return
	world.completed_focuses.append(focus.id)
	for effect in focus.effects:
		match effect.type:
			"set_education": actor.education = effect.value
			"add_knowledge": actor.knowledge[effect.key] = clampi(int(actor.knowledge.get(effect.key, 0)) + int(effect.amount), 0, 100)
			"unlock_action":
				if not actor.has("unlocked_actions"):
					actor.unlocked_actions = []
				if effect.action not in actor.unlocked_actions:
					actor.unlocked_actions.append(effect.action)
	world.history.append({"type":"focus_completed", "day":world.day_index, "character_id":actor_id, "focus_id":focus.id})
