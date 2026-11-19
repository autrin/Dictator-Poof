extends Node3D
## Chapter state owns story progress; props, café policy and card rules are separate.
const Props := preload("res://scripts/domestic_props.gd")
const Person := preload("res://scripts/person_visual.gd")
const Cafe := preload("res://scripts/book_cafe.gd")
const DayRules := preload("res://scripts/day_rules.gd")
const Life := preload("res://scripts/nowruz_life.gd")
const Decor := preload("res://scripts/home_decor.gd")
const Interiors := preload("res://scripts/family_interiors.gd")
const Front := preload("res://scripts/house_front.gd")
const Hokm := preload("res://scripts/hokm.gd")
const Pastries := preload("res://scripts/pastry_art.gd")
const Bakery := preload("res://scenes/pastry_shop.tscn")
const SUNSET_MINUTE := 18 * 60 + 20
const STEPS := ["wake", "blinds", "tv", "family", "car", "stop", "scarf", "pastry", "grandma", "sal", "help", "lunch", "cards", "home", "visits", "done", "lane"]
var game: Node3D
var rules := DayRules.new()
var stage := 0
var targets: Dictionary = {}
var blinds: Node3D
var sister: Node3D
var family: Array[Node3D] = []
var relatives: Array[Node3D] = []
var officer: Node3D
var scarf: MeshInstance3D
var pastry_box: Node3D
var pastry_lid: Node3D
var bakery: Node3D
var car: Node3D
var cafe: Node3D
var sun: DirectionalLight3D
var environment: WorldEnvironment
var tv_screen: Label3D
var marker: Label3D
var cards: Control
var elapsed := 0.0
var bird_left := 4.0
var labels: Array[Dictionary] = []
var serving: Node3D
var transition_left := 0.0
var life: Node
var speaker: Label3D
var leaving := false

func _ready() -> void:
	build_light()
	PoofShapes.box(self, Vector3(0, -0.21, -20), Vector3(44, 0.4, 62), Color("c1b397"), true)
	for x in [-22.0, 22.0]:
		PoofShapes.box(self, Vector3(x, 1.5, -20), Vector3(0.25, 3, 62), Color("b49c7d"), true)
	for z in [-51.0, 11.0]:
		PoofShapes.box(self, Vector3(0, 1.5, z), Vector3(44, 3, 0.25), Color("b49c7d"), true)
	build_home(Vector3.ZERO, false)
	build_home(Vector3(0, 0, -44), true)
	build_garden()
	build_bakery()
	build_car()
	build_lane_gate()
	cafe = Cafe.new()
	cafe.game = game
	cafe.rules = rules
	cafe.position = Vector3(13, 0, -18)
	cafe.rotation.y = -PI / 2
	add_child(cafe)
	sister = person(Vector3(2, 0, 1), Color("427b88"), 1)
	scarf = Person.sphere(sister.get_node("Gaze"), "Covering scarf", Vector3(0, 0.30, 0.035), Vector3(0.32, 0.21, 0.31), Color("bd8393"))
	scarf.hide()
	Person.remember_pose(sister)
	family.append(sister)
	family.append(person(Vector3(3.5, 0, 1.5), Color("ab6652"), 3))
	family.append(person(Vector3(4.7, 0, 0.8), Color("75644f"), 0))
	var jackets := [Color("746b75"), Color("527572"), Color("a68163"), Color("716855"), Color("9c654c"), Color("637588")]
	for i in range(6):
		var hair := Color("998c80") if i in [0, 3] else Color("473633")
		var relative := person(Vector3(-1 + (i % 3), 0, -42.5 + (-1.0 if i < 3 else 1.0)), jackets[i], i % 5, hair)
		if i == 3:
			Person.reading_glasses(relative.get_node("Gaze"))
		relative.rotation.y = PI if i < 3 else 0
		relatives.append(relative)
		Props.chair(self, relative.position, relative.rotation.y)
		Person.sit(relative)
	life = Life.new()
	life.chapter = self
	add_child(life)
	speaker = label_at(officer, Vector3(0, 2.2, 0), "patrol_speaker")
	speaker.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	speaker.pixel_size = 0.003
	speaker.hide()
	# All chapter actions point to real, reachable objects.
	target("wake", Vector3(-4.7, 0, 3))
	target("blinds", Vector3(-3.6, 0, -3.9))
	target("tv", Vector3(5.8, 0, -1.4))
	target("family", Vector3(2, 0, 1))
	target("car", Vector3(7.1, 0, -7.3))
	target("stop", Vector3(-7.3, 0, -15))
	target("scarf", Vector3(-7.3, 0, -15))
	target("pastry", Vector3(-10, 0, -16))
	target("grandma", Vector3(-1.9, 0, -17.3))
	target("sal", Vector3(0, 0, -46))
	target("gift", Vector3(-2.77, 0, -47.65))
	targets["help"] = life.cook
	target("lunch", Vector3(2, 0, -42.5))
	target("cards", Vector3(-2.7, 0, -43.5))
	target("home", Vector3(7.1, 0, -34.3))
	target("visits", Vector3(7.1, 0, -7.3))
	target("done", Vector3(21.2, 0, -29))
	target("lane", Vector3(21.2, 0, -29))
	for key in ["family", "stop", "scarf"]:
		targets[key].queue_free()
		targets[key] = sister
	marker = label_at(self, Vector3.ZERO, "action_wake")
	marker.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	marker.pixel_size = 0.005
	marker.no_depth_test = false
	apply_language()
	var texture := Props.surface_texture()
	for mesh in find_children("*", "MeshInstance3D", true, false):
		if mesh.mesh is BoxMesh and mesh.mesh.size.length() > 5:
			if mesh.get_parent().has_meta("house_shell"):
				continue
			var material := mesh.material_override as StandardMaterial3D
			if material.albedo_texture != null:
				continue
			material.albedo_texture = texture
			material.uv1_triplanar = true
			material.uv1_world_triplanar = true
			material.uv1_scale = Vector3.ONE * 0.8

