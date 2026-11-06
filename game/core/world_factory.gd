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
		# JSON parses all numbers as floats; the domain uses whole-valued fields.
		var actor: Dictionary = world.characters[character.id]
		for field in ["death_day","health","money","imprisoned_until","lifespan_end_day"]: actor[field] = int(actor[field])
		for field in ["year","month","day"]: actor.birth_date[field] = int(actor.birth_date[field])
		for field in ["knowledge","relationships"]:
			for key in actor[field]: actor[field][key] = int(actor[field][key])
	for organization in catalog.data.organizations:
		world.organizations[organization.id] = organization.duplicate(true)
		world.organizations[organization.id].budget = int(organization.budget)
		world.organizations[organization.id].capacity = 3
		world.organizations[organization.id].capacity_max = 3
	world.organizations.governorship.security_priority = "liman"
	world.organizations.police.investigations = {}
	world.organizations.harbor_network.member_ids = ["cem"]
	world.organizations.harbor_network.assignments = {}
	world.characters[world.player_id] = create_player(world.player_id, route, {"year":1945,"month":3,"day":1}, 0)
	world.characters[world.player_id].relationships = {"nermin":70,"aylin":20}
	world.characters.nermin.relationships[world.player_id] = 70
	world.characters.aylin.relationships[world.player_id] = 20
	return world

# Development worlds use established adult office holders; normal routes still create Deniz.
static func scenarios() -> Array:
	var data = JSON.parse_string(FileAccess.get_file_as_string("res://content/scenarios.json"))
	return data if data is Array else []

static func create_scenario(scenario_id: String, seed_value: int) -> State:
	for row in scenarios():
		if row.id == scenario_id:
			var world := create(row.route,seed_value)
			if world == null or not world.characters.has(row.actor_id): return null
			world.player_id = row.actor_id
			if row.has("risk_target_id"): world.characters[row.risk_target_id].investigation_risk = int(row.investigation_risk)
			world.history.append({"type":"development_scenario","day":0,"reason":"Geliştirme senaryosu: " + row.title})
			return world
	return null

# Fresh personal state is shared by the first and subsequent lives.
static func create_player(id: String, route: String, birth: Dictionary, start_day: int) -> Dictionary:
	return {
		"id": id, "name": "Deniz", "district_id": "cinar",
		"birth_date": birth, "death_day": -1,
		"health": 100, "money": 100, "investigation_risk": 0,
		"background": "Liseyi bitirdin; eğitim ve kamu hayatına açılan bir yol önünde." if route == "light" else "Liseyi yarıda bıraktın; geçimini sağlamak için sokak çevrenle bağ kurdun.",
		"route": route, "role": "citizen",
		"education": "high_school_graduate" if route == "light" else "high_school_dropout",
		"knowledge": {}, "relationships": {},
		"imprisoned_until": -1, "lifespan_end_day": start_day + 24000
	}
