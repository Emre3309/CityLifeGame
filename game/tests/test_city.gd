extends RefCounted

func run() -> Array[String]:
	var failures: Array[String] = []
	failures.append_array(test_city_has_three_districts_and_unique_building_ids())
	failures.append_array(test_camera_selection_guards())
	failures.append_array(test_building_selection_updates_panel_and_reconfigure_clears_selection())
	return failures

# Catches missing districts, broken references, duplicate selectable identities and missing venues.
func test_city_has_three_districts_and_unique_building_ids() -> Array[String]:
	var failures: Array[String] = []
	if not FileAccess.file_exists("res://content/city.json"):
		return ["test_city_has_three_districts_and_unique_building_ids: city content missing"]
	var data = JSON.parse_string(FileAccess.get_file_as_string("res://content/city.json"))
	if not data is Dictionary:
		return ["city content must be a Dictionary"]
	var district_ids: Array[String] = []
	for district in data.get("districts", []):
		district_ids.append(district.id)
	district_ids.sort()
	if district_ids != ["carsi", "cinar", "liman"]:
		failures.append("city must contain exactly carsi, cinar, liman")
	var ids: Dictionary = {}
	var types: Dictionary = {}
	for building in data.get("buildings", []):
		if str(building.get("id", "")).is_empty() or ids.has(building.id):
			failures.append("every building needs a unique nonempty id")
		ids[building.id] = true
		types[building.get("type", "")] = true
		if not district_ids.has(building.get("district_id", "")):
			failures.append("building references unknown district")
	for required in ["home", "cafe", "school", "police", "government", "warehouse"]:
		if not types.has(required):
			failures.append("missing selectable building type: " + required)
	return failures

# Catches UI click-through, drag-release selection and off-by-one zoom/drag bounds.
func test_camera_selection_guards() -> Array[String]:
	if not ResourceLoader.exists("res://city/camera_rig.gd"):
		return ["test_camera_selection_guards: CameraRig interface missing"]
	var rig = load("res://city/camera_rig.gd").new()
	var failures: Array[String] = []
	for row in [[true, 0.0, false], [false, 6.1, false], [false, 6.0, true], [false, 0.0, true]]:
		if rig.can_select(row[0], row[1]) != row[2]:
			failures.append("selection must reject UI and drags exceeding six pixels")
	for row in [[1.0, 15.0], [15.0, 15.0], [42.0, 42.0], [90.0, 90.0], [120.0, 90.0]]:
		if not is_equal_approx(rig.clamp_zoom(row[0]), row[1]):
			failures.append("orthographic zoom must clamp to 15–90")
	rig.free()
	return failures

# Catches a dropped selection signal, stale highlights/data after rebuilding and invented panel labels.
func test_building_selection_updates_panel_and_reconfigure_clears_selection() -> Array[String]:
	if not ResourceLoader.exists("res://city/city.tscn") or not ResourceLoader.exists("res://ui/hud.tscn"):
		return ["test_building_selection: city and HUD scenes missing"]
	var city = load("res://city/city.tscn").instantiate()
	var hud = load("res://ui/hud.tscn").instantiate()
	var tree := Engine.get_main_loop() as SceneTree
	tree.root.add_child(city)
	tree.root.add_child(hud)
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://content/city.json"))
	city.configure(data)
	hud.configure(data)
	city.building_selected.connect(hud.show_building)
	var failures: Array[String] = []
	city.select_building("carsi_cafe")
	if city.selected_building_id != "carsi_cafe" or hud.selected_building_id != "carsi_cafe":
		failures.append("selection must reach both highlight and information panel")
	if hud.detail_title.text != "Sahil Kahvesi" or hud.district_label.text != "Çarşı Mahallesi":
		failures.append("information panel must use selected content names")
	city.select_building("unknown")
	if city.selected_building_id != "carsi_cafe":
		failures.append("unknown selection must not replace a valid selection")
	city.configure(data)
	if not city.selected_building_id.is_empty() or not hud.selected_building_id.is_empty():
		failures.append("reconfiguring city must clear selection and panel")
	if city.get_node("Buildings").get_child_count() != data.buildings.size():
		failures.append("reconfigure must replace meshes rather than duplicate buildings")
	city.free()
	hud.free()
	return failures
