extends Node3D
## Kaveh Lane: an outdoor neighborhood, restored one pool of light at a time.

const GraffitiWall := preload("res://scenes/graffiti_wall.tscn")
const PersianFont := preload("res://assets/fonts/vazirmatn/Vazirmatn.ttf")
const BRICK := Color("a57559")
const PLASTER := Color("c3aa88")
const TEAL := Color("287f81")
const WOOD := Color("50372e")
const POWER_POINTS := [Vector3(-11, 0, 7), Vector3(11, 0, -5), Vector3(-9, 0, -17)]
var game: Node3D
var celebration := false
var district_lights: Array[OmniLight3D] = []
var district_windows: Array[MeshInstance3D] = []
var festoon_bulbs: Array[MeshInstance3D] = []
var neighbors: Array[Node3D] = []
var gathering: Node3D
var gathering_light: OmniLight3D
var elapsed := 0.0

func _ready() -> void:
	build_sky()
	PoofShapes.box(self, Vector3(0, -0.3, 0), Vector3(32, 0.6, 48), Color("71675f"), true)
	for x in [-13.7, 13.7]:
		PoofShapes.box(self, Vector3(x, 0.025, 0), Vector3(3.5, 0.05, 47.8), Color("b7a58a"))
	for z in range(-23, 24, 2):
		PoofShapes.box(self, Vector3(0, 0.006, z), Vector3(31, 0.01, 0.025), Color("8f8170"))
	for x in range(-14, 15, 2):
		PoofShapes.box(self, Vector3(x, 0.007, 0), Vector3(0.022, 0.01, 48), Color("8f8170"))
	for side in [-1, 1]:
		for i in range(6):
			build_home(side, -20.0 + i * 8.0, i)
	build_end_wall(-24.0)
	build_end_wall(24.0)
	build_fountain()
	for at in [Vector3(-4, 0, 10), Vector3(4, 0, 7), Vector3(-5, 0, -5), Vector3(5, 0, -12)]:
		planter(at)
	# These small trees frame the street without covering its walkable lanes.
	for at in [Vector3(-13.6, 0, 2), Vector3(13.6, 0, -12), Vector3(-13.6, 0, -21)]:
		tree(at)
	shop(-1, 5.0, "نان", Color("9d493b"))
	shop(1, -11.0, "شاهنامه", TEAL)
	banner(Vector3(0, 4.6, -23.3))
	var street_name := persian(self, Vector3(0, 3.2, -23.25), "کوچهٔ کاوه", Color("f0dbab"), 62)
	street_name.pixel_size = 0.012
	for data in [Vector3(-15.39, 0.15, 15), Vector3(15.39, 0.15, -1)]:
		var wall := GraffitiWall.instantiate()
		wall.position = data
		wall.rotation_degrees.y = 90 if data.x < 0 else -90
		add_child(wall)
	for i in range(3):
		power_box(POWER_POINTS[i], i)
	build_gathering()
	string_lights(-14.0)
	string_lights(8.0)
	string_lights(19.0)

func build_sky() -> void:
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color("172944")
	sky_material.sky_horizon_color = Color("9d7781")
	sky_material.ground_bottom_color = Color("292634")
	sky_material.ground_horizon_color = Color("9d7781")
	sky_material.sun_angle_max = 12.0
	var sky := Sky.new()
	sky.sky_material = sky_material
	var settings := Environment.new()
	settings.background_mode = Environment.BG_SKY
	settings.sky = sky
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color = Color("b4c6de")
	settings.ambient_light_energy = 0.28
	settings.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var environment := WorldEnvironment.new()
	environment.environment = settings
	add_child(environment)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-22, -32, 0)
	sun.light_color = Color("ffd0a0")
	sun.light_energy = 0.32
	sun.shadow_enabled = true
	sun.shadow_bias = 0.08
	sun.shadow_normal_bias = 2.0
	sun.directional_shadow_max_distance = 65.0
	add_child(sun)
	# Distant silhouettes beyond the enclosed playable neighborhood.
	for i in range(9):
		var ridge := MeshInstance3D.new()
		var peak := PrismMesh.new()
		peak.size = Vector3(24, 14 + (i % 3) * 7, 12)
		ridge.mesh = peak
		ridge.material_override = PoofShapes.material(Color("565c78"))
		ridge.position = Vector3(-80 + i * 20, 3, -80 - (i % 2) * 8)
		add_child(ridge)