func build_light() -> void:
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color("72a6c8")
	sky_mat.sky_horizon_color = Color("eed8ae")
	var sky := Sky.new()
	sky.sky_material = sky_mat
	environment = WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_SKY
	environment.environment.sky = sky
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color("d4dce4")
	environment.environment.ambient_light_energy = 0.3
	environment.environment.tonemap_mode = Environment.TONE_MAPPER_ACES
	add_child(environment)
	sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-38, -28, 0)
	sun.light_color = Color("fff3df")
	sun.light_energy = 0.55
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 80
	add_child(sun)

func build_home(at: Vector3, grandparents: bool) -> void:
	var room := Node3D.new()
	room.name = "Grandparents home" if grandparents else "Family home"
	room.set_meta("house_shell", true)
	add_child(room)
	room.position = at
	# The courtyard slab already supports the capsule through both doorways.
	var floorboards := PoofShapes.box(room, Vector3(0, -0.02, 0), Vector3(14, 0.04, 10), Color("d3b594") if grandparents else Color("e4cfaf"))
	floorboards.material_override.albedo_texture = preload("res://assets/textures/interiors/wood_blocks.svg")
	floorboards.material_override.uv1_scale = Vector3(15, 9, 1)
	for x in [-7.0, 7.0]:
		PoofShapes.box(room, Vector3(x, 1.55, 0), Vector3(0.2, 3.1, 10), Color("e6d7bb"), true)
	if not grandparents:
		PoofShapes.box(room, Vector3(0, 1.55, 5), Vector3(14, 3.1, 0.2), Color("e6d7bb"), true)
	# A low sill and lintel frame the garden; a full-height opening is the door.
	PoofShapes.box(room, Vector3(-2.5, 0.42, -5), Vector3(9, 0.84, 0.2), Color("d8c6a4"), true)
	PoofShapes.box(room, Vector3(-2.5, 2.7, -5), Vector3(9, 0.8, 0.2), Color("e6d7bb"), true)
	PoofShapes.box(room, Vector3(6, 1.55, -5), Vector3(2, 3.1, 0.2), Color("e6d7bb"), true)
	if grandparents:
		for x in [-6.7, -1.8, 1.9]:
			PoofShapes.box(room, Vector3(x, 1.6, -4.97), Vector3(0.09, 1.6, 0.14), Props.WOOD, true)
	PoofShapes.box(room, Vector3(0, 3.1, 0), Vector3(14.2, 0.16, 10.2), Color("efe1c4"), true)
	Decor.furnish(room, grandparents)
	Front.build(room, grandparents)
	Props.rug(room, Vector3(1, 0.035, 0), Vector2(6, 6))
	Props.haftseen(room, Vector3(0, 0, -2))
	var lamp := OmniLight3D.new()
	lamp.position = Vector3(0, 2.5, 0)
	lamp.omni_range = 10
	lamp.light_color = Color("ffe0aa")
	lamp.light_energy = 0.65
	room.add_child(lamp)
	if grandparents:
		# The street-facing south wall has a full-height doorway.
		Interiors.grandparents(room)
		PoofShapes.box(room, Vector3(-2.5, 0.42, 5), Vector3(9, 0.84, 0.2), Color("ded1b9"), true)
		PoofShapes.box(room, Vector3(-2.5, 2.71, 5), Vector3(9, 0.78, 0.2), Color("ded1b9"), true)
		PoofShapes.box(room, Vector3(6, 1.55, 5), Vector3(2, 3.1, 0.2), Color("e6d7bb"), true)
		Props.table(room, Vector3(0, 0, 1.5), Vector2(3, 1.3))
		var runner := PoofShapes.box(room, Vector3(0, 0.786, 1.5), Vector3(3.04, 0.009, 0.43), Color.WHITE)
		runner.material_override.albedo_texture = Interiors.WEAVE
		serving = Node3D.new()
		room.add_child(serving)
		for i in range(6):
			var dish := Vector3(-1 + (i % 3), 0.8, 1.2 + (i / 3) * 0.5)
			Props.round_shape(serving, dish, 0.24, 0.025, Props.CREAM)
			Props.round_shape(serving, dish + Vector3.UP * 0.014, 0.219, 0.004, Color("588181"))
			Props.round_shape(serving, dish + Vector3.UP * 0.018, 0.207, 0.005, Props.CREAM)
			Person.sphere(serving, "Herbed rice", dish + Vector3(-0.043, 0.054, 0), Vector3(0.27, 0.096, 0.29), Color("d4c897"))
			for j in range(9):
				var radius := 0.097 * sqrt(j / 9.0)
				var herb := dish + Vector3(-0.043 + radius * cos(j * 2.4), 0.101 - 0.013 * j / 9.0, radius * sin(j * 2.4))
				Person.sphere(serving, "Dill", herb, Vector3(0.026, 0.007, 0.011), Color("688052"))
			var fillet := Person.sphere(serving, "Fish", dish + Vector3(0.096, 0.049, 0.025), Vector3(0.113, 0.061, 0.24), Color("bc8350"))
			fillet.rotation.y = 0.20
			var lemon := Props.round_shape(serving, dish + Vector3(0.10, 0.037, -0.112), 0.052, 0.020, Color("e3b34e"))
			Props.round_shape(lemon, Vector3.UP * 0.011, 0.044, 0.004, Color("f1d491"))
		var yogurt := Props.round_shape(serving, Vector3(0.49, 0.83, 1.5), 0.15, 0.084, Color("427272"))
		yogurt.mesh.bottom_radius = 0.095
		Props.round_shape(yogurt, Vector3.UP * 0.042, 0.136, 0.004, Color("e8dfc5"))
		for x in [-0.51, 0.88]:
			Props.tea_glass(serving, Vector3(x, 0.80, 1.49))
		serving.hide()
		PoofShapes.box(room, Vector3(5.8, 0.45, 0), Vector3(1.3, 0.9, 2), Props.WOOD, true)
		var pot := Props.round_shape(room, Vector3(5.49, 1.03, 0), 0.30, 0.24, Color("99705a"))
		Props.round_shape(pot, Vector3.UP * 0.122, 0.279, 0.007, Color("bdc295"))
		for z in [-0.31, 0.31]:
			PoofShapes.box(pot, Vector3(0, 0.065, z), Vector3(0.16, 0.026, 0.089), Color("766054"))
		Props.table(room, Vector3(-2.7, 0, 0.5), Vector2(1.2, 0.9))
		for i in range(8):
			PoofShapes.box(room, Vector3(-3.1 + i * 0.1, 0.79, 0.5), Vector3(0.064, 0.008, 0.095), Color("823e43"))
		PoofShapes.box(room, Vector3(5.98, 1.66, 5.173), Vector3(1.38, 0.32, 0.044), Color("365d5a"))
		var house_sign := label_at(room, Vector3(5.98, 1.66, 5.201), "grandma_house")
		house_sign.pixel_size = 0.0017
		# Ajil and fruit set out beside the Haft-Seen.
		for i in range(12):
			Person.sphere(room, "Ajil", Vector3(0.5 + (i % 4) * 0.05, 0.85, -1.7 + (i / 4) * 0.04), Vector3(0.04, 0.035, 0.035), Color("ad8553"))
	else:
		Interiors.home(room)
		PoofShapes.box(room, Vector3(-4.7, 0.27, 3), Vector3(2.1, 0.54, 3.1), Props.WOOD, true)
		PoofShapes.box(room, Vector3(-4.7, 0.58, 3), Vector3(2, 0.12, 2.9), Color("c7d0bd"))
		PoofShapes.box(room, Vector3(-4.7, 0.69, 4), Vector3(1.25, 0.17, 0.48), Props.CREAM)
		blinds = Node3D.new()
		room.add_child(blinds)
		for i in range(10):
			PoofShapes.box(blinds, Vector3(-4.1, 0.93 + i * 0.14, -4.8), Vector3(4.8, 0.105, 0.055), Color("c49b70"))
		var television := Node3D.new()
		room.add_child(television)
		television.position = Vector3(6.8, 1.4, -1.4)
		television.rotation.y = -PI / 2
		PoofShapes.box(television, Vector3.ZERO, Vector3(2, 1.1, 0.1), Color("34383b"), true)
		tv_screen = label_at(television, Vector3(0, 0, 0.065), "tv_program")
		tv_screen.pixel_size = 0.003
		tv_screen.modulate = Color("f4ce92")

