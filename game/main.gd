extends Node3D

@onready var city = $City
@onready var hud = $HUD

func _ready() -> void:
	var city_data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://content/city.json"))
	city.configure(city_data)
	hud.configure(city_data)
	city.building_selected.connect(hud.show_building)
	hud.district_requested.connect(func(district_id: String):
		for district in city_data.districts:
			if district.id == district_id:
				var center: Array = district.center
				city.camera_rig.focus_on(Vector3(center[0], center[1], center[2]))
	)
