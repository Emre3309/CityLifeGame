extends RefCounted

const State = preload("res://core/world_state.gd")
const Calendar = preload("res://core/calendar.gd")
const Focus = preload("res://features/focus/focus_service.gd")
const Events = preload("res://features/events/event_service.gd")
const Authority = preload("res://features/careers/authority_service.gd")
const TOP := ["schema_version","day_index","player_id","characters","districts","organizations","active_focus","completed_focuses","pending_events","resolved_event_ids","history","rng_seed","rng_state"]
const MAX_EXACT := 9007199254740991
var _io: RefCounted

# The optional IO boundary keeps filesystem failures testable without changing world logic.
func _init(io: RefCounted = null) -> void:
	_io = io

func save_world(world: State, path: String) -> Dictionary:
	if world == null: return _fail("Kaydedilecek bir hayat yok.")
	var data := world.to_dict()
	data.rng_seed = str(world.rng_seed)
	data.rng_state = str(world.rng_state)
	for field in ["characters","districts","organizations"]: data[field] = data[field].values()
	var checked := _decode(data)
	if not checked.ok: return checked
	var absolute := ProjectSettings.globalize_path(path)
	if DirAccess.make_dir_recursive_absolute(absolute.get_base_dir()) != OK: return _fail("Kayıt klasörü oluşturulamadı.")
	var temporary := absolute + ".tmp"
	var backup := absolute + ".bak"
	var error := _write_file(temporary, JSON.stringify(data, "\t"))
	if error != OK:
		DirAccess.remove_absolute(temporary)
		return _fail("Kayıt yazılamadı; önceki kayıt korundu.")
	# Never move the live slot until the complete temporary file has been checked.
	var verified := load_world(temporary)
	if not verified.ok:
		DirAccess.remove_absolute(temporary)
		return _fail("Geçici kayıt doğrulanamadı; önceki kayıt korundu.")
	var had_previous := FileAccess.file_exists(absolute)
	if had_previous:
		if FileAccess.file_exists(backup) and DirAccess.remove_absolute(backup) != OK:
			DirAccess.remove_absolute(temporary)
			return _fail("Eski yedek değiştirilemedi; önceki kayıt korundu.")
		if _rename_file(absolute, backup) != OK:
			DirAccess.remove_absolute(temporary)
			return _fail("Kayıt yedeklenemedi; önceki kayıt korundu.")
	if _rename_file(temporary, absolute) != OK:
		# Roll back through the real filesystem even if an injected IO adapter failed.
		if had_previous and DirAccess.rename_absolute(backup, absolute) != OK:
			return _fail("Kayıt yerleştirilemedi. Önceki kayıt yedekte: " + backup)
		DirAccess.remove_absolute(temporary)
		return _fail("Kayıt yerleştirilemedi; önceki kayıt korundu.")
	return {"ok":true,"reason":"Hayat kaydedildi.","world":null}

func load_world(path: String) -> Dictionary:
	if not FileAccess.file_exists(path): return _fail("Kayıt dosyası bulunamadı.")
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null: return _fail("Kayıt dosyası okunamadı.")
	var text := file.get_as_text()
	file.close()
	var parser := JSON.new()
	if parser.parse(text) != OK: return _fail("Kayıt JSON verisi bozuk.")
	return _decode(parser.data)

func _write_file(path: String, text: String) -> Error:
	if _io != null: return _io.write_file(path, text)
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null: return FileAccess.get_open_error()
	file.store_string(text)
	file.flush()
	var error := file.get_error()
	file.close()
	return error

func _rename_file(from: String, to: String) -> Error:
	return _io.rename_file(from, to) if _io != null else DirAccess.rename_absolute(from, to)

static func _fail(reason: String) -> Dictionary:
	return {"ok":false,"reason":reason,"world":null}

static func _fields(value: Variant, required: Array, optional: Array = []) -> bool:
	if not value is Dictionary: return false
	for key in required:
		if not value.has(key): return false
	for key in value:
		if key not in required and key not in optional: return false
	return true

