extends RefCounted

# Leaf service: never import the catalog, factory, simulation or command gateway.
const Calendar = preload("res://core/calendar.gd")

static func definitions() -> Array:
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string("res://content/events.json")) != OK:
		return []
	return parser.data if validate(parser.data).is_empty() else []

static func _integer(value: Variant, minimum: int, maximum: int) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and floor(value) == value and value >= minimum and value <= maximum

static func validate(rows: Variant, character_ids: Array = []) -> Array[String]:
	if not rows is Array or rows.is_empty():
		return ["Olay listesi gerekli."]
	var errors: Array[String] = []
	var indexed: Dictionary = {}
	for row in rows:
		if not row is Dictionary or not row.get("id") is String or not row.id.is_valid_identifier() or indexed.has(row.id):
			errors.append("Olay kimliği geçersiz veya tekrarlı.")
			continue
		indexed[row.id] = row
		if not row.get("title") is String or not row.get("description") is String or row.get("route") not in ["any", "light", "dark"] or not _integer(row.get("min_day"), 1, 100000) or not row.get("romantic") is bool:
			errors.append("Olay başlığı, tarihi veya yolu geçersiz.")
		if not row.get("participants") is Array or row.get("participants", []).is_empty() or not row.get("requires") is Dictionary or not row.get("choices") is Array or row.get("choices", []).is_empty():
			errors.append("Olay katılımcıları, ön koşulu ve seçenekleri gerekli.")
			continue
		var seen: Array = []
		for id in row.participants:
			if not id is String or not id.is_valid_identifier() or id == "player" or id in seen or (not character_ids.is_empty() and id not in character_ids):
				errors.append("Olay katılımcısı bilinmiyor veya tekrarlı.")
			seen.append(id)
		var choices: Array = []
		for choice in row.choices:
			if not choice is Dictionary or not choice.get("id") is String or not choice.id.is_valid_identifier() or choice.id in choices:
				errors.append("Olay seçeneği kimliği geçersiz veya tekrarlı.")
				continue
			choices.append(choice.id)
			if not choice.get("title") is String or not choice.get("reason") is String or not choice.get("effects") is Array:
				errors.append("Olay seçeneği metni veya etkileri geçersiz.")
				continue
			var chance = choice.get("risk_chance")
			if not (chance is int or chance is float) or not is_finite(float(chance)) or chance < 0 or chance > 1 or not _integer(choice.get("risk_amount"), 0, 100):
				errors.append("Soruşturma ihtimali veya etkisi geçersiz.")
			for effect in choice.effects:
				if not effect is Dictionary or effect.get("type") not in ["money", "relationship"] or effect.get("target") not in row.participants + ["player"] or not _integer(effect.get("amount"), -1000, 1000):
					errors.append("Olay etkisi izin verilen listede değil.")
				elif effect.type == "relationship" and (effect.target == "player" or not _integer(effect.amount, -100, 100)):
					errors.append("İlişki etkisi geçersiz.")
	for row in indexed.values():
		var required = row.get("requires", {})
		if not required is Dictionary or required.is_empty():
			continue
		var parent: Dictionary = indexed.get(required.get("template_id", ""), {})
		if parent.is_empty() or parent.id == row.id or not _choice(parent, required.get("choice_id", "")).has("id") or parent.get("min_day", 0) >= row.get("min_day", 0):
			errors.append("Olay ön koşulu bilinmiyor veya sırası geçersiz.")
	return errors

static func _template(rows: Array, id: String) -> Dictionary:
	for row in rows:
		if row.id == id: return row
	return {}

static func _choice(template: Dictionary, id: String) -> Dictionary:
	for choice in template.get("choices", []):
		if choice.id == id: return choice
	return {}

static func _alive(world: RefCounted, actor_id: String) -> bool:
	var actor: Dictionary = world.characters.get(actor_id, {})
	return not actor.is_empty() and actor.get("death_day", 0) == -1 and world.day_index < actor.get("lifespan_end_day", 0)

