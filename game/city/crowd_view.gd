extends Node3D

const WorldState = preload("res://core/world_state.gd")

# Decorative representatives only: domain population and daily decisions never use these nodes.
var paused := true
var _agents: Array[Dictionary] = []
var _patrol_ids: Array[String] = []
var _routes: Dictionary = {}

func configure(districts: Array) -> void:
	for child in get_children():
		remove_child(child)
		child.free()
	_agents.clear()
	_patrol_ids.clear()
	_routes.clear()
	for district in districts:
		var id := str(district.id)
		var x: float = district.center[0]
		var bounds: Array = {"cinar":[-35.0,-14.0], "carsi":[-14.0,14.0], "liman":[14.0,28.0]}.get(id, [x-5,x+5])
		_routes[id] = bounds
		for index in range(3):
			_add_agent("pedestrian", id, [Vector3(bounds[0]+2, 0.35, 4), Vector3(bounds[1]-2, 0.35, 4), Vector3(bounds[1]-2, 0.35, 23), Vector3(bounds[0]+2, 0.35, 23)], index * 0.22, 1.2)
		_add_agent("car", id, [Vector3(bounds[0], 0.4, 2), Vector3(bounds[1], 0.4, 2), Vector3(bounds[1], 0.4, 25), Vector3(bounds[0], 0.4, 25)], 0.3, 3.0)

func refresh(world: WorldState) -> void:
	var patrol_ids: Array[String] = []
	if world != null:
		for entry in world.history:
			if entry.get("type") == "authority_action" and entry.get("action") == "assign_patrol" and world.day_index - int(entry.day) < 7:
				var id: String = entry.get("payload", {}).get("district_id", "")
				if _routes.has(id) and not patrol_ids.has(id): patrol_ids.append(id)
	patrol_ids.sort()
	if patrol_ids == _patrol_ids: return
	for index in range(_agents.size() - 1, -1, -1):
		if _agents[index].node.get_meta("kind") == "police":
			var node: Node3D = _agents[index].node
			remove_child(node)
			node.free()
			_agents.remove_at(index)
	_patrol_ids = patrol_ids
	for id in patrol_ids:
		var bounds: Array = _routes[id]
		_add_agent("police", id, [Vector3(bounds[0], 0.4, 2), Vector3(bounds[1], 0.4, 2), Vector3(bounds[1], 0.4, 25), Vector3(bounds[0], 0.4, 25)], 0.65, 2.5)

func set_paused(value: bool) -> void:
	paused = value

func _process(delta: float) -> void:
	if paused: return
	for agent in _agents:
		agent.distance = fmod(float(agent.distance) + maxf(0.0, delta) * float(agent.speed), float(agent.length))
		_place(agent)

func _add_agent(kind: String, district: String, route: Array, fraction: float, speed: float) -> void:
	var node := Node3D.new()
	node.set_meta("kind", kind)
	node.set_meta("district_id", district)
	add_child(node)
	var color := Color("476c65") if kind == "pedestrian" else Color("a35f48")
	if kind == "police": color = Color("314e68")
	var body := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.42, 1.2, 0.42) if kind == "pedestrian" else Vector3(1.2, 0.65, 2.3)
	body.mesh = mesh
	body.position.y = mesh.size.y / 2
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 1.0
	body.material_override = material
	node.add_child(body)
	if kind == "pedestrian":
		var head := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.22
		sphere.height = 0.44
		head.mesh = sphere
		head.position.y = 1.42
		head.material_override = material
		node.add_child(head)
	else:
		var roof := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.95, 0.45, 1.15)
		roof.mesh = box
		roof.position.y = 0.85
		var glass := StandardMaterial3D.new()
		glass.albedo_color = Color("a8b6af")
		roof.material_override = glass
		node.add_child(roof)
	if kind == "police":
		var label := Label3D.new()
		label.text = "POLİS · DEVRİYE"
		label.position.y = 2.6
		label.font_size = 28
		label.pixel_size = 0.025
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.no_depth_test = true
		node.add_child(label)
	var length := 0.0
	for index in range(route.size()): length += route[index].distance_to(route[(index + 1) % route.size()])
	var agent := {"node":node, "route":route, "distance":fraction * length, "length":length, "speed":speed}
	_agents.append(agent)
	_place(agent)

func _place(agent: Dictionary) -> void:
	var remaining: float = agent.distance
	var route: Array = agent.route
	for index in range(route.size()):
		var start: Vector3 = route[index]
		var finish: Vector3 = route[(index + 1) % route.size()]
		var length := start.distance_to(finish)
		if remaining <= length:
			agent.node.position = start.lerp(finish, remaining / length)
			agent.node.rotation.y = atan2(finish.x - start.x, finish.z - start.z)
			return
		remaining -= length