func build_garden() -> void:
	for x in [-7.5, 0.0]:
		PoofShapes.box(self, Vector3(x, 0.025, -10.5), Vector3(5, 0.025, 7), Color("768758"))
		garden_grass(Vector3(x, 0.04, -10.5))
	PoofShapes.box(self, Vector3(-4.5, 0.28, -14.1), Vector3(16, 0.56, 0.3), Color("a98269"), true)
	for i in range(3):
		var at := Vector3(-8.5 + i * 4.1, 0, -12.7)
		PoofShapes.box(self, at + Vector3(0, 1.1, 0), Vector3(0.22, 2.2, 0.22), Props.WOOD, true)
		Person.sphere(self, "Cypress", at + Vector3(0, 2.65, 0), Vector3(1.0, 4.2, 1.0), Color("344f3d"))
		for j in range(18):
			var angle := j * 2.4
			var y := 1.2 + j * 0.18
			var width := 0.35 * sin((y - 0.4) / 4.4 * PI)
			Person.sphere(self, "Cypress branch", at + Vector3(cos(angle) * width, y, sin(angle) * width), Vector3(0.45, 0.8, 0.45), Color("456449"))
		# Honeysuckle threads the low garden wall.
		for j in range(10):
			var vine := Vector3(-10 + i * 6 + j * 0.38, 0.7 + sin(j) * 0.16, -13.8)
			Person.sphere(self, "Honeysuckle", vine, Vector3(0.45, 0.3, 0.35), Color("5d7547"))
			Person.sphere(self, "Blossom", vine + Vector3(0, 0.1, 0.14), Vector3(0.07, 0.06, 0.1), Color("f0dfaa"))
	for at in [Vector3(-10, 0, -8), Vector3(0, 0, -8)]:
		PoofShapes.box(self, at + Vector3(0, 0.9, 0), Vector3(0.2, 1.8, 0.2), Props.WOOD, true)
		for j in range(7):
			Person.sphere(self, "Fruit tree", at + Vector3(sin(j * 2.4) * 0.65, 2 + sin(j) * 0.35, cos(j * 2.4) * 0.65), Vector3(1.2, 1.15, 1.1), Color("557445").lightened((j % 3) * 0.025))
		for i in range(9):
			Person.sphere(self, "Orange", at + Vector3(sin(i * 2.4) * 0.85, 1.9 + sin(i) * 0.5, cos(i * 2.4) * 0.85), Vector3.ONE * 0.15, Color("dfa04c"))
	for i in range(3):
		var bird := Person.sphere(self, "Garden bird", Vector3(-8.5 + i * 4.1, 4.7, -12.7), Vector3(0.16, 0.1, 0.25), Color("4e493f"))
		Person.sphere(bird, "Head", Vector3(0, 0.3, -0.4), Vector3(0.45, 0.7, 0.4), Color("534337"))
	Props.round_shape(self, Vector3(-4, 0.12, -10), 1.1, 0.24, Color("428c91"))
	Props.round_shape(self, Vector3(-4, 0.249, -10), 0.94, 0.01, Color("80b7b8"))

