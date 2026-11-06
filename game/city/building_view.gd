extends Node3D

var data: Dictionary
var highlight: MeshInstance3D
var caption: Label3D

func configure(building_data: Dictionary) -> void:
	data = building_data
	name = data.id
	var p: Array = data.position
	position = Vector3(p[0], p[1], p[2])
	var dimensions: Array = data.size
	var w: float = dimensions[0]
	var h: float = dimensions[1]
	var d: float = dimensions[2]
	var color := Color(str(data.color))
	highlight = box(Vector3(w + 1.5, 0.18, d + 1.5), Vector3(0, 0.25, 0), Color("e6bc61"))
	highlight.visible = false
	box(Vector3(w + 0.4, 0.4, d + 0.4), Vector3(0, 0.3, 0), Color("e0d4b9"))
	box(Vector3(w, h, d), Vector3(0, h / 2 + 0.5, 0), color)
	var roof := MeshInstance3D.new()
	var prism := PrismMesh.new()
	prism.size = Vector3(w + 0.7, 1.4, d + 0.8)
	roof.mesh = prism
	roof.position.y = h + 1.1
	roof.material_override = material(Color("986953") if data.type != "warehouse" else Color("6f817b"))
	add_child(roof)
	var floors := maxi(1, int(h / 2.3))
	for floor_index in range(floors):
		var y := 1.8 + floor_index * 2.2
		for column in range(maxi(2, int(w / 2))):
			var x := -w / 2 + 1.0 + column * 2.0
			box(Vector3(0.8, 1.1, 0.12), Vector3(x, y, d / 2 + 0.06), Color("425f5c"))
			box(Vector3(0.95, 0.12, 0.23), Vector3(x, y - 0.6, d / 2 + 0.12), Color("e9dfc8"))
		for column in range(maxi(1, int(d / 2))):
			box(Vector3(0.12, 1.1, 0.8), Vector3(w / 2 + 0.06, y, -d / 2 + 1.0 + column * 2.0), Color("425f5c"))
	box(Vector3(1.0, 1.8, 0.16), Vector3(0, 1.35, d / 2 + 0.1), Color("745b45"))
	if data.type == "cafe":
		box(Vector3(w + 0.3, 0.18, 2.0), Vector3(0, 2.7, d / 2 + 0.8), Color("466f65"))
		for x in [-w / 3, w / 3]:
			box(Vector3(0.15, 2.6, 0.15), Vector3(x, 1.55, d / 2 + 1.5), Color("6a8069"))
	elif data.type == "government":
		for x in [-w / 3, w / 3]:
			box(Vector3(0.55, 3.8, 0.7), Vector3(x, 2.4, d / 2 + 0.5), Color("eee5d0"))
		box(Vector3(5.0, 0.3, 1.8), Vector3(0, 0.5, d / 2 + 0.9), Color("c3b89c"))
	elif data.type == "warehouse":
		box(Vector3(w / 2, 2.8, 0.2), Vector3(0, 1.9, d / 2 + 0.12), Color("64726b"))
	var body := StaticBody3D.new()
	body.set_meta("building_id", str(data.id))
	var shape := CollisionShape3D.new()
	var bounds := BoxShape3D.new()
	bounds.size = Vector3(w, h + 1.4, d)
	shape.shape = bounds
	shape.position.y = (h + 1.4) / 2 + 0.4
	body.add_child(shape)
	add_child(body)
	caption = Label3D.new()
	caption.text = data.name
	caption.position.y = h + 3.5
	caption.font_size = 38
	caption.pixel_size = 0.025
	caption.modulate = Color("fff3d5")
	caption.outline_size = 9
	caption.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	caption.no_depth_test = true
	caption.visible = false
	add_child(caption)

func set_selected(selected: bool) -> void:
	highlight.visible = selected
	caption.visible = selected

func box(dimensions: Vector3, location: Vector3, color: Color) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	instance.mesh = mesh
	instance.position = location
	instance.material_override = material(color)
	add_child(instance)
	return instance

func material(color: Color) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = color
	result.roughness = 1.0
	return result