# Shared trigger/resolve policy, evaluated again when a queued event is selected.
static func _prerequisites(world: RefCounted, template: Dictionary) -> String:
	if not _alive(world, world.player_id): return "Hayatı sona eren kişi kişisel karar veremez."
	var actor: Dictionary = world.characters[world.player_id]
	if actor.imprisoned_until > world.day_index: return "Hapisteyken bu görüşmeye katılamazsın."
	if world.day_index < int(template.min_day): return "Bu olayın zamanı henüz gelmedi."
	if template.route != "any" and template.route != actor.route: return "Olay seçtiğin başlangıç yoluna ait değil."
	for id in template.participants:
		if id == world.player_id or not _alive(world, id): return "Olay katılımcısı artık hayatta değil veya bulunamıyor."
		if world.characters[id].imprisoned_until > world.day_index: return "Olay katılımcısı şu an görüşemiyor."
	if not template.requires.is_empty():
		var found := false
		for entry in world.history:
			if entry.get("type") == "event_resolved" and entry.get("character_id") == world.player_id and entry.get("template_id") == template.requires.template_id and entry.get("choice_id") == template.requires.choice_id:
				found = true
		if not found: return "Önce tanışma teklifini kabul etmelisin."
	if template.romantic:
		var date := Calendar.date_on(world.day_index)
		var player_age := Calendar.age_on(actor.birth_date, date)
		var player_months: int = player_age.years * 12 + player_age.months
		for id in template.participants:
			var peer_age := Calendar.age_on(world.characters[id].birth_date, date)
			var peer_months: int = peer_age.years * 12 + peer_age.months
			if player_age.years < 17 or player_age.years > 19 or peer_age.years < 17 or peer_age.years > 19 or absi(player_months - peer_months) > 24:
				return "Bu tanışma olayı yalnızca yaşları uygun yaşıtlar içindir."
	return ""

static func trigger(world: RefCounted) -> void:
	if world == null: return
	for template in definitions():
		if not _prerequisites(world, template).is_empty(): continue
		var id: String = world.player_id + ":" + template.id
		if id in world.resolved_event_ids: continue
		var exists := false
		for event in world.pending_events:
			if event.get("instance_id") == id: exists = true
		if exists: continue
		var participants: Array = [world.player_id]
		participants.append_array(template.participants)
		world.pending_events.append({"instance_id":id, "template_id":template.id, "actor_id":world.player_id, "participant_ids":participants, "created_day":world.day_index})

static func availability(world: RefCounted, event_id: String, choice_id: String) -> Dictionary:
	if world == null or not world.characters.has(world.player_id): return {"ok":false, "reason":"Önce bir hayata başla."}
	if event_id in world.resolved_event_ids: return {"ok":false, "reason":"Bu olay zaten sonuçlandı; yeniden ödül verilemez."}
	var matches: Array = []
	for event in world.pending_events:
		if event.get("instance_id") == event_id: matches.append(event)
	if matches.size() != 1: return {"ok":false, "reason":"Olay bulunamadı veya kimliği tekrarlı."}
	var event: Dictionary = matches[0]
	var template := _template(definitions(), event.get("template_id", ""))
	if template.is_empty(): return {"ok":false, "reason":"Olay içeriği bulunamadı."}
	var expected: Array = [world.player_id]
	expected.append_array(template.participants)
	if event.get("actor_id") != world.player_id or event_id != world.player_id + ":" + template.id or event.get("participant_ids") != expected or not _integer(event.get("created_day"), int(template.min_day), world.day_index):
		return {"ok":false, "reason":"Olay kimliği, tarihi veya katılımcıları artık geçerli değil."}
	var denial := _prerequisites(world, template)
	if not denial.is_empty(): return {"ok":false, "reason":denial}
	var choice := _choice(template, choice_id)
	if choice.is_empty(): return {"ok":false, "reason":"Bu seçenek bulunamadı."}
	# Aggregate every financial effect before touching any participant or the RNG.
	var payments: Dictionary = {}
	for effect in choice.effects:
		if effect.type == "money":
			var target: String = world.player_id if effect.target == "player" else effect.target
			payments[target] = payments.get(target, 0) + int(effect.amount)
	for target in payments:
		if world.characters[target].money + payments[target] < 0:
			return {"ok":false, "reason":"Yetersiz para: " + world.characters[target].name}
	return {"ok":true, "reason":"Seçilebilir.", "event":event, "template":template, "choice":choice}