func garden_grass(at: Vector3) -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for point in [Vector3(-0.02, 0, 0), Vector3(0.02, 0, 0), Vector3(0.025, 0.16, 0.02)]:
		surface.add_vertex(point)
	surface.generate_normals()
	var grass := MultiMeshInstance3D.new()
	var instances := MultiMesh.new()
	instances.transform_format = MultiMesh.TRANSFORM_3D
	instances.use_colors = true
	instances.mesh = surface.commit()
	instances.instance_count = 750
	var rng := RandomNumberGenerator.new()
	rng.seed = 1403
	for i in range(instances.instance_count):
		var basis := Basis(Vector3.UP, rng.randf_range(0, TAU)).scaled(Vector3.ONE * rng.randf_range(0.5, 1.25))
		instances.set_instance_transform(i, Transform3D(basis, Vector3(rng.randf_range(-2.4, 2.4), 0, rng.randf_range(-3.4, 3.4))))
		instances.set_instance_color(i, Color("607649").lightened(rng.randf_range(0, 0.12)))
	grass.multimesh = instances
	var material := PoofShapes.material(Color.WHITE)
	material.vertex_color_use_as_albedo = true
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	grass.material_override = material
	grass.position = at
	add_child(grass)

func build_bakery() -> void:
	bakery = Bakery.instantiate()
	bakery.game = game
	bakery.position = Vector3(-11.5, 0, -16.55)
	add_child(bakery)
	bakery.wrapped.connect(collect_pastries)
	pastry_box = Pastries.box_base(self)
	pastry_lid = Pastries.lid(pastry_box)
	pastry_box.hide()

