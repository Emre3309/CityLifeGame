extends PanelContainer

signal district_requested(district_id: String)
var buttons: Array[Button] = []

func configure(districts: Array) -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	buttons.clear()
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
