extends Node3D

const State = preload("res://core/world_state.gd")
const Commands = preload("res://core/command_service.gd")
const Simulation = preload("res://core/simulation.gd")

const Saves = preload("res://persistence/save_service.gd")
var saves := Saves.new()
var save_path := "user://saves/slot1.json"
var world: State
var simulation := Simulation.new()
@onready var city = $City
@onready var hud = $HUD

func _ready() -> void:
	var city_data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://content/city.json"))
	city.configure(city_data)
	hud.configure(city_data)
	city.building_selected.connect(hud.show_building)
	hud.save_requested.connect(_save_world)
	hud.load_requested.connect(_load_world)
	hud.start_requested.connect(_start_world)
	hud.scenario_requested.connect(_start_scenario)
	hud.authority_requested.connect(func(action: String, payload: Dictionary):
		var result := Commands.execute(world,{"type":"authority","actor_id":world.player_id,"action":action,"payload":payload})
		hud.authority_panel.show_result(result.reason)
		_refresh_hud()
	)
	hud.focus_requested.connect(func(focus_id: String):
		var result := Commands.execute(world, {"type":"start_focus", "focus_id":focus_id})
		hud.focus_panel.show_result(result.reason)
		_refresh_hud()
	)
	hud.event_requested.connect(func(event_id: String, choice_id: String):
		var result := Commands.execute(world, {"type":"resolve_event", "event_id":event_id, "choice_id":choice_id})
		hud.event_panel.show_result(result.reason)
		_refresh_hud()
	)
	hud.pause_requested.connect(func():
		if world != null:
			simulation.set_paused(not simulation.paused)
			_refresh_hud()
	)
	hud.speed_requested.connect(func(speed: int):
		simulation.set_speed(speed)
		_refresh_hud()
	)
	hud.district_requested.connect(func(district_id: String):
		for district in city_data.districts:
			if district.id == district_id:
				var center: Array = district.center
				city.camera_rig.focus_on(Vector3(center[0], center[1], center[2]))
	)
	_refresh_hud()

func _start_world(route: String) -> void:
	var result := Commands.execute(world, {"type": "start_world", "route": route, "seed": 19620901})
	if not result.ok:
		hud.start_panel.show_error(result.reason)
		return
	world = result.world
	simulation.set_paused(true)
	hud.start_panel.hide()
	_refresh_hud()

func _start_scenario(scenario_id: String) -> void:
	var result := Commands.execute(world,{"type":"start_scenario","scenario_id":scenario_id,"seed":19620901})
	if not result.ok:
		hud.start_panel.show_error(result.reason)
		return
	world = result.world
	simulation.set_paused(true)
	hud.start_panel.hide()
	_refresh_hud()

func _process(delta: float) -> void:
	if world == null:
		return
	var previous_day := world.day_index
	simulation.advance_frame(world, delta)
	if world.day_index != previous_day:
		_refresh_hud()

func _refresh_hud() -> void:
	city.refresh(world)
	city.set_paused(world == null or simulation.paused)
	hud.refresh_world(world, simulation.paused, simulation.days_per_second)

func _save_world() -> void:
	var result := saves.save_world(world,save_path)
	hud.show_save_result(result.reason)

func _load_world() -> void:
	var result := saves.load_world(save_path)
	if result.ok:
		world = result.world
		simulation.set_paused(true)
		hud.start_panel.hide()
		_refresh_hud()
	hud.show_save_result(result.reason)