func collect_pastries() -> void:
	for i in range(bakery.packed_pieces.size()):
		var piece: Node3D = bakery.packed_pieces[i]
		piece.reparent(pastry_box, false)
		piece.position = Pastries.slot(i)
	pastry_box.reparent(sister, false)
	pastry_box.position = Vector3(0, 0.92, -0.3)
	pastry_box.show()
	bakery.gift.hide()
	game.player.camera.make_current()
	game.player.update_viewmodel()
	game.hud.hud.show()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	game.notify("line_pastry", 8)
	complete_step()

func set_out_pastries() -> void:
	pastry_box.reparent(self, false)
	# The tea table by the garden window has room beside its tray.
	pastry_box.position = targets.gift.position + Vector3.UP * 0.79
	pastry_lid.hide()

func build_car() -> void:
	car = Node3D.new()
	add_child(car)
	car.position = Vector3(5.5, 0, -9)
	car.name = "Family car"
	var body := AnimatableBody3D.new()
	body.name = "Car collider"
	body.sync_to_physics = false
	body.collision_layer = 1
	body.collision_mask = 0
	car.add_child(body)
	var collision := CollisionShape3D.new()
	var bounds := BoxShape3D.new()
	bounds.size = Vector3(1.75, 1.5, 3.7)
	collision.shape = bounds
	collision.position.y = 0.9
	body.add_child(collision)
	PoofShapes.box(car, Vector3(0, 0.58, 0), Vector3(1.75, 0.63, 3.7), Color("dfd9c7"))
	PoofShapes.box(car, Vector3(0, 1.62, 0.1), Vector3(1.65, 0.08, 2.1), Color("dfd9c7"))
	for x in [-0.78, 0.78]:
		for z in [-0.95, 0.15, 1.1]:
			PoofShapes.box(car, Vector3(x, 1.24, z), Vector3(0.06, 0.72, 0.06), Color("dfd9c7"))
		for z in [-0.4, 0.68]:
			PoofShapes.box(car, Vector3(x, 0.91, z), Vector3(0.06, 0.11, 0.93), Color("d4cbb7"))
	for z in [-0.98, 1.13]:
		var glass := PoofShapes.box(car, Vector3(0, 1.26, z), Vector3(1.5, 0.61, 0.015), Color(0.48, 0.67, 0.68, 0.16))
		glass.material_override.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	PoofShapes.box(car, Vector3(0, 0.99, -0.8), Vector3(1.4, 0.13, 0.3), Color("444b49"))
	var steering := MeshInstance3D.new()
	var ring := TorusMesh.new()
	ring.inner_radius = 0.14
	ring.outer_radius = 0.17
	steering.mesh = ring
	steering.material_override = PoofShapes.material(Color("303634"))
	steering.position = Vector3(-0.4, 1.09, -0.65)
	steering.rotation.x = 0.9
	car.add_child(steering)
	var wheels: Array[Node3D] = []
	for x in [-0.85, 0.85]:
		for z in [-1.15, 1.15]:
			var wheel := Props.round_shape(car, Vector3(x, 0.35, z), 0.32, 0.17, Color("303334"))
			wheel.rotation.z = PI / 2
			wheels.append(wheel)
	car.set_meta("wheels", wheels)
	for x in [-0.58, 0.58]:
		PoofShapes.box(car, Vector3(x, 0.72, -1.86), Vector3(0.35, 0.2, 0.04), Color("eee5b8"))

