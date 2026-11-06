extends RefCounted

const State = preload("res://core/world_state.gd")
const Factory = preload("res://core/world_factory.gd")
const Focus = preload("res://features/focus/focus_service.gd")
const Events = preload("res://features/events/event_service.gd")

static func execute(world: State, command: Dictionary) -> Dictionary:
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
