extends Control

var summary: Label
var entries: Label

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
	column.add_theme_constant_override("separation", 14)
	panel.add_child(column)
	var heading := HBoxContainer.new()
	column.add_child(heading)
	var title := _label("YAKIN ÇEVREN · İLİŞKİLER", 21)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(title)
	var close_button := Button.new()
	close_button.text = "Kapat"
	close_button.pressed.connect(hide)
	heading.add_child(close_button)
	summary = _label("", 16)
	column.add_child(summary)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	entries = _label("", 16)
	entries.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(entries)
	hide()

func refresh(world: RefCounted) -> void:
	if world == null:
		summary.text = "Önce bir hayata başla."
		entries.text = ""
		return
	var actor: Dictionary = world.characters[world.player_id]
	summary.text = "%s · Para: %d · Soruşturma riski: %d/100" % [actor.name, actor.money, actor.get("investigation_risk", 0)]
	var lines: Array[String] = []
	for id in actor.relationships:
		var peer: Dictionary = world.characters.get(id, {})
		if peer.is_empty():
			lines.append("Artık bulunamayan kişi · " + str(id))
			continue
		var status := "Hayatta" if peer.death_day == -1 and world.day_index < peer.lifespan_end_day else "Hayatı sona erdi"
		lines.append("%s · %s\nYakınlığın: %d/100 · Sana yakınlığı: %d/100" % [peer.name, status, actor.relationships[id], peer.relationships.get(world.player_id, 0)])
	lines.append("Romantik prototip: yalnızca yaşıtlarla tanışma ve görüşme. Evlilik ve çocuk simülasyonu kapsam dışı.")
	entries.text = "\n\n".join(lines)

func _label(text: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color("30564b"))
	return label