func build_home(side: int, z: float, index: int) -> void:
	var height := 7.5 + (index % 3) * 1.2
	var facade := BRICK if index % 2 == 0 else PLASTER
	PoofShapes.box(self, Vector3(side * 18.0, height / 2.0, z), Vector3(5, height, 8), facade, true)
	PoofShapes.box(self, Vector3(side * 15.4, 0.4, z), Vector3(0.15, 0.8, 8), Color("766856"))
	PoofShapes.box(self, Vector3(side * 15.35, height, z), Vector3(0.4, 0.28, 8.15), PLASTER)
	for row in range(1, 14):
		var y := row * 0.5
		PoofShapes.box(self, Vector3(side * 15.485, y, z), Vector3(0.025, 0.018, 7.9), facade.darkened(0.12))
	# Every facade is assembled locally, so windows face into the street.
	var face := Node3D.new()
	face.position = Vector3(side * 15.35, 0, z)
	face.rotation_degrees.y = -side * 90.0
	add_child(face)
	PoofShapes.box(face, Vector3(0, 1.25, 0.04), Vector3(1.5, 2.5, 0.12), WOOD)
	for offset in [-0.38, 0.38]:
		PoofShapes.box(face, Vector3(offset, 1.35, 0.13), Vector3(0.56, 1.9, 0.05), WOOD.lightened(0.1))
	PoofShapes.box(face, Vector3(0.32, 1.2, 0.18), Vector3(0.04, 0.17, 0.07), Color("c0a064"))
	arch(face, Vector3(0, 2.5, 0), 0.85)
	for x in [-2.3, 2.3]:
		PoofShapes.box(face, Vector3(x, 4.7, 0.05), Vector3(1.65, 2.3, 0.14), TEAL.darkened(0.3))
		var pane := PoofShapes.box(face, Vector3(x, 4.7, 0.14), Vector3(1.4, 2.05, 0.06), Color("384554"))
		district_windows.append(pane)
		PoofShapes.box(face, Vector3(x, 4.7, 0.2), Vector3(0.075, 2.1, 0.08), WOOD)
		PoofShapes.box(face, Vector3(x, 4.7, 0.2), Vector3(1.5, 0.07, 0.08), WOOD)
		PoofShapes.box(face, Vector3(x, 3.5, 0.35), Vector3(1.95, 0.18, 0.7), PLASTER)
		arch(face, Vector3(x, 5.85, 0.05), 0.88)
	if index % 2 == 0:
		PoofShapes.box(face, Vector3(0, 3.35, 0.7), Vector3(4.4, 0.18, 1.5), PLASTER)
		PoofShapes.box(face, Vector3(0, 4.15, 1.38), Vector3(4.4, 0.06, 0.06), WOOD)
		for x in range(-10, 11):
			PoofShapes.box(face, Vector3(x * 0.2, 3.77, 1.38), Vector3(0.035, 0.76, 0.035), WOOD)
	var light := lamp(Vector3(side * 14.8, 2.85, z + 1.7), Color("ffc583"), 0.15, 6.5)
	district_lights.append(light)

func arch(parent: Node3D, at: Vector3, radius: float) -> void:
	for i in range(11):
		var angle := float(i) / 10.0 * PI
		var stone := PoofShapes.box(parent, at + Vector3(cos(angle) * radius, sin(angle) * radius, 0.1), Vector3(0.25, 0.28, 0.22), PLASTER.lightened(0.14))
		stone.rotation.z = angle - PI / 2.0

func build_end_wall(z: float) -> void:
	for side in [-1, 1]:
		PoofShapes.box(self, Vector3(side * 10, 3, z), Vector3(12, 6, 1), BRICK, true)
	PoofShapes.box(self, Vector3(0, 2, z), Vector3(8, 4, 0.6), WOOD, true)
	PoofShapes.box(self, Vector3(0, 5.7, z), Vector3(8, 3.4, 1), PLASTER, true)
	var facing := Node3D.new()
	facing.position = Vector3(0, 0, z + (0.6 if z < 0 else -0.6))
	facing.rotation.y = 0 if z < 0 else PI
	add_child(facing)
	arch(facing, Vector3(0, 2.9, 0), 2.0)
	for x in [-3.1, 3.1]:
		PoofShapes.box(facing, Vector3(x, 2.2, 0), Vector3(0.2, 4.4, 0.2), TEAL)
		lamp(facing.position + Vector3(x, 3, 0), Color("ffd0a0"), 0.7, 5)

func build_fountain() -> void:
	PoofShapes.box(self, Vector3(0, 0.4, 0), Vector3(5, 0.8, 5), TEAL, true)
	PoofShapes.box(self, Vector3(0, 0.815, 0), Vector3(4.55, 0.03, 4.55), Color("386675"))
	PoofShapes.box(self, Vector3(0, 1.3, 0), Vector3(0.7, 1.0, 0.7), PLASTER, true)
	for side in [-1, 1]:
		PoofShapes.box(self, Vector3(side * 2.4, 0.88, 0), Vector3(0.2, 0.18, 5), PLASTER)
		PoofShapes.box(self, Vector3(0, 0.88, side * 2.4), Vector3(5, 0.18, 0.2), PLASTER)

