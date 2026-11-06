extends SceneTree

# Render the game itself; this harness never injects or claims physical input.
var game: Node
var output := "res://../docs/validation/task7/"

func _initialize() -> void:
	_capture.call_deferred()

func _frames(count: int = 3) -> void:
	for index in range(count): await process_frame
	await RenderingServer.frame_post_draw

func _save(label: String) -> void:
	await _frames()
	var path := ProjectSettings.globalize_path(output + label + ".png")
	var error := root.get_texture().get_image().save_png(path)
	print("CAPTURE %s (%s)" % [path, error])

func _capture() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i.ZERO
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await _frames()
	game._start_scenario("police_demo")
	var authority = load("res://features/careers/authority_service.gd")
	authority.apply(game.world, game.world.player_id, "assign_patrol", {"district_id":"liman"})
	game._refresh_hud()
	game.hud.show_district("liman")
	# A city-wide view first, before district camera focusing.
	game.city.camera_rig.focus_on(Vector3.ZERO)
	await _save("1280-overview")
	for id in ["cinar", "carsi", "liman"]:
		game.hud.show_district(id)
		await _save("1280-" + id)
	for zoom in [15.0, 90.0]:
		game.city.camera_rig.camera.size = zoom
		await _save("1280-zoom-%d" % zoom)
	game.city.camera_rig.camera.size = 86.0
	for panel in ["focus_panel", "event_panel", "relationships_panel", "authority_panel"]:
		game.hud._show_personal_panel(game.hud.get(panel))
		await _save("1280-" + panel)
		game.hud.get(panel).hide()
	root.size = Vector2i(800, 640)
	await _frames()
	game.hud.show_district("liman")
	game.city.camera_rig.focus_on(Vector3.ZERO)
	await _save("800-overview")
	for panel in ["focus_panel", "event_panel", "relationships_panel", "authority_panel"]:
		game.hud._show_personal_panel(game.hud.get(panel))
		await _save("800-" + panel)
		game.hud.get(panel).hide()
	print("HARDWARE CPU=%s GPU=%s renderer=%s" % [OS.get_processor_name(), RenderingServer.get_video_adapter_name(), RenderingServer.get_current_rendering_method()])
	game.simulation.set_paused(false)
	game._refresh_hud()
	await _frames(10)
	var started := Time.get_ticks_usec()
	await _frames(120)
	print("PERFORMANCE 120 rendered frames elapsed_ms=%.1f active_agents=%d resolution=%s" % [(Time.get_ticks_usec()-started)/1000.0, game.city.crowd.get_child_count(), root.size])
	quit()
