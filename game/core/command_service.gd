extends RefCounted

const State = preload("res://core/world_state.gd")
const Factory = preload("res://core/world_factory.gd")
const Focus = preload("res://features/focus/focus_service.gd")
const Events = preload("res://features/events/event_service.gd")

static func execute(world: State, command: Dictionary) -> Dictionary:
	if command.get("type", "") == "start_next_life":
		if not command.get("route") is String: return {"ok":false,"reason":"Başlangıç yolu geçersiz."}
		return preload("res://features/life/life_service.gd").start_next_life(world,command.route)
	if command.get("type", "") == "start_scenario":
		if world != null: return {"ok":false,"reason":"Başlamış hayat değiştirilemez; geliştirme senaryosu için yeniden başlat."}
		if not command.get("scenario_id") is String or not command.get("seed",1) is int: return {"ok":false,"reason":"Senaryo bilgileri geçersiz."}
		var created := Factory.create_scenario(command.scenario_id,command.get("seed",1))
		if created == null: return {"ok":false,"reason":"Geliştirme senaryosu bulunamadı."}
		return {"ok":true,"reason":"Ayrı geliştirme dünyası başladı.","world":created}
	if command.get("type", "") == "authority":
		if world == null or command.get("actor_id") != world.player_id: return {"ok":false,"reason":"Yalnızca oyuncu kimliğiyle emir verilebilir."}
		if not command.get("action") is String or not command.get("payload") is Dictionary: return {"ok":false,"reason":"Emir bilgileri geçersiz."}
		return preload("res://features/careers/authority_service.gd").apply(world,world.player_id,command.action,command.payload)
	if command.get("type", "") == "start_world":
		if world != null:
			return {"ok": false, "reason": "Hayat başladı; başlangıç yolu yeniden seçilemez."}
		var route = command.get("route", "")
		var seed_value = command.get("seed", 1)
		if not route is String or not seed_value is int:
			return {"ok": false, "reason": "Başlangıç bilgileri geçersiz."}
		var created := Factory.create(route, seed_value)
		if created == null:
			return {"ok": false, "reason": "Başlangıç yolu veya içerik geçersiz."}
		return {"ok": true, "reason": "Hayatın başladı.", "world": created}
	if command.get("type", "") == "start_focus":
		if not command.get("focus_id") is String:
			return {"ok": false, "reason": "Odak kimliği geçersiz."}
		return Focus.start(world, command.focus_id)
	if command.get("type", "") == "resolve_event":
		if not command.get("event_id") is String or not command.get("choice_id") is String:
			return {"ok":false, "reason":"Olay ve seçenek kimlikleri geçersiz."}
		return Events.resolve(world, command.event_id, command.choice_id)
	return {"ok": false, "reason": "Bilinmeyen komut."}