func planter(at: Vector3) -> void:
	PoofShapes.box(self, at + Vector3(0, 0.65, 0), Vector3(3, 1.3, 1.4), BRICK, true)
	PoofShapes.box(self, at + Vector3(0, 1.31, 0), Vector3(2.8, 0.05, 1.2), Color("44372a"))
	for i in range(5):
		rounded(self, at + Vector3(-1.1 + i * 0.55, 1.45, 0), Vector3(0.65, 0.55, 0.85), Color("577256"))

func tree(at: Vector3) -> void:
	PoofShapes.box(self, at + Vector3(0, 0.35, 0), Vector3(1.3, 0.7, 1.3), BRICK, true)
	PoofShapes.box(self, at + Vector3(0, 1.7, 0), Vector3(0.23, 3.4, 0.23), WOOD, true)
	for i in range(3):
		rounded(self, at + Vector3(sin(i * 2.1) * 0.5, 3.6 + i * 0.4, cos(i * 2.1) * 0.4), Vector3(2.4, 2.1, 2.2), Color("455f4a"))

func rounded(parent: Node3D, at: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var result := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.5
	sphere.height = 1.0
	sphere.radial_segments = 12
	sphere.rings = 6
	result.mesh = sphere
	result.position = at
	result.scale = size
	result.material_override = PoofShapes.material(color)
	parent.add_child(result)
	return result

func shop(side: int, z: float, title: String, cloth: Color) -> void:
	var root := Node3D.new()
	root.position = Vector3(side * 15.1, 0, z)
	root.rotation_degrees.y = -side * 90.0
	add_child(root)
	PoofShapes.box(root, Vector3(0, 1.6, 0), Vector3(4.4, 3.2, 0.3), WOOD)
	PoofShapes.box(root, Vector3(0, 1.6, 0.18), Vector3(3.9, 2.8, 0.05), Color("252d37"))
	for y in [0.6, 1.35, 2.1]:
		PoofShapes.box(root, Vector3(0, y, 0.33), Vector3(3.8, 0.08, 0.6), PLASTER)
		for i in range(7):
			if side < 0:
				rounded(root, Vector3(-1.5 + i * 0.48, y + 0.15, 0.48), Vector3(0.33, 0.11, 0.45), Color("d7a55e"))
			else:
				PoofShapes.box(root, Vector3(-1.5 + i * 0.48, y + 0.27, 0.38), Vector3(0.3, 0.46, 0.2), [TEAL, Color("943e3d"), Color("c29855")][i % 3])
	PoofShapes.box(root, Vector3(0, 3.5, 0.3), Vector3(4.8, 0.7, 0.3), cloth)
	persian(root, Vector3(0, 3.48, 0.48), title, Color("ffdfad"), 52)
	for i in range(10):
		var awning := PoofShapes.box(root, Vector3(-2.25 + i * 0.5, 3.0, 0.9), Vector3(0.5, 0.1, 1.8), cloth if i % 2 == 0 else PLASTER)
		awning.rotation.x = 0.13

func banner(at: Vector3) -> void:
	# An original banner inspired by Kaveh, not a historical reconstruction.
	PoofShapes.box(self, at, Vector3(1.7, 2.1, 0.05), Color("6a384d"))
	PoofShapes.box(self, at + Vector3(0, 1.15, 0), Vector3(2.0, 0.08, 0.1), WOOD)
	for angle in [0.0, PI / 2.0]:
		var motif := PoofShapes.box(self, at + Vector3(0, 0.1, 0.045), Vector3(0.14, 1.05, 0.035), Color("e5b864"))
		motif.rotation.z = angle + PI / 4.0
	persian(self, at + Vector3(0, -0.65, 0.06), "کاوه", Color("f5db9c"), 36)

func persian(parent: Node3D, at: Vector3, words: String, color: Color, size: int) -> Label3D:
	var label := PoofShapes.label(parent, at, words, color, size)
	label.font = PersianFont
	label.language = "fa"
	label.text_direction = TextServer.DIRECTION_RTL
	label.outline_size = 2
	label.double_sided = false
	return label

func lamp(at: Vector3, color: Color, energy: float, reach: float) -> OmniLight3D:
	PoofShapes.box(self, at, Vector3(0.18, 0.3, 0.18), color, false, 0.5)
	var light := OmniLight3D.new()
	light.position = at
	light.light_color = color
	light.light_energy = energy
	light.omni_range = reach
	add_child(light)
	return light

func power_box(at: Vector3, index: int) -> void:
	var root := Node3D.new()
	root.position = at
	add_child(root)
	PoofShapes.box(root, Vector3(0, 0.7, 0), Vector3(0.9, 1.4, 0.45), Color("44565b"), true)
	var screen := PoofShapes.box(root, Vector3(0, 1.0, 0.25), Vector3(0.62, 0.45, 0.04), Color("f0b86c"), false, 0.8)
	var caption := PoofShapes.label(root, Vector3(0, 2.1, 0), ["01 / BREAD SHOP", "02 / SHAHNAMEH", "03 / NORTH GATE"][index], Color("f0b86c"), 25)
	caption.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	caption.pixel_size = 0.008
	game.relays.append({"node": root, "screen": screen, "label": caption, "online": false})

func build_gathering() -> void:
	gathering = Node3D.new()
	gathering.position = Vector3(0, 0, 20)
	add_child(gathering)
	PoofShapes.box(gathering, Vector3(0, 0.02, 0), Vector3(7, 0.04, 3.5), Color("823e43"))
	PoofShapes.box(gathering, Vector3(0, 0.045, 0), Vector3(6.6, 0.02, 3.1), Color("bf875e"))
	PoofShapes.box(gathering, Vector3(0, 0.055, 0), Vector3(5.9, 0.01, 2.4), Color("823e43"))
	for x in [-2.5, 2.5]:
		PoofShapes.box(gathering, Vector3(x, 0.2, 0), Vector3(1.0, 0.4, 0.75), TEAL)
	# Finish here, returning to the friends you started beside.
	var speaker := Node3D.new()
	speaker.position = Vector3(-4, 0, 19)
	add_child(speaker)
	PoofShapes.box(speaker, Vector3(0, 0.8, 0), Vector3(0.75, 1.6, 0.55), Color("292936"), true)
	game.broadcast_screen = PoofShapes.box(speaker, Vector3(0, 1.1, 0.3), Vector3(0.45, 0.3, 0.04), Color("785e59"), false, 0.3)
	game.broadcast = speaker
	var caption := persian(speaker, Vector3(0, 2.2, 0), "کنار هم", Color("f0dbab"), 40)
	caption.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	gathering_light = lamp(Vector3(0, 4, 20), Color("ffd299"), 0.2, 11)
	for i in range(4):
		var person := Node3D.new()
		person.position = Vector3(-2.7 + i * 1.8, 0, 1)
		person.set_meta("name", ["آوا", "بهار", "نیما", "کیان"][i])
		person.set_meta("line", ["چراغ‌ها را روشن کن. ما همین‌جا می‌مانیم.", "نترس. کنار هم هستیم.", "این کوچه خانهٔ ماست.", "امشب را از ما نمی‌گیرند."][i])
		gathering.add_child(person)
		rounded(person, Vector3(0, 1.48, 0), Vector3(0.3, 0.38, 0.3), Color("b88869"))
		rounded(person, Vector3(0, 1.0, 0), Vector3(0.47, 0.7, 0.3), [TEAL, Color("b86b59"), Color("c9a259"), Color("707db0")][i])
		for side in [-1, 1]:
			rounded(person, Vector3(side * 0.12, 0.37, 0), Vector3(0.16, 0.75, 0.18), Color("354352"))
			rounded(person, Vector3(side * 0.29, 0.98, 0), Vector3(0.14, 0.64, 0.14), PLASTER)
		neighbors.append(person)
	var words := persian(gathering, Vector3(0, 2.8, 1.0), "زن، زندگی، آزادی", Color("f4dba9"), 34)
	words.rotation.y = PI

func string_lights(z: float) -> void:
	for i in range(19):
		var x := -14.4 + i * 1.6
		var sag := 4.4 + absf(x) * 0.065
		PoofShapes.box(self, Vector3(x, sag, z), Vector3(1.65, 0.025, 0.025), WOOD)
		var bulb := rounded(self, Vector3(x, sag - 0.15, z), Vector3.ONE * 0.13, Color("7b705f"))
		festoon_bulbs.append(bulb)

func restore_district(index: int) -> void:
	for i in range(district_lights.size()):
		if i % 3 == index:
			district_lights[i].light_energy = 1.4
	for i in range(district_windows.size()):
		if i % 3 == index:
			district_windows[i].material_override = PoofShapes.material(Color("edbe80"), 0.5)

func celebrate() -> void:
	celebration = true
	gathering_light.light_energy = 2.3
	for bulb in festoon_bulbs:
		bulb.material_override = PoofShapes.material(Color("ffcf83"), 1.5)
	for child in get_children():
		if child is CharacterBody3D:
			child.set_physics_process(false)
			child.hide()
			child.collision_layer = 0
			child.collision_mask = 0

func _process(delta: float) -> void:
	if not celebration or not game.active:
		return
	elapsed += delta
	for i in range(neighbors.size()):
		neighbors[i].rotation.z = sin(elapsed * 3.0 + i) * 0.09
		neighbors[i].position.y = absf(sin(elapsed * 3.0 + i)) * 0.055