static func _number(value: Variant, minimum: int = 0, maximum: int = MAX_EXACT) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and value >= minimum and value <= maximum and floor(value) == value

static func _id(value: Variant) -> bool:
	return value is String and value.is_valid_identifier()

static func _signed64(value: Variant) -> bool:
	if not value is String or value.is_empty(): return false
	var digits: String = value.trim_prefix("-")
	if digits.is_empty() or (digits.length() > 1 and digits.begins_with("0")) or value == "-0": return false
	for index in digits.length():
		if digits.unicode_at(index) < 48 or digits.unicode_at(index) > 57: return false
	var bound := "9223372036854775808" if value.begins_with("-") else "9223372036854775807"
	return digits.length() < 19 or (digits.length() == 19 and digits <= bound)

static func _ref(value: Variant, table: Dictionary, empty: bool = false) -> bool:
	return value is String and ((empty and value.is_empty()) or table.has(value))

static func _list(value: Variant, table: Dictionary = {}, references: bool = false) -> bool:
	if not value is Array: return false
	var seen := {}
	for item in value:
		if not item is String or item.is_empty() or seen.has(item) or (references and not table.has(item)): return false
		seen[item] = true
	return true

static func _scores(value: Variant, table: Dictionary = {}, references: bool = false, minimum: int = 0, maximum: int = 100) -> bool:
	if not value is Dictionary: return false
	for key in value:
		if not _id(key) or (references and not table.has(key)) or not _number(value[key],minimum,maximum): return false
	return true

static func _normalize(value: Variant) -> Variant:
	if value is float: return int(value)
	if value is Dictionary:
		var result := {}
		for key in value: result[key] = _normalize(value[key])
		return result
	if value is Array:
		var result := []
		for item in value: result.append(_normalize(item))
		return result
	return value

