extends CanvasLayer

signal district_requested(district_id: String)
signal start_requested(route: String)
signal focus_requested(focus_id: String)
signal event_requested(event_id: String, choice_id: String)
signal pause_requested
signal speed_requested(days_per_second: int)

const Calendar = preload("res://core/calendar.gd")
const StartPanel = preload("res://ui/start_panel.gd")
const FocusPanel = preload("res://features/focus/focus_panel.gd")
const EventPanel = preload("res://features/events/event_panel.gd")
const RelationshipsPanel = preload("res://features/life/relationships_panel.gd")
const DistrictPanel = preload("res://ui/district_panel.gd")
const TYPE_NAMES := {"home": "Konut", "cafe": "Kahvehane", "school": "Okul", "police": "Karakol", "government": "Hükümet konağı", "warehouse": "Depo"}
const TYPE_DESCRIPTIONS := {
	"home": "Gündelik hayat bu sokaklarda akar. Komşular, aileler ve yeni başlangıçlar burada bir araya gelir.",
	"cafe": "Şehrin nabzı masalar arasında atar. Bir fincan kahve, uzun bir sohbet için iyi bir başlangıçtır.",
	"school": "Derslikler, kitaplar ve geleceğe açılan kapılar. Mahallenin gençleri burada buluşur.",
	"police": "Mahallenin güvenliği ve kamu düzeni için hizmet veren karakol.",
	"government": "Şehrin idari işlerinin yürütüldüğü hükümet konağı. Meydanın en belirgin yapısı.",
	"warehouse": "Kıyıdan gelen malların toplandığı ambar. Limanın çalışma hayatı burada şekillenir."
}
var city_data: Dictionary = {}
var selected_building_id := ""
var detail_title: Label
var district_label: Label
var type_label: Label
var description: Label
var detail_panel: PanelContainer
var header_title: Label
var date_label: Label
var controls_hint: Label
var age_label: Label
var focus_button: Button
var focus_panel: Control
var events_button: Button
var relationships_button: Button
var event_panel: Control
var relationships_panel: Control
var pause_button: Button
var speed_buttons: Dictionary = {}
var start_panel: Control
var root: Control
var district_panel: PanelContainer

func _ready() -> void:
	_build_ui()
	get_viewport().size_changed.connect(_layout)
	_layout()

func configure(data: Dictionary) -> void:
	city_data = data
	district_panel.configure(data.get("districts", []))
	show_building("")

func show_building(building_id: String) -> void:
	selected_building_id = ""
	for building in city_data.get("buildings", []):
		if building.id == building_id:
			selected_building_id = building_id
			detail_title.text = building.name
			type_label.text = TYPE_NAMES.get(building.type, building.type).to_upper()
			district_label.text = _district(building.district_id).get("name", "")
			description.text = TYPE_DESCRIPTIONS.get(building.type, "")
			return
	type_label.text = "ŞEHRİ KEŞFET"
	detail_title.text = "Bir binayı seçin"
	district_label.text = "Üç mahalle, ortak bir hayat"
	description.text = "Sokaklara yukarıdan bakın. Bir yapıya tıklayarak adını, işlevini ve mahallesini keşfedin.\n\nMahalle kartları sizi şehrin farklı köşelerine götürür."

func show_district(district_id: String) -> void:
	var district := _district(district_id)
	if district.is_empty():
		return
	selected_building_id = ""
	type_label.text = "MAHALLE REHBERİ"
	detail_title.text = district.name
	district_label.text = district.subtitle
	description.text = district.description
	district_requested.emit(district_id)

func _district(district_id: String) -> Dictionary:
	for district in city_data.get("districts", []):
		if district.id == district_id:
			return district
	return {}