func build_lane_gate() -> void:
	# A lit street gate marks the scene boundary; its note introduces the raid.
	var gate := Node3D.new()
	gate.name = "Kaveh Lane gate"
	add_child(gate)
	gate.position = Vector3(21.7, 0, -29)
	gate.rotation.y = -PI / 2
	PoofShapes.box(gate, Vector3(0, 1.3, 0), Vector3(2.4, 2.6, 0.16), Color("315e69"), true)
	for x in [-1.3, 1.3]:
		PoofShapes.box(gate, Vector3(x, 1.5, 0), Vector3(0.2, 3, 0.35), Color("d0b187"), true)
	for x in [-0.9, -0.3, 0.3, 0.9]:
		PoofShapes.box(gate, Vector3(x, 1.25, 0.1), Vector3(0.04, 2.2, 0.04), Color("ad9566"))
	PoofShapes.box(gate, Vector3(0, 2.78, 0), Vector3(2.6, 0.35, 0.25), Color("24424e"))
	var sign := label_at(gate, Vector3(0, 2.8, 0.14), "lane_sign")
	sign.pixel_size = 0.003
	PoofShapes.box(gate, Vector3(0, 1.5, 0.13), Vector3(0.4, 0.5, 0.02), Props.CREAM)
	for i in range(5):
		PoofShapes.box(gate, Vector3(0, 1.64 - i * 0.07, 0.145), Vector3(0.28, 0.014, 0.005), Color("4d514b"))
	PoofShapes.box(gate, Vector3(0.3, 1.03, 0.14), Vector3(0.07, 0.2, 0.07), Color("b39760"))
	# Closed equipment case: collected at the cut into the armed mission.
	PoofShapes.box(gate, Vector3(-0.8, 0.25, 0.42), Vector3(0.65, 0.5, 0.55), Props.WOOD, true)
	PoofShapes.box(gate, Vector3(-0.8, 0.57, 0.42), Vector3(0.56, 0.14, 0.37), Color("333c3e"))
	for x in [-0.99, -0.61]:
		PoofShapes.box(gate, Vector3(x, 0.57, 0.61), Vector3(0.055, 0.06, 0.025), Color("b39760"))
	var lamp := OmniLight3D.new()
	lamp.position = Vector3(0, 2.5, 0.65)
	lamp.light_color = Color("ffe0aa")
	lamp.light_energy = 0.9
	lamp.omni_range = 5
	gate.add_child(lamp)
	PoofShapes.box(gate, lamp.position, Vector3(0.22, 0.18, 0.16), Color("ffe0aa"), false, 1.2)

