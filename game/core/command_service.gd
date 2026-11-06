extends RefCounted

const State = preload("res://core/world_state.gd")
const Factory = preload("res://core/world_factory.gd")

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
	return {"ok": false, "reason": "Bilinmeyen komut."}