func _build_ui() -> void:
	root = Control.new()
	root.name = "Overlay"
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = _theme()
	add_child(root)
	var header := PanelContainer.new()
	header.name = "Header"
	header.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	header.offset_left = 20
	header.offset_right = -20
	header.offset_top = 18
	header.offset_bottom = 90
	root.add_child(header)
	var header_row := HBoxContainer.new()
	header_row.add_theme_constant_override("separation", 20)
	header.add_child(header_row)
	var titles := VBoxContainer.new()
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_row.add_child(titles)
	header_title = _label("ŞEHİR VE HAYAT", 27, Color("264e48"))
	titles.add_child(header_title)
	age_label = _label("Geçmişini seçerek hayatına başla.", 13, Color("66766a"))
	titles.add_child(age_label)
	date_label = _label("1962  /  ŞEHİR REHBERİ", 15, Color("6b7c70"))
	date_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header_row.add_child(date_label)
	focus_button = Button.new()
	focus_button.text = "Odak ağacı"
	focus_button.disabled = true
	focus_button.pressed.connect(func(): _show_personal_panel(focus_panel))
	header_row.add_child(focus_button)
	var time_controls := VBoxContainer.new()
	header_row.add_child(time_controls)
	pause_button = Button.new()
	pause_button.text = "Duraklatıldı · Devam et"
	pause_button.disabled = true
	pause_button.pressed.connect(func(): pause_requested.emit())
	time_controls.add_child(pause_button)
	var speeds := HBoxContainer.new()
	time_controls.add_child(speeds)
	for speed in [1, 4, 12]:
		var button := Button.new()
		button.text = "%d gün/sn" % speed
		button.toggle_mode = true
		button.disabled = true
		button.pressed.connect(func(): speed_requested.emit(speed))
		speed_buttons[speed] = button
		speeds.add_child(button)
	detail_panel = PanelContainer.new()
	detail_panel.name = "Information"
	detail_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	detail_panel.offset_left = -294
	detail_panel.offset_right = -20
	detail_panel.offset_top = 110
	root.add_child(detail_panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	detail_panel.add_child(column)
	type_label = _label("", 12, Color("987b4c"))
	column.add_child(type_label)
	detail_title = _label("", 25, Color("264e48"))
	detail_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(detail_title)
	district_label = _label("", 14, Color("5b7b6e"))
	district_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(district_label)
	var separator := HSeparator.new()
	column.add_child(separator)
	description = _label("", 15, Color("59675e"))
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(description)
	district_panel = DistrictPanel.new()
	district_panel.name = "Districts"
	district_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	district_panel.offset_left = 20
	district_panel.offset_right = -20
	district_panel.offset_top = -108
	district_panel.offset_bottom = -20
	root.add_child(district_panel)
	district_panel.district_requested.connect(show_district)
	controls_hint = _label("Sol sürükle: kaydır   ·   Sağ sürükle: döndür   ·   Tekerlek: yakınlaş   ·   Tıkla: bina seç", 13, Color("314f46"))
	controls_hint.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	controls_hint.offset_left = 22
	controls_hint.offset_top = -137
	controls_hint.offset_bottom = -115
	controls_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(controls_hint)
	focus_panel = FocusPanel.new()
	focus_panel.name = "FocusPanel"
	root.add_child(focus_panel)
	focus_panel.start_requested.connect(func(focus_id: String): focus_requested.emit(focus_id))
	var personal_controls := HBoxContainer.new()
	personal_controls.position = Vector2(20, 104)
	personal_controls.add_theme_constant_override("separation", 8)
	root.add_child(personal_controls)
	events_button = Button.new()
	events_button.text = "Olaylar (0)"
	events_button.disabled = true
	events_button.pressed.connect(func(): _show_personal_panel(event_panel))
	personal_controls.add_child(events_button)
	relationships_button = Button.new()
	relationships_button.text = "İlişkiler"
	relationships_button.disabled = true
	relationships_button.pressed.connect(func(): _show_personal_panel(relationships_panel))
	personal_controls.add_child(relationships_button)
	event_panel = EventPanel.new()
	event_panel.name = "EventPanel"
	root.add_child(event_panel)
	event_panel.choice_requested.connect(func(event_id: String, choice_id: String): event_requested.emit(event_id, choice_id))
	relationships_panel = RelationshipsPanel.new()
	relationships_panel.name = "RelationshipsPanel"
	root.add_child(relationships_panel)
	start_panel = StartPanel.new()
	start_panel.name = "StartPanel"
	root.add_child(start_panel)
	start_panel.route_chosen.connect(func(route: String): start_requested.emit(route))

func _layout() -> void:
	var narrow := get_viewport().get_visible_rect().size.x < 800
	date_label.visible = true
	date_label.add_theme_font_size_override("font_size", 12 if narrow else 15)
	header_title.visible = get_viewport().get_visible_rect().size.x >= 680
	header_title.add_theme_font_size_override("font_size", 21 if narrow else 27)
	detail_panel.offset_left = -244 if narrow else -294
	controls_hint.text = "Sürükle: kaydır  ·  Sağ sürükle: döndür  ·  Tekerlek: yakınlaş" if narrow else "Sol sürükle: kaydır   ·   Sağ sürükle: döndür   ·   Tekerlek: yakınlaş   ·   Tıkla: bina seç"
	controls_hint.add_theme_font_size_override("font_size", 11 if narrow else 13)

func _label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

func _theme() -> Theme:
	var result := Theme.new()
	result.default_font_size = 16
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color("f4ecd9")
	panel.border_color = Color("d6c9ab")
	panel.set_border_width_all(1)
	panel.set_corner_radius_all(6)
	panel.content_margin_left = 20
	panel.content_margin_right = 20
	panel.content_margin_top = 15
	panel.content_margin_bottom = 15
	panel.shadow_color = Color(0.12, 0.21, 0.17, 0.13)
	panel.shadow_size = 5
	result.set_stylebox("panel", "PanelContainer", panel)
	for state in ["normal", "hover", "pressed", "focus"]:
		var button := StyleBoxFlat.new()
		button.bg_color = Color("dfe4d2") if state == "normal" else Color("c2d5c2")
		button.set_corner_radius_all(4)
		button.content_margin_left = 8
		button.content_margin_right = 8
		button.content_margin_top = 5
		button.content_margin_bottom = 5
		if state == "focus":
			button.bg_color = Color.TRANSPARENT
			button.border_color = Color("50786b")
			button.set_border_width_all(2)
		result.set_stylebox(state, "Button", button)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		result.set_color(state, "Button", Color("30564b"))
	return result

func refresh_world(world, paused: bool, speed: int) -> void:
	events_button.disabled = world == null
	relationships_button.disabled = world == null
	events_button.text = "Olaylar (%d)" % (0 if world == null else world.pending_events.size())
	event_panel.refresh(world)
	relationships_panel.refresh(world)
	focus_button.disabled = world == null
	focus_panel.refresh(world)
	pause_button.disabled = world == null
	pause_button.text = "Duraklatıldı · Devam et" if paused else "Zaman akıyor · Duraklat"
	for value in speed_buttons:
		speed_buttons[value].disabled = world == null
		speed_buttons[value].set_pressed_no_signal(value == speed)
	if world == null:
		date_label.text = "01.09.1962"
		return
	var actor: Dictionary = world.characters[world.player_id]
	var date := Calendar.date_on(world.day_index)
	var age := Calendar.age_on(actor.birth_date, date)
	date_label.text = Calendar.format_date(date)
	age_label.text = "%s · %d yıl %d ay" % [actor.name, age.years, age.months]

func _show_personal_panel(panel: Control) -> void:
	for candidate in [focus_panel, event_panel, relationships_panel]:
		candidate.visible = candidate == panel
	panel.move_to_front()
