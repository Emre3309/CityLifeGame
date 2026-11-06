extends Control

signal next_life_requested(route: String)
var entries: Label
var feedback: Label
var _player_id := ""

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var shade := ColorRect.new()
	shade.color = Color(0.08,0.17,0.14,0.70)
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
	column.add_theme_constant_override("separation",12)
	panel.add_child(column)
	var title := Label.new()
	title.text = "HAYAT ÖZETİ · ŞEHİR DEVAM EDİYOR"
	title.add_theme_font_size_override("font_size",21)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(title)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	entries = Label.new()
	entries.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	entries.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(entries)
	feedback = Label.new()
	feedback.text = "Yeni kişi 17 yıl 6 aylık başlar; kendi parası ve geçmişiyle. Önceki kişi, kurumlar ve mahalleler korunur."
	feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(feedback)
	var routes := HBoxContainer.new()
	column.add_child(routes)
	for route in ["light","dark"]:
		var button := Button.new()
		button.text = "Yeni hayat · " + ("Aydınlık yol" if route == "light" else "Karanlık yol")
		button.pressed.connect(func(): next_life_requested.emit(route))
		routes.add_child(button)
	var close := Button.new()
	close.text = "Şehri incele"
	close.pressed.connect(hide)
	routes.add_child(close)
	hide()

func refresh(world: RefCounted) -> void:
	if world == null or world.characters[world.player_id].death_day == -1:
		_player_id = ""
		hide()
		return
	entries.text = preload("res://features/life/life_service.gd").summary(world)
	if _player_id != world.player_id:
		_player_id = world.player_id
		show()
		move_to_front()
