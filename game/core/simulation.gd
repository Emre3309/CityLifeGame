extends RefCounted

const State = preload("res://core/world_state.gd")
const Focus = preload("res://features/focus/focus_service.gd")
const Life = preload("res://features/life/life_service.gd")
const Events = preload("res://features/events/event_service.gd")

var paused: bool = true
var days_per_second: int = 1
var _elapsed: float = 0.0

func set_paused(value: bool) -> void:
	paused = value
	_elapsed = 0.0

func set_speed(value: int) -> void:
	if value in [1, 4, 12]:
		days_per_second = value

func advance_frame(world: State, delta: float) -> void:
	if paused or world == null or delta <= 0 or not is_finite(delta):
		return
	if world.characters[world.player_id].death_day != -1:
		set_paused(true)
		return
	_elapsed += delta * days_per_second
	var days := int(floor(_elapsed + 0.0000001))
	_elapsed = maxf(0.0, _elapsed - days)
	for day in range(days):
		advance_days(world, 1)
		if world.characters[world.player_id].death_day != -1:
			set_paused(true)
			break

func advance_days(world: State, count: int) -> void:
	if world == null or count <= 0:
		return
	for day in range(count):
		world.day_index += 1
		_tick_focus(world)
		_tick_npcs(world)
		_trigger_events(world)
		_check_life(world)

# Domain services remain independent of scenes and UI.
func _tick_focus(world: State) -> void:
	Focus.tick(world)

func _tick_npcs(world: State) -> void:
	preload("res://features/npc/npc_service.gd").tick(world)

func _trigger_events(world: State) -> void:
	Events.trigger(world)

func _check_life(world: State) -> void:
	Life.tick(world)
