extends Control

signal action_requested(action: String, payload: Dictionary)
const DisplayNames = preload("res://core/display_names.gd")
const Authority = preload("res://features/careers/authority_service.gd")
const LABELS := {"set_security_priority":"Öncelik belirle · 20 bütçe", "allocate_budget":"Emniyete 100 aktar", "assign_patrol":"Devriye ata · 50 bütçe, 1 personel", "open_investigation":"Dosya aç · 50 bütçe, 1 personel", "launch_operation":"Operasyon · 100 bütçe, 2 personel", "assign_member":"Üye ata · 20 bütçe, 1 personel", "expand_influence":"Etki girişimi · 50 bütçe, 1 personel"}
var summary: Label
var feedback: Label
var status: Label
var recent: Label
var district_choice: OptionButton
var target_choice: OptionButton
var actions: VBoxContainer
var action_buttons: Dictionary = {}
var _world: RefCounted

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var shade := ColorRect.new()
	shade.color = Color(0.08,0.17,0.14,0.7)
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
	column.add_theme_constant_override("separation",8)
	panel.add_child(column)
	var heading := HBoxContainer.new()
	column.add_child(heading)
	var title := _label("KURUMLAR VE MAKAM KARARLARI")
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(title)
	var close := Button.new()
	close.text = "Kapat"
	close.pressed.connect(hide)
	heading.add_child(close)
	feedback = _label("Makam yetkileri birbirinden bağımsızdır. Bu panel açıldığında zaman duraklatılır.")
	column.add_child(feedback)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	var body := VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation",10)
	scroll.add_child(body)
	summary = _label("")
	body.add_child(summary)
	status = _label("")
	body.add_child(status)
	body.add_child(_label("Mahalle / hedef kişi (seçilen emre göre kullanılır):"))
	district_choice = OptionButton.new()
	body.add_child(district_choice)
	target_choice = OptionButton.new()
	body.add_child(target_choice)
	district_choice.item_selected.connect(func(_index): _refresh_actions())
	target_choice.item_selected.connect(func(_index): _refresh_actions())
	actions = VBoxContainer.new()
	body.add_child(actions)
	recent = _label("")
	body.add_child(recent)
	hide()

func refresh(world: RefCounted) -> void:
	_world = world
	if world == null:
		summary.text = "Önce bir hayata başla."
		return
	var player: Dictionary = world.characters[world.player_id]
	summary.text = "%s · Makam: %s\nPara kaynağı: başlangıç kurum hazineleri. Bütçe otomatik yenilenmez; vali hazineden emniyete aktarabilir.\nPersonel: haftada yenilenen en çok 3 görev birimi. Dosya incelemesi haftada 25 bütçe; +25 ilerleme, mevcut risk kadar (en çok +25) delil.\nOperasyon: en az 60 delil, 50 ilerleme, 2 personel. Prototip mahkûmiyeti 30 gün hapis başlatır." % [player.name,DisplayNames.role(player.role)]
	status.text = ""
	for office in ["governorship","police","harbor_network"]:
		var org: Dictionary = world.organizations[office]
		var holder: String = world.characters.get(org.leader_id,{}).get("name","Makam boş")
		status.text += "%s · %s · bütçe %d · personel %d/3\n" % [org.name,holder,org.budget,org.capacity]
	for id in world.organizations.police.investigations:
		var data: Dictionary = world.organizations.police.investigations[id]
		status.text += "Dosya: %s · ilerleme %d/100 · delil %d/100\n" % [world.characters[id].name,data.progress,data.evidence]
	var district: String = _selected(district_choice)
	district_choice.clear()
	for id in world.districts:
		district_choice.add_item({"cinar":"Çınar","carsi":"Çarşı","liman":"Liman"}.get(id,id))
		district_choice.set_item_metadata(district_choice.item_count-1,id)
		if id == district: district_choice.select(district_choice.item_count-1)
	var target: String = _selected(target_choice)
	target_choice.clear()
	for id in world.characters:
		if id == world.player_id: continue
		target_choice.add_item(world.characters[id].name + " · risk %d/100" % int(world.characters[id].get("investigation_risk",0)))
		target_choice.set_item_metadata(target_choice.item_count-1,id)
		if id == target or (target.is_empty() and id == ("cem" if player.role == "gang_leader" else "riza")): target_choice.select(target_choice.item_count-1)
	recent.text = "Son kurum kayıtları:\n"
	var entries: Array[String] = []
	for e in world.history:
		if e.type in ["authority_action","npc_skipped","investigation_progress","conviction","office_succession"]: entries.append("Gün %d · %s" % [e.day,e.reason])
	for i in range(maxi(0,entries.size()-6),entries.size()): recent.text += entries[i] + "\n"
	_refresh_actions()

func _refresh_actions() -> void:
	for child in actions.get_children():
		actions.remove_child(child)
		child.queue_free()
	action_buttons.clear()
	if _world == null: return
	var role: String = _world.characters[_world.player_id].role
	if not Authority.ACTIONS.has(role):
		actions.add_child(_label("Vatandaşın yönetim emri yoktur. Normal kariyer makam kazandırmaz; ayrı geliştirme senaryoları başlangıç menüsündedir."))
		return
	for action in Authority.ACTIONS[role]:
		var payload := _payload(action)
		var checked := Authority.availability(_world,_world.player_id,action,payload)
		var button := Button.new()
		button.text = LABELS[action]
		button.disabled = not checked.ok
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.pressed.connect(func():
			if button.disabled: return
			button.disabled = true
			action_requested.emit(action,payload)
		)
		actions.add_child(button)
		action_buttons[action] = button
		if not checked.ok: actions.add_child(_label(checked.reason))

func _selected(choice: OptionButton) -> String:
	if choice.selected < 0: return ""
	return str(choice.get_item_metadata(choice.selected))

func _payload(action: String) -> Dictionary:
	match action:
		"allocate_budget": return {"organization_id":"police","amount":100}
		"open_investigation", "launch_operation": return {"target_id":_selected(target_choice)}
		"assign_member": return {"target_id":_selected(target_choice),"district_id":_selected(district_choice)}
	return {"district_id":_selected(district_choice)}

func show_result(reason: String) -> void:
	feedback.text = reason

func _label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size",14)
	return label