static func resolve(world: RefCounted, event_id: String, choice_id: String) -> Dictionary:
	var checked := availability(world, event_id, choice_id)
	if not checked.ok: return {"ok":false, "reason":checked.reason}
	var choice: Dictionary = checked.choice
	var actor: Dictionary = world.characters[world.player_id]
	var deltas := {"money":0, "money_by_character":{}, "relationships":{}, "reciprocal_relationships":{}, "investigation_risk":0}
	# Commit begins here, after all prerequisites and resource checks passed.
	world.resolved_event_ids.append(event_id)
	world.pending_events.erase(checked.event)
	for effect in choice.effects:
		var target: String = world.player_id if effect.target == "player" else effect.target
		if effect.type == "money":
			world.characters[target].money += int(effect.amount)
			deltas.money_by_character[target] = deltas.money_by_character.get(target, 0) + int(effect.amount)
			if target == world.player_id: deltas.money += int(effect.amount)
		else:
			var previous := int(actor.relationships.get(target, 0))
			actor.relationships[target] = clampi(previous + int(effect.amount), 0, 100)
			deltas.relationships[target] = deltas.relationships.get(target, 0) + actor.relationships[target] - previous
			var peer: Dictionary = world.characters[target]
			previous = int(peer.relationships.get(world.player_id, 0))
			peer.relationships[world.player_id] = clampi(previous + int(effect.amount), 0, 100)
			deltas.reciprocal_relationships[target] = deltas.reciprocal_relationships.get(target, 0) + peer.relationships[world.player_id] - previous
	var detected := false
	if choice.risk_chance > 0:
		var rng := RandomNumberGenerator.new()
		rng.seed = world.rng_seed
		rng.state = world.rng_state
		detected = rng.randf() < choice.risk_chance
		world.rng_state = rng.state
		var previous := int(actor.get("investigation_risk", 0))
		if detected: actor.investigation_risk = clampi(previous + int(choice.risk_amount), 0, 100)
		deltas.investigation_risk = int(actor.get("investigation_risk", 0)) - previous
	var reason: String = choice.reason + "\nPara: %+d" % deltas.money
	for id in deltas.money_by_character:
		if id != world.player_id: reason += " · %s para: %+d" % [world.characters[id].name, deltas.money_by_character[id]]
	for id in deltas.relationships:
		reason += "\n%s ile yakınlık: %+d (şimdi %d) · karşılıklı: %+d" % [world.characters[id].name, deltas.relationships[id], actor.relationships[id], deltas.reciprocal_relationships[id]]
	if choice.risk_chance > 0:
		reason += "\nSoruşturma riski: %+d (şimdi %d). " % [deltas.investigation_risk, actor.get("investigation_risk", 0)]
		reason += "Teslimat dikkat çekti." if detected else "Bu kez teslimat dikkat çekmedi."
	var entry := {"type":"event_resolved", "day":world.day_index, "character_id":world.player_id, "instance_id":event_id, "template_id":checked.template.id, "participant_ids":checked.event.participant_ids.duplicate(), "choice_id":choice_id, "deltas":deltas.duplicate(true), "reason":reason}
	world.history.append(entry)
	return {"ok":true, "reason":reason, "deltas":deltas}