func target(key: String, at: Vector3) -> void:
	var node := Node3D.new()
	node.position = at
	add_child(node)
	targets[key] = node

func person(at: Vector3, clothes: Color, style: int, hair := Color("3b302e")) -> Node3D:
	var node := Node3D.new()
	add_child(node)
	node.position = at
	Person.build(node, clothes, Color("c4977b"), hair, style)
	Person.articulate_head(node)
	return node

func label_at(parent: Node3D, at: Vector3, key: String) -> Label3D:
	var label := PoofShapes.label(parent, at, game.localize(key), Color("f7e0ae"), 36)
	label.font = preload("res://assets/fonts/vazirmatn/Vazirmatn.ttf")
	label.pixel_size = 0.008
	labels.append({"label": label, "key": key})
	return label

func movement_locked() -> bool:
	return stage == 0 or bakery.packing or life.trip_phase == "driving" or transition_left > 0 or (is_instance_valid(cards) and cards.visible)

func spawn_player() -> void:
	game.player.position = Vector3(-4.7, 0.55, 3.3)
	game.player.camera.position.y = 0.65
	game.player.camera.rotation.x = 0.2
	game.player.set_gun_drawn(false)
	game.player.flashlight.hide()

func objective() -> String:
	return game.localize("action_" + STEPS[stage])

func prompt() -> String:
	if life.busy():
		return game.localize("scene_wait")
	if stage == 0:
		return game.localize("action_wake")
	if game.near_and_visible(targets[STEPS[stage]]):
		return "[E]  " + objective()
	if pastry_box.visible and not pastry_lid.visible and game.near_and_visible(targets.gift):
		return game.localize("pastry_offer")
	return cafe.prompt()

func interact() -> void:
	if leaving or bakery.packing or life.busy() or transition_left > 0 or (is_instance_valid(cards) and cards.visible):
		return
	if stage == 0 or game.near_and_visible(targets[STEPS[stage]]):
		advance()
	elif pastry_box.visible and not pastry_lid.visible and game.near_and_visible(targets.gift):
		game.notify(bakery.reaction(), 9)
	else:
		cafe.interact()

func advance() -> void:
	var step: String = STEPS[stage]
	if life.busy():
		return
	if step == "lane":
		leaving = true
		# Interaction runs inside player physics; rebuild only after that stack exits.
		game.call_deferred("finish_visit", get_instance_id())
		return
	if step in ["car", "grandma", "home", "visits"]:
		life.begin_trip("bakery" if step == "car" else step)
		return
	game.notify("line_" + step, 12)
	match step:
		"wake":
			teleport(Vector3(-3.1, 0.05, 2), Vector3(-3.6, 1.6, -4))
		"blinds":
			blinds.hide()
		"family":
			life.walk_to_car(true)
		"stop":
			speaker.show()
			game.player.camera.look_at(officer.global_position + Vector3(0, 1.65, 0))
		"scarf":
			speaker.hide()
			scarf.show()
			sister.rotation.z = 0.045
		"pastry":
			bakery.open()
			marker.hide()
			game.hud.hud.hide()
			game.player.empty_hands.hide()
			for i in range(life.officers.size()):
				life.motion.walk(life.officers[i], [Vector3(-6 + i, 0, -18), Vector3(-7 + i, 0, -23)], 1.3)
			return
		"sal":
			rules.minute = 11 * 60
			game.play_tone(660, 0.6, 0.12)
		"help":
			rules.minute = 13 * 60
			life.start_cooking()
			return
		"lunch":
			life.eating = true
			rules.minute = 14 * 60
		"cards":
			life.eating = false
			rules.minute = 17 * 60
			cards = Hokm.new()
			cards.game = game
			game.hud.add_child(cards)
			cards.finished.connect(finish_cards)
			return
	complete_step()

