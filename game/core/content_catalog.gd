extends RefCounted

static func load_all(path: String) -> Dictionary:
	var data: Dictionary = {}
	var errors: Array[String] = []
	for name in ["city", "characters", "organizations"]:
		var file_path := path.path_join(name + ".json")
		if not FileAccess.file_exists(file_path):
			errors.append("İçerik dosyası bulunamadı: " + file_path)
			continue
		var parser := JSON.new()
		if parser.parse(FileAccess.get_file_as_string(file_path)) != OK:
			errors.append("İçerik JSON okunamadı: " + file_path)
			continue
		data[name] = parser.data
	if errors.is_empty():
		errors.append_array(validate(data))
	return {"ok": errors.is_empty(), "data": data if errors.is_empty() else {}, "errors": errors}

static func validate(data: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	if not data.get("city") is Dictionary or not data.get("characters") is Array or not data.get("organizations") is Array:
		return ["Şehir nesnesi, kişi ve kurum listeleri gerekli."]
	var city: Dictionary = data.city
	if not city.get("districts") is Array or not city.get("buildings") is Array:
		return ["Mahalle ve bina listeleri gerekli."]
	var districts := _index(city.districts, "mahalle", errors)
	_index(city.buildings, "bina", errors)
	var characters := _index(data.characters, "kişi", errors)
	_index(data.organizations, "kurum", errors)
	for building in city.buildings:
		if building is Dictionary and not districts.has(building.get("district_id", "")):
			errors.append("Bina bilinmeyen mahalleye bağlı: " + str(building.get("id", "")))
	for actor in data.characters:
		if not actor is Dictionary:
			continue
		if not districts.has(actor.get("district_id", "")):
			errors.append("Kişi bilinmeyen mahalleye bağlı: " + str(actor.get("id", "")))
		for field in ["name", "birth_date", "death_day", "health", "money", "background", "route", "role", "education", "knowledge", "relationships", "imprisoned_until", "lifespan_end_day"]:
			if not actor.has(field):
				errors.append("Kişi alanı eksik: " + field)
		if not _valid_date(actor.get("birth_date")):
			errors.append("Kişinin doğum tarihi geçersiz.")
		if not _number_in_range(actor.get("health"), 0, 100) or not _nonnegative_integer(actor.get("money")) or not _nonnegative_integer(actor.get("lifespan_end_day")):
			errors.append("Kişinin sağlık, para veya ömür sınırı geçersiz.")
		if actor.get("lifespan_end_day", 0) == 0:
			errors.append("Kişinin ömür sınırı gelecekte olmalı.")
		if not actor.get("relationships") is Dictionary:
			errors.append("İlişkiler bir kimlik sözlüğü olmalı.")
		else:
			for person_id in actor.relationships:
				if not characters.has(person_id) or not _number_in_range(actor.relationships[person_id], 0, 100):
					errors.append("İlişki kimliği veya göstergesi geçersiz.")
	for organization in data.organizations:
		if not organization is Dictionary:
			continue
		if not districts.has(organization.get("district_id", "")):
			errors.append("Kurum bilinmeyen mahalleye bağlı.")
		if not characters.has(organization.get("leader_id", "")):
			errors.append("Kurum yöneticisi bilinmiyor.")
		if not _nonnegative_integer(organization.get("budget")):
			errors.append("Kurum bütçesi negatif olamaz.")
	return errors

static func _index(rows: Array, kind: String, errors: Array[String]) -> Dictionary:
	var result: Dictionary = {}
	for row in rows:
		if not row is Dictionary or not row.get("id") is String or row.id.is_empty():
			errors.append("Geçersiz " + kind + " kimliği.")
			continue
		if result.has(row.id):
			errors.append("Tekrarlanan " + kind + " kimliği: " + row.id)
		result[row.id] = row
	return result

static func _nonnegative_integer(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and value >= 0 and floor(value) == value

static func _number_in_range(value: Variant, minimum: int, maximum: int) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and value >= minimum and value <= maximum

static func _valid_date(value: Variant) -> bool:
	if not value is Dictionary:
		return false
	for field in ["year", "month", "day"]:
		if not _nonnegative_integer(value.get(field)):
			return false
	if value.year < 1 or value.month < 1 or value.month > 12 or value.day < 1:
		return false
	return value.day <= preload("res://core/calendar.gd").days_in_month(int(value.year), int(value.month))
