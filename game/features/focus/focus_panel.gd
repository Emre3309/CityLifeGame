extends Control

signal start_requested(focus_id: String)

const Focus = preload("res://features/focus/focus_service.gd")
const DisplayNames = preload("res://core/display_names.gd")
var summary: Label
var feedback: Label
var start_buttons: Dictionary = {}
var lock_labels: Dictionary = {}
var branches: GridContainer
var _world: RefCounted
var _rows: Array = []

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var shade := ColorRect.new()
	shade.color = Color(0.08, 0.17, 0.14, 0.70)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 30
	panel.offset_right = -30
	panel.offset_top = 100
	panel.offset_bottom = -28
	add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	panel.add_child(column)
	var heading := HBoxContainer.new()
	column.add_child(heading)
	var title := _label("HAYATINA YÖN VER · ODAK AĞACI", 22)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(title)
	var close_button := Button.new()
	close_button.text = "Kapat"
	close_button.pressed.connect(hide)
	heading.add_child(close_button)
	summary = _label("", 15)
	column.add_child(summary)
	feedback = _label("Tek seferde bir odak. Süre takvim günüdür; bedel başlangıçta ödenir.", 13)
	column.add_child(feedback)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	branches = GridContainer.new()
	branches.columns = 2
	branches.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	branches.add_theme_constant_override("h_separation", 20)
	branches.add_theme_constant_override("v_separation", 16)
	scroll.add_child(branches)
	_rows = Focus.definitions()
	for route in ["light", "dark"]:
		var branch := VBoxContainer.new()
		branch.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		branch.add_theme_constant_override("separation", 12)
		branches.add_child(branch)
		branch.add_child(_label("AYDINLIK YOL · EĞİTİM VE HİZMET" if route == "light" else "KARANLIK YOL · SOKAK ÇEVRESİ", 17))
		for focus in _rows:
			if focus.route == route:
				_add_card(branch, focus)
	get_viewport().size_changed.connect(_layout)
	_layout()
	hide()

func _add_card(branch: VBoxContainer, focus: Dictionary) -> void:
	var card := PanelContainer.new()
	branch.add_child(card)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	card.add_child(column)
	var links: Array[String] = []
	for required in focus.prerequisites:
		for row in _rows:
			if row.id == required:
				links.append(row.name)
	column.add_child(_label("↓ " + " + ".join(links) if not links.is_empty() else "● Yolun başlangıcı", 12))
	column.add_child(_label(focus.name, 18))
	column.add_child(_label(focus.description, 14))
	column.add_child(_label("Süre: Gelecek içerik · Başlatılamaz" if focus.future else "Süre: %d gün · Bedel: %d" % [int(focus.duration_days), int(focus.cost)], 13))
	column.add_child(_label("Ön koşul: " + (" + ".join(links) if not links.is_empty() else "Yok"), 13))
	var status := _label("", 13)
	column.add_child(status)
	lock_labels[focus.id] = status
	var button := Button.new()
	button.text = "Odağı başlat"
	button.pressed.connect(func(): start_requested.emit(focus.id))
	column.add_child(button)
	start_buttons[focus.id] = button

func _layout() -> void:
	branches.columns = 1 if get_viewport().get_visible_rect().size.x < 950 else 2

func _label(text: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color("30564b"))
	return label

func refresh(world: RefCounted) -> void:
	_world = world
	if world == null:
		summary.text = "Önce başlangıç yolunu seç."
	else:
		var actor: Dictionary = world.characters[world.player_id]
		summary.text = "%s · Para: %d · Tamamlanan odak: %d" % [DisplayNames.education(actor.education), int(actor.money), world.completed_focuses.size()]
		if not world.active_focus.is_empty():
			var active_name: String = world.active_focus.id
			for row in _rows:
				if row.id == active_name:
					active_name = row.name
			summary.text += "\nEtkin: %s · %d gün kaldı" % [active_name, maxi(0, world.active_focus.end_day - world.day_index)]
	for id in start_buttons:
		var eligibility := Focus.availability(world, id)
		start_buttons[id].disabled = not eligibility.ok
		lock_labels[id].text = eligibility.reason

func show_result(reason: String) -> void:
	feedback.text = reason
