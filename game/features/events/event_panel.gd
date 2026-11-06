extends Control

signal choice_requested(event_id: String, choice_id: String)

const Events = preload("res://features/events/event_service.gd")
var feedback: Label
var summary: Label
var cards: VBoxContainer
var choice_buttons: Dictionary = {}

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
	var title := _label("HAYATIN İÇİNDEN · OLAYLAR", 21)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(title)
	var close_button := Button.new()
	close_button.text = "Kapat"
	close_button.pressed.connect(hide)
	heading.add_child(close_button)
	summary = _label("", 15)
	column.add_child(summary)
	feedback = _label("Seçeneklerin bedelini ve riskini okuyarak karar ver. Zamanı üst çubuktan duraklatabilirsin.", 14)
	column.add_child(feedback)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	cards = VBoxContainer.new()
	cards.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cards.add_theme_constant_override("separation", 12)
	scroll.add_child(cards)
	hide()

func refresh(world: RefCounted) -> void:
	for child in cards.get_children():
		cards.remove_child(child)
		child.queue_free()
	choice_buttons.clear()
	if world == null:
		summary.text = "Önce bir hayata başla."
		return
	summary.text = "Bekleyen olay: %d · Para: %d · Soruşturma riski: %d/100" % [world.pending_events.size(), world.characters[world.player_id].money, world.characters[world.player_id].get("investigation_risk", 0)]
	if world.pending_events.is_empty():
		cards.add_child(_label("Bekleyen olay yok. Takvim ilerledikçe aile, iş ve tanışma fırsatları açılır.", 16))
	var definitions := Events.definitions()
	for event in world.pending_events:
		var template: Dictionary = {}
		for row in definitions:
			if row.id == event.get("template_id"): template = row
		if template.is_empty():
			cards.add_child(_label("İçeriği bulunamayan olay · " + str(event.get("instance_id", "?")), 15))
			continue
		var card := PanelContainer.new()
		cards.add_child(card)
		var column := VBoxContainer.new()
		column.add_theme_constant_override("separation", 8)
		card.add_child(column)
		column.add_child(_label(template.title, 20))
		var names: Array[String] = []
		for id in event.get("participant_ids", []):
			names.append(world.characters.get(id, {}).get("name", "Artık bulunamayan kişi"))
		column.add_child(_label("Katılımcılar: " + ", ".join(names), 13))
		column.add_child(_label(template.description, 15))
		for choice in template.choices:
			var button := Button.new()
			button.text = choice.title
			button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			button.alignment = HORIZONTAL_ALIGNMENT_LEFT
			var eligibility := Events.availability(world, event.instance_id, choice.id)
			button.disabled = not eligibility.ok
			button.pressed.connect(func():
				if button.disabled: return
				button.disabled = true
				choice_requested.emit(event.instance_id, choice.id)
			)
			column.add_child(button)
			choice_buttons[event.instance_id + ":" + choice.id] = button
			if not eligibility.ok: column.add_child(_label(eligibility.reason, 13))

func show_result(reason: String) -> void:
	feedback.text = reason

func _label(text: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color("30564b"))
	return label