static func _decode(raw: Variant) -> Dictionary:
	if not raw is Dictionary or not _number(raw.get("schema_version"),1,1): return _fail("Desteklenmeyen kayıt sürümü; yalnızca sürüm 1 yüklenebilir.")
	if not _fields(raw,TOP): return _fail("Kayıt alanları eksik veya bilinmeyen şemada.")
	if not _number(raw.day_index) or not _signed64(raw.rng_seed) or not _signed64(raw.rng_state): return _fail("Kayıt tarihi veya RNG değeri geçersiz.")
	var data: Dictionary = raw.duplicate(true)
	for field in ["characters","districts","organizations"]:
		if not raw[field] is Array or raw[field].is_empty(): return _fail("Kayıtta kimlikli liste gerekli: " + field)
		data[field] = {}
		for row in raw[field]:
			if not row is Dictionary or not _id(row.get("id")) or data[field].has(row.id): return _fail("Geçersiz veya tekrarlı kimlik: " + field)
			data[field][row.id] = row
	var chars: Dictionary = data.characters
	var districts: Dictionary = data.districts
	var orgs: Dictionary = data.organizations
	if not _ref(data.player_id,chars) or districts.keys().size() != 3 or not districts.has_all(["cinar","carsi","liman"]) or orgs.keys().size() != 3 or not orgs.has_all(["governorship","police","harbor_network"]): return _fail("Oyuncu, mahalle veya kurum kimlikleri geçersiz.")
	for actor in chars.values():
		if not _valid_character(actor,chars,districts,data.day_index): return _fail("Karakter verisi veya kişi referansı geçersiz.")
	for district in districts.values():
		if not _fields(district,["id","population","prosperity","trust","crime_pressure","official_owner_id","influence"]) or not _number(district.population) or not _ref(district.official_owner_id,chars,true) or not _scores(district.influence,orgs,true): return _fail("Mahalle verisi veya referansı geçersiz.")
		for field in ["prosperity","trust","crime_pressure"]:
			if not _number(district[field],0,100): return _fail("Mahalle göstergesi 0–100 aralığında olmalı.")
	for org in orgs.values():
		if not _valid_organization(org,chars,districts,data.day_index): return _fail("Kurum verisi veya iç referansı geçersiz.")
	var focuses := {}
	for row in Focus.definitions(): focuses[row.id] = row
	var events := {}
	for row in Events.definitions(): events[row.id] = row
	if not _list(data.completed_focuses,focuses,true) or not _list(data.resolved_event_ids) or not data.pending_events is Array or not data.history is Array: return _fail("Odak, olay veya tarihçe listesi geçersiz.")
	if not data.active_focus is Dictionary: return _fail("Etkin odak geçersiz.")
	if not data.active_focus.is_empty():
		var active: Dictionary = data.active_focus
		if not _fields(active,["id","actor_id","start_day","end_day"]) or not _ref(active.id,focuses) or not _ref(active.actor_id,chars) or active.id in data.completed_focuses or not _number(active.start_day,0,data.day_index) or not _number(active.end_day,active.start_day + 1) or focuses[active.id].future or active.end_day - active.start_day != focuses[active.id].duration_days: return _fail("Etkin odak kimliği veya tarihi geçersiz.")
	var seen := {}
	for event in data.pending_events:
		if not _fields(event,["instance_id","template_id","actor_id","participant_ids","created_day"]) or not _ref(event.template_id,events) or not _ref(event.actor_id,chars) or not event.instance_id is String: return _fail("Bekleyen olay geçersiz.")
		if event.instance_id != event.actor_id + ":" + event.template_id or seen.has(event.instance_id) or event.instance_id in data.resolved_event_ids or not _list(event.participant_ids,chars,true) or not _number(event.created_day,events[event.template_id].min_day,data.day_index): return _fail("Olay kimliği, tarihi veya katılımcısı geçersiz.")
		var expected: Array = [event.actor_id]
		expected.append_array(events[event.template_id].participants)
		if event.participant_ids != expected: return _fail("Olay katılımcıları şablonla uyuşmuyor.")
		seen[event.instance_id] = true
	for id in data.resolved_event_ids:
		var parts: PackedStringArray = id.split(":")
		if parts.size() != 2 or not chars.has(parts[0]) or not events.has(parts[1]): return _fail("Sonuçlanan olay referansı geçersiz.")
	for entry in data.history:
		if not _valid_history(entry,chars,districts,orgs,focuses,events,data.day_index): return _fail("Tarihçe verisi veya referansı geçersiz.")
	data = _normalize(data)
	data.rng_seed = int(raw.rng_seed)
	data.rng_state = int(raw.rng_state)
	return {"ok":true,"reason":"Hayat yüklendi; zaman duraklatıldı.","world":State.from_dict(data)}

static func _valid_character(actor: Dictionary, chars: Dictionary, districts: Dictionary, day: int) -> bool:
	if not _fields(actor,["id","name","district_id","birth_date","death_day","health","money","background","route","role","education","knowledge","relationships","imprisoned_until","lifespan_end_day","investigation_risk"],["unlocked_actions"]): return false
	for field in ["name","background","education"]:
		if not actor[field] is String: return false
	if not _ref(actor.district_id,districts) or actor.route not in ["light","dark"] or actor.role not in ["citizen","governor","police_chief","gang_leader","gang_member"]: return false
	if not _fields(actor.birth_date,["year","month","day"]): return false
	var birth: Dictionary = actor.birth_date
	if not _number(birth.year,1,9999) or not _number(birth.month,1,12) or not _number(birth.day,1,Calendar.days_in_month(int(birth.year),int(birth.month))): return false
	if not _number(actor.death_day,-1,day) or not _number(actor.imprisoned_until,-1) or not _number(actor.lifespan_end_day,1) or not _number(actor.money) or not _number(actor.health,0,100) or not _number(actor.investigation_risk,0,100): return false
	return _scores(actor.knowledge) and _scores(actor.relationships,chars,true) and (not actor.has("unlocked_actions") or _list(actor.unlocked_actions))

