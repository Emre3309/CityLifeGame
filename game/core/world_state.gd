class_name WorldState
extends RefCounted

var day_index: int = 0
var player_id: String = ""
var characters: Dictionary = {}
var districts: Dictionary = {}
var organizations: Dictionary = {}
var active_focus: Dictionary = {}
var completed_focuses: Array[String] = []
var pending_events: Array = []
var resolved_event_ids: Array[String] = []
var history: Array = []
var rng_seed: int = 0
var rng_state: int = 0
var schema_version: int = 1

func to_dict() -> Dictionary:
	return {
		"day_index": day_index, "player_id": player_id, "characters": characters,
		"districts": districts, "organizations": organizations, "active_focus": active_focus,
		"completed_focuses": completed_focuses, "pending_events": pending_events,
		"resolved_event_ids": resolved_event_ids, "history": history,
		"rng_seed": rng_seed, "rng_state": rng_state, "schema_version": schema_version
	}.duplicate(true)

# Structural restoration only; untrusted save validation belongs to SaveService.
static func from_dict(data: Dictionary) -> WorldState:
	var world = load("res://core/world_state.gd").new()
	world.day_index = int(data.get("day_index", 0))
	world.player_id = str(data.get("player_id", ""))
	world.characters = data.get("characters", {}).duplicate(true)
	world.districts = data.get("districts", {}).duplicate(true)
	world.organizations = data.get("organizations", {}).duplicate(true)
	world.active_focus = data.get("active_focus", {}).duplicate(true)
	world.completed_focuses.assign(data.get("completed_focuses", []))
	world.pending_events = data.get("pending_events", []).duplicate(true)
	world.resolved_event_ids.assign(data.get("resolved_event_ids", []))
	world.history = data.get("history", []).duplicate(true)
	world.rng_seed = int(data.get("rng_seed", 0))
	world.rng_state = int(data.get("rng_state", 0))
	world.schema_version = int(data.get("schema_version", 1))
	return world
