extends "res://tests/capture_presentation.gd"

# Own-framebuffer renders plus real UI signals. No OS input injection is used.
func _capture() -> void:
	output = "res://../docs/validation/task10/"
	root.content_scale_size = Vector2i.ZERO
	for width in [1280,800]:
		root.size = Vector2i(width,720 if width == 1280 else 640)
		game = load("res://main.tscn").instantiate()
		root.add_child(game)
		game.set_process(false)
		game.save_path = "user://saves/capture_delivery.json"
		await _save("%d-start" % width)
		game.hud.start_panel.route_chosen.emit("light")
		game.city.camera_rig.focus_on(Vector3.ZERO)
		await _save("%d-light" % width)
		game.hud.focus_button.pressed.emit()
		game.hud.focus_panel.start_buttons.university_prep.pressed.emit()
		await _save("%d-focus" % width)
		game.hud.focus_panel.hide()
		game.hud.speed_requested.emit(12)
		game.hud.pause_requested.emit()
		game._process(28.0/12.0)
		game.hud.pause_requested.emit()
		game.hud.events_button.pressed.emit()
		await _save("%d-day28-event" % width)
		game.hud.event_panel.choice_buttons["player_1:family_support:part_time_work"].pressed.emit()
		await _save("%d-family-result" % width)
		game.hud.event_panel.hide()
		game.hud.save_requested.emit()
		game.simulation.advance_days(game.world,2)
		game.hud.load_requested.emit()
		game.hud._show_personal_panel(game.hud.save_panel)
		await _save("%d-restored" % width)
		game.hud.save_panel.hide()
		game.hud.show_district("liman")
		await _save("%d-liman" % width)
		game.city.camera_rig.camera.size = 15.0
		await _save("%d-zoom15" % width)
		game.city.camera_rig.camera.size = 86.0
		game.world.characters[game.world.player_id].lifespan_end_day = 29
		game.simulation.set_speed(12)
		game.simulation.set_paused(false)
		game._process(1.0)
		await _save("%d-death" % width)
		game.hud.life_summary_panel.next_life_requested.emit("dark")
		await _save("%d-newlife" % width)
		game.free()
	for scenario in ["governor_demo","police_demo","gang_demo"]:
		root.size = Vector2i(1280,720)
		game = load("res://main.tscn").instantiate()
		root.add_child(game)
		game.set_process(false)
		game._start_scenario(scenario)
		game.hud.authority_button.pressed.emit()
		await _save("1280-" + scenario)
		game.free()
	print("HARDWARE CPU=%s GPU=%s renderer=%s" % [OS.get_processor_name(),RenderingServer.get_video_adapter_name(),RenderingServer.get_current_rendering_method()])
	print("DELIVERY CAPTURES COMPLETE")
	quit(0)
