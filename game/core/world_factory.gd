extends RefCounted

const State = preload("res://core/world_state.gd")
const Catalog = preload("res://core/content_catalog.gd")

static func create(route: String, seed: int) -> State:
	if route not in ["light", "dark"]:
		return null
	var catalog: Dictionary = Catalog.load_all("res://content")
	if not catalog.ok:
		return null
	var world := State.new()
	world.player_id = "player_1"
	world.rng_seed = seed
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	world.rng_state = rng.state
	for district in catalog.data.city.districts:
		world.districts[district.id] = {
			"id": district.id, "population": 1500, "prosperity": 50,
			"trust": 50, "crime_pressure": 30, "official_owner_id": "kemal",
			"influence": {"harbor_network": 20 if district.id == "liman" else 5}
		}
	for character in catalog.data.characters:
		world.characters[character.id] = character.duplicate(true)
		world.characters[character.id].investigation_risk = 0
	for organization in catalog.data.organizations:
		world.organizations[organization.id] = organization.duplicate(true)
	world.characters[world.player_id] = {
		"id": world.player_id, "name": "Deniz", "district_id": "cinar",
		"birth_date": {"year": 1945, "month": 3, "day": 1}, "death_day": -1,
		"health": 100, "money": 100, "investigation_risk": 0,
		"background": "Liseyi bitirdin; eğitim ve kamu hayatına açılan bir yol önünde." if route == "light" else "Liseyi yarıda bıraktın; geçimini sağlamak için sokak çevrenle bağ kurdun.",
		"route": route, "role": "citizen",
		"education": "high_school_graduate" if route == "light" else "high_school_dropout",
		"knowledge": {}, "relationships": {"nermin": 70, "aylin": 20},
		"imprisoned_until": -1, "lifespan_end_day": 24000
	}
	world.characters.nermin.relationships[world.player_id] = 70
	world.characters.aylin.relationships[world.player_id] = 20
	return world
