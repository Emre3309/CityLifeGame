extends Control

signal route_chosen(route: String)
var message: Label
var card: PanelContainer

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.08, 0.17, 0.15, 0.55)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	card = PanelContainer.new()
	card.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	add_child(card)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	card.add_child(column)
	var title := Label.new()
	title.text = "HAYATININ EŞİĞİNDE"
	title.add_theme_font_size_override("font_size", 26)
	column.add_child(title)
	message = Label.new()
	message.text = "1 Eylül 1962 · 17 yıl 6 ay\nÇınar Mahallesi'nde yeni bir hayat. Bilinen geçmişini seç."
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(message)
	for row in [["light", "Aydınlık yol · Lise mezunu", "Eğitim ve kamu hayatı için hazırlan."], ["dark", "Karanlık yol · Lise yarıda", "Sokak çevrenle bağ kurarak geçimini ara."]]:
		var button := Button.new()
		button.text = row[1] + "\n" + row[2]
		button.custom_minimum_size.y = 64
		button.pressed.connect(func(): route_chosen.emit(row[0]))
		column.add_child(button)
	var hint := Label.new()
	hint.text = "Yol seçimi bu hayat için kalıcıdır. Oyun duraklatılmış başlar."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(hint)
	get_viewport().size_changed.connect(_layout)
	_layout()

func show_error(text: String) -> void:
	message.text = text

func _layout() -> void:
	var width := minf(620.0, get_viewport().get_visible_rect().size.x - 40.0)
	card.offset_left = -width / 2
	card.offset_right = width / 2
	card.offset_top = -190
	card.offset_bottom = 190
