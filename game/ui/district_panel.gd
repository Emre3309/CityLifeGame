extends PanelContainer

const WorldState = preload("res://core/world_state.gd")

signal district_requested(district_id: String)
var _world: WorldState
var _district_ids: Array[String] = []
var buttons: Array[Button] = []

func configure(districts: Array) -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	buttons.clear()
	_district_ids.clear()
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	add_child(row)
	for district in districts:
		var button := Button.new()
		button.text = str(district.name).replace(" Mahallesi", "\nMahallesi")
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size = Vector2(0, 58)
		button.pressed.connect(func(): district_requested.emit(str(district.id)))
		row.add_child(button)
		buttons.append(button)
		_district_ids.append(str(district.id))

func refresh(world: WorldState) -> void:
	_world = world
	for index in range(buttons.size()):
		var id := _district_ids[index]
		var button := buttons[index]
		button.tooltip_text = readout(id)

func readout(district_id: String) -> String:
	if _world == null or not _world.districts.has(district_id): return "Hayata başladığında mahalle göstergeleri burada görünür."
	var district: Dictionary = _world.districts[district_id]
	var owner: Dictionary = _world.characters.get(district.official_owner_id, {})
	var official: String = owner.get("name", "Makam boş")
	if owner.get("death_day", -1) != -1: official = "Makam boş"
	var strongest := ""
	var strength := 0
	var ids: Array = district.influence.keys()
	ids.sort()
	for id in ids:
		if int(district.influence[id]) > strength:
			strongest = str(id)
			strength = int(district.influence[id])
	var influence := "Yok"
	if not strongest.is_empty(): influence = "%s: %d/100" % [_world.organizations.get(strongest, {}).get("name", strongest), strength]
	return "Güven: %d/100\nSuç baskısı: %d/100\nRefah: %d/100\n\nResmî yönetici: %s\nEn güçlü nüfuz: %s\nNüfuz, resmî yönetim yetkisi vermez." % [district.trust, district.crime_pressure, district.prosperity, official, influence]
