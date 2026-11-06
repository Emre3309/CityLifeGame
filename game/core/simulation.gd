extends RefCounted

const State = preload("res://core/world_state.gd")

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
	_elapsed += delta * days_per_second
	var days := int(floor(_elapsed + 0.0000001))
	_elapsed = maxf(0.0, _elapsed - days)
	advance_days(world, days)

func advance_days(world: State, count: int) -> void:
	if world == null or count <= 0:
		return
	for day in range(count):
		world.day_index += 1
		_tick_focus(world)
		_tick_npcs(world)
		_trigger_events(world)
		_check_life(world)

# Reserved daily stages are filled by Tasks 4, 6 and 5 respectively.
func _tick_focus(_world: State) -> void:
	pass

func _tick_npcs(_world: State) -> void:
	pass

func _trigger_events(_world: State) -> void:
	pass

func _check_life(world: State) -> void:
	for actor in world.characters.values():
		if actor.death_day == -1 and world.day_index >= actor.lifespan_end_day:
			actor.death_day = world.day_index
			world.history.append({"type": "death", "day": world.day_index, "character_id": actor.id, "cause": "lifespan"})