func complete_step() -> void:
	stage = mini(stage + 1, STEPS.size() - 1)
	update_time()
	apply_language()

func finish_cards() -> void:
	stage = 13
	rules.minute = 19 * 60
	update_time()
	apply_language()
	game.notify("line_cards_done", 10)

func teleport(at: Vector3, look: Vector3) -> void:
	game.player.position = at
	game.player.velocity = Vector3.ZERO
	game.player.camera.position.y = 1.62
	game.player.rotation.y = atan2(at.x - look.x, at.z - look.z)
	game.player.camera.rotation = Vector3.ZERO

func update_time() -> void:
	var night := rules.minute >= SUNSET_MINUTE
	sun.light_energy = 0.025 if night else 0.55
	environment.environment.ambient_light_energy = 0.12 if night else 0.3
	var sky_mat: ProceduralSkyMaterial = environment.environment.sky.sky_material
	sky_mat.sky_top_color = Color("152b45") if night else Color("72a6c8")
	sky_mat.sky_horizon_color = Color("596379") if night else Color("eed8ae")
	cafe.refresh_service()

func drink() -> void:
	if movement_locked():
		return
	var at: Vector3 = game.player.global_position
	var in_public := at.z < -5 and at.z > -39
	# The bakery patrol witnesses public consumption; walls still block its view.
	var witnessed := in_public and officer.visible and at.distance_to(officer.global_position) < 9
	if witnessed:
		var query := PhysicsRayQueryParameters3D.create(at + Vector3(0, 1.5, 0), officer.global_position + Vector3(0, 1.5, 0), 1, [game.player.get_rid()])
		var hit := get_world_3d().direct_space_state.intersect_ray(query)
		witnessed = hit.is_empty() or officer.is_ancestor_of(hit.collider)
	var result: String = rules.consume(in_public, witnessed)
	if result == "drink_detained":
		# Return to a known reachable point without losing story inventory or phase.
		var destination: Vector3 = targets[STEPS[stage]].position + Vector3(0, 0.05, 2)
		teleport(destination, targets[STEPS[stage]].position)
	game.notify(result, 10)

func apply_language() -> void:
	for entry in labels:
		entry.label.text = game.localize(entry.key)
	if is_instance_valid(marker):
		marker.text = "◇  " + (game.localize("lane_sign") if stage >= 15 else objective())
		marker.position = targets[STEPS[stage]].position + Vector3(0, 2.25, 0)
		marker.visible = stage > 0 and not bakery.packing
	if is_instance_valid(life):
		life.van.get_node("Patrol sign").text = game.localize("van_sign")
		life.van.get_node("Patrol sign right").text = game.localize("van_sign")
	if is_instance_valid(cafe):
		cafe.refresh_language()
	if is_instance_valid(cards):
		cards.refresh()

func _process(delta: float) -> void:
	if not game.active:
		return
	transition_left = maxf(0, transition_left - delta)
	elapsed += delta
	if is_instance_valid(marker):
		marker.position = targets[STEPS[stage]].global_position + Vector3(0, 2.25, 0)
	bird_left -= delta
	if bird_left <= 0 and rules.minute < SUNSET_MINUTE and game.player.position.z > -15:
		bird_left = 7
		game.play_tone(2300, 0.08, 0.015)
		game.play_tone(2850, 0.12, 0.009)
