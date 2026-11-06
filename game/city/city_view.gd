extends Node3D

signal building_selected(building_id: String)

const BuildingView = preload("res://city/building_view.gd")
var city_data: Dictionary = {}
var selected_building_id := ""
var buildings: Dictionary = {}
var scenery: Node3D
var building_root: Node3D
@onready var camera_rig = $CameraRig

func _ready() -> void:
	camera_rig.selection_requested.connect(_pick_building)

func configure(data: Dictionary) -> void:
	city_data = data
	selected_building_id = ""
	buildings.clear()
	for child in get_children():
		if child.name in ["Scenery", "Buildings"]:
			remove_child(child)
			child.free()
	scenery = Node3D.new()
	scenery.name = "Scenery"
	add_child(scenery)
	building_root = Node3D.new()
	building_root.name = "Buildings"
	add_child(building_root)
	_build_landscape()
	for building_data in data.get("buildings", []):
		var view = BuildingView.new()
		building_root.add_child(view)
		view.configure(building_data)
		buildings[str(building_data.id)] = view
	building_selected.emit("")

func select_building(building_id: String) -> void:
	if not buildings.has(building_id):
		return
	if buildings.has(selected_building_id):
		buildings[selected_building_id].set_selected(false)
	selected_building_id = building_id
	buildings[building_id].set_selected(true)
	building_selected.emit(building_id)

func _pick_building(screen_position: Vector2) -> void:
	var camera: Camera3D = camera_rig.camera
	var origin := camera.project_ray_origin(screen_position)
	var direction := camera.project_ray_normal(screen_position)
	var query := PhysicsRayQueryParameters3D.create(origin, origin + direction * 500.0, 1)
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		var id: String = hit.collider.get_meta("building_id", "")
		select_building(id)

func _build_landscape() -> void:
	_box(Vector3(82, 1, 66), Vector3(-8, -0.65, 0), Color("a7b395"))
	_box(Vector3(66, 0.22, 51), Vector3(-3, 0, 0), Color("d6c8a9"))
	_box(Vector3(55, 0.1, 49), Vector3(59, -0.3, 0), Color("6b9f9d"))
	_box(Vector3(4, 0.45, 53), Vector3(30, 0, 0), Color("c5b597"))
	for z in [-12.0, 2.0, 25.0, -26.0]:
		_box(Vector3(66, 0.08, 4.5), Vector3(-3, 0.17, z), Color("e4d8bc"))
		_box(Vector3(66, 0.1, 3.0), Vector3(-3, 0.24, z), Color("76847c"))
		for x in range(-32, 30, 5):
			_box(Vector3(1.8, 0.02, 0.1), Vector3(x, 0.3, z), Color("d4cead"))
	for x in [-14.0, 14.0, -35.0]:
		_box(Vector3(4.5, 0.08, 51), Vector3(x, 0.17, 0), Color("e4d8bc"))
		_box(Vector3(3.0, 0.1, 51), Vector3(x, 0.24, 0), Color("76847c"))
	# The small civic square stays open and legible between the public buildings.
	_box(Vector3(6, 0.15, 9), Vector3(0.5, 0.23, -5), Color("c7ba9e"))
	_cylinder(1.5, 0.45, Vector3(0.5, 0.55, -5), Color("e6dbc1"))
	_cylinder(1.15, 0.1, Vector3(0.5, 0.83, -5), Color("73a5a2"))
	_cylinder(0.25, 1.5, Vector3(0.5, 1.3, -5), Color("daceb2"))
	for z in [-19.0, 8.0, 20.0]:
		_box(Vector3(12, 0.5, 2.5), Vector3(35, -0.05, z), Color("b5a185"))
		for x in [31.0, 35.0, 39.0]:
			_cylinder(0.13, 1.0, Vector3(x, 0.3, z + 1.0), Color("7c7761"))
	_boat(Vector3(38, 0, -10))
	_boat(Vector3(42, 0, 16))
	for p in [Vector3(-32, 0, 17), Vector3(-30, 0, 17), Vector3(-18, 0, 7), Vector3(-18, 0, 11), Vector3(-9, 0, 21), Vector3(5, 0, 21), Vector3(10, 0, 21), Vector3(-31, 0, -23), Vector3(-23, 0, -23), Vector3(-5, 0, -25), Vector3(7, 0, -25), Vector3(27, 0, 2), Vector3(27, 0, 13)]:
		_tree(p)
	for x in [-31.0, -18.0, -9.0, 10.0, 27.0]:
		for z in [-10.0, 23.0]:
			_cylinder(0.08, 3.0, Vector3(x, 1.7, z), Color("606f60"))
			_box(Vector3(0.48, 0.5, 0.48), Vector3(x, 3.3, z), Color("f0ddb0"))
	for district in city_data.get("districts", []):
		var label := Label3D.new()
		label.text = str(district.name).to_upper()
		var point: Array = district.center
		label.position = Vector3(point[0], 1.1, 29)
		label.font_size = 32
		label.pixel_size = 0.035
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.modulate = Color("fff2cf")
		label.outline_modulate = Color("365f57")
		label.outline_size = 10
		scenery.add_child(label)

func _tree(point: Vector3) -> void:
	_cylinder(0.2, 2.1, point + Vector3(0, 1.2, 0), Color("8d7657"))
	var canopy := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 1.4
	sphere.height = 3.0
	sphere.radial_segments = 8
	sphere.rings = 4
	canopy.mesh = sphere
	canopy.position = point + Vector3(0, 3.0, 0)
	canopy.material_override = _material(Color("718e68"))
	scenery.add_child(canopy)

func _boat(point: Vector3) -> void:
	_box(Vector3(2.5, 0.7, 5.8), point + Vector3(0, 0.1, 0), Color("455f5d"))
	_box(Vector3(2.0, 0.4, 4.8), point + Vector3(0, 0.65, 0), Color("ece0bc"))
	_box(Vector3(1.5, 1.2, 1.8), point + Vector3(0, 1.4, 0.5), Color("c6d0bc"))
	_box(Vector3(0.35, 1.3, 0.35), point + Vector3(0, 2.3, 0.5), Color("9f7059"))

func _box(dimensions: Vector3, location: Vector3, color: Color) -> void:
	var instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	instance.mesh = mesh
	instance.position = location
	instance.material_override = _material(color)
	scenery.add_child(instance)

func _cylinder(radius: float, height: float, location: Vector3, color: Color) -> void:
	var instance := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 12
	instance.mesh = mesh
	instance.position = location
	instance.material_override = _material(color)
	scenery.add_child(instance)

func _material(color: Color) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = color
	result.roughness = 1.0
	return result