static func _valid_organization(org: Dictionary, chars: Dictionary, districts: Dictionary, day: int) -> bool:
	var extra: Array = ["security_priority"] if org.id == "governorship" else (["investigations"] if org.id == "police" else ["member_ids","assignments"])
	if not _fields(org,["id","name","district_id","leader_id","budget","capacity","capacity_max"] + extra) or not org.name is String or not _ref(org.district_id,districts) or not _ref(org.leader_id,chars,true) or not _number(org.budget) or not _number(org.capacity_max) or not _number(org.capacity,0,org.capacity_max): return false
	if org.id == "governorship": return _ref(org.security_priority,districts)
	if org.id == "police":
		if not org.investigations is Dictionary: return false
		for target in org.investigations:
			var case_data = org.investigations[target]
			if not chars.has(target) or not _fields(case_data,["target_id","progress","evidence","opened_day"]): return false
			if case_data.target_id != target or not _number(case_data.progress,0,100) or not _number(case_data.evidence,0,100) or not _number(case_data.opened_day,0,day): return false
		return true
	if not _list(org.member_ids,chars,true) or not org.assignments is Dictionary: return false
	for member in org.assignments:
		if member not in org.member_ids or not _ref(org.assignments[member],districts): return false
	return true

static func _valid_history(entry: Variant, chars: Dictionary, districts: Dictionary, orgs: Dictionary, focuses: Dictionary, events: Dictionary, day: int) -> bool:
	var layouts := {
		"focus_started":["character_id","focus_id"],"focus_completed":["character_id","focus_id"],"focus_cancelled":["character_id","focus_id","reason"],
		"event_resolved":["character_id","instance_id","template_id","participant_ids","choice_id","deltas","reason"],
		"development_scenario":["reason"],"npc_week":["reason"],"npc_skipped":["actor_id","action","reason"],
		"investigation_progress":["character_id","reason"],"office_succession":["organization_id","leader_id","reason"],
		"conviction":["character_id","imprisoned_until","reason"],"authority_action":["actor_id","action","payload","reason"],"death":["character_id","cause"]}
	if not entry is Dictionary or not entry.get("type") is String or not layouts.has(entry.type) or not _fields(entry,["type","day"] + layouts[entry.type]) or not _number(entry.day,0,day): return false
	for key in ["reason","cause","action","choice_id"]:
		if entry.has(key) and not entry[key] is String: return false
	for key in ["actor_id","character_id","leader_id"]:
		if entry.has(key) and not _ref(entry[key],chars,key == "leader_id"): return false
	if entry.has("organization_id") and not _ref(entry.organization_id,orgs): return false
	if entry.has("focus_id") and not _ref(entry.focus_id,focuses): return false
	if entry.has("imprisoned_until") and not _number(entry.imprisoned_until,entry.day): return false
	if entry.has("payload"):
		if not Authority.PAYLOAD_FIELDS.has(entry.action) or not _fields(entry.payload,Authority.PAYLOAD_FIELDS[entry.action]): return false
		for key in entry.payload:
			match key:
				"district_id":
					if not _ref(entry.payload[key],districts): return false
				"target_id":
					if not _ref(entry.payload[key],chars): return false
				"organization_id":
					if not _ref(entry.payload[key],orgs): return false
				"amount":
					if not _number(entry.payload[key],1): return false
	if entry.type == "event_resolved":
		if not _ref(entry.template_id,events) or not entry.instance_id is String or entry.instance_id != entry.character_id + ":" + entry.template_id or not _list(entry.participant_ids,chars,true): return false
		var choices: Array = events[entry.template_id].choices.filter(func(choice): return choice.id == entry.choice_id)
		if choices.size() != 1 or not _fields(entry.deltas,["money","money_by_character","relationships","reciprocal_relationships","investigation_risk"]): return false
		if not _number(entry.deltas.money,-MAX_EXACT) or not _number(entry.deltas.investigation_risk,-100,100): return false
		for key in ["money_by_character","relationships","reciprocal_relationships"]:
			if not _scores(entry.deltas[key],chars,true,-MAX_EXACT if key == "money_by_character" else -100,MAX_EXACT if key == "money_by_character" else 100): return false
	return true
