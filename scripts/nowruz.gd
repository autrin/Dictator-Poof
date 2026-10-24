extends Node3D
## Chapter state owns story progress; props, café policy and card rules are separate.
const Props := preload("res://scripts/domestic_props.gd")
const Person := preload("res://scripts/person_visual.gd")
const Cafe := preload("res://scripts/book_cafe.gd")
const DayRules := preload("res://scripts/day_rules.gd")
const Hokm := preload("res://scripts/hokm.gd")
const SUNSET_MINUTE := 18 * 60 + 20
const STEPS := ["wake", "blinds", "tv", "family", "car", "stop", "scarf", "pastry", "grandma", "sal", "help", "lunch", "cards", "home", "visits", "done"]
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
	cafe = Cafe.new()
	cafe.game = game
	cafe.rules = rules
	cafe.position = Vector3(13, 0, -18)
	cafe.rotation.y = -PI / 2
	add_child(cafe)
	sister = person(Vector3(2, 0, 1), Color("427b88"), 1)
	scarf = Person.sphere(sister, "Covering scarf", Vector3(0, 1.82, 0.035), Vector3(0.32, 0.21, 0.31), Color("bd8393"))
	scarf.hide()
	family.append(sister)
	family.append(person(Vector3(3.5, 0, 1.5), Color("ab6652"), 3))
	family.append(person(Vector3(4.7, 0, 0.8), Color("75644f"), 0))
	officer = person(Vector3(-7.2, 0, -16.7), Color("39463e"), 0)
	officer.rotation.y = PI
	set_officer_visible(true)
	for i in range(7):
		var relative := person(Vector3(-4.5 + (i % 4) * 2.5, 0, -46.5 + (i / 4) * 5), [Color("9c654c"), Color("527572"), Color("8c6e82")][i % 3], i % 5)
		relatives.append(relative)
		Props.chair(self, relative.position)
		Person.sit(relative)
	# All chapter actions point to real, reachable objects.
	target("wake", Vector3(-4.7, 0, 3))
	target("blinds", Vector3(-3.6, 0, -3.9))
	target("tv", Vector3(5.8, 0, -1.4))
	target("family", Vector3(2, 0, 1))
	target("car", Vector3(3.8, 0, -9))
	target("stop", Vector3(-7.3, 0, -15))
	target("scarf", Vector3(-7.3, 0, -15))
	target("pastry", Vector3(-10, 0, -16))
	target("grandma", Vector3(-3.5, 0, -17.5))
	target("sal", Vector3(0, 0, -46))
	target("help", Vector3(5, 0, -44))
	target("lunch", Vector3(0, 0, -42.5))
	target("cards", Vector3(-2.7, 0, -43.5))
	target("home", Vector3(3.8, 0, -36))
	target("visits", Vector3(3.8, 0, -9))
	target("done", Vector3(0, 0, -42.5))
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
			var material := mesh.material_override as StandardMaterial3D
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
	add_child(room)
	room.position = at
	# Flush with the courtyard so the capsule does not catch on a tiny threshold.
	PoofShapes.box(room, Vector3(0, -0.03, 0), Vector3(14, 0.04, 10), Color("d6b78d"), true)
	for x in [-7.0, 7.0]:
		PoofShapes.box(room, Vector3(x, 1.55, 0), Vector3(0.2, 3.1, 10), Color("e6d7bb"), true)
	if not grandparents:
		PoofShapes.box(room, Vector3(0, 1.55, 5), Vector3(14, 3.1, 0.2), Color("e6d7bb"), true)
	# A low sill and lintel frame the garden; a full-height opening is the door.
	PoofShapes.box(room, Vector3(-2.5, 0.42, -5), Vector3(9, 0.84, 0.2), Color("d8c6a4"), true)
	PoofShapes.box(room, Vector3(-2.5, 2.7, -5), Vector3(9, 0.8, 0.2), Color("e6d7bb"), true)
	PoofShapes.box(room, Vector3(6, 1.55, -5), Vector3(2, 3.1, 0.2), Color("e6d7bb"), true)
	for x in [-6.7, -1.8, 1.9]:
		PoofShapes.box(room, Vector3(x, 1.6, -4.97), Vector3(0.09, 1.6, 0.14), Props.WOOD, true)
	PoofShapes.box(room, Vector3(0, 3.1, 0), Vector3(14.2, 0.16, 10.2), Color("efe1c4"), true)
	Props.rug(room, Vector3(1, 0.035, 0), Vector2(6, 6))
	Props.haftseen(room, Vector3(0, 0, -2))
	for x in [-5.7, 5.7]:
		PoofShapes.box(room, Vector3(x, 0.32, 3.6), Vector3(2, 0.55, 0.9), Color("87745d"), true)
		PoofShapes.box(room, Vector3(x, 0.71, 3.95), Vector3(2, 0.5, 0.17), Color("87745d"), true)
	var lamp := OmniLight3D.new()
	lamp.position = Vector3(0, 2.5, 0)
	lamp.omni_range = 10
	lamp.light_color = Color("ffe0aa")
	lamp.light_energy = 0.65
	room.add_child(lamp)
	if grandparents:
		# The street-facing south wall has a full-height doorway.
		PoofShapes.box(room, Vector3(-2.5, 1.55, 5), Vector3(9, 3.1, 0.2), Color("e6d7bb"), true)
		PoofShapes.box(room, Vector3(6, 1.55, 5), Vector3(2, 3.1, 0.2), Color("e6d7bb"), true)
		Props.table(room, Vector3(0, 0, 1.5), Vector2(3, 1.3))
		serving = Node3D.new()
		room.add_child(serving)
		for i in range(6):
			var dish := Vector3(-1 + (i % 3), 0.8, 1.2 + (i / 3) * 0.5)
			Props.round_shape(serving, dish, 0.24, 0.025, Props.CREAM)
			Person.sphere(serving, "Herbed rice", dish + Vector3(0, 0.04, 0), Vector3(0.36, 0.08, 0.32), Color("c8c591"))
			Person.sphere(serving, "Fish", dish + Vector3(0.1, 0.08, 0), Vector3(0.26, 0.07, 0.11), Color("b88848"))
		serving.hide()
		PoofShapes.box(room, Vector3(5.8, 0.45, 0), Vector3(1.3, 0.9, 2), Props.WOOD, true)
		Props.round_shape(room, Vector3(5.8, 1.03, 0), 0.33, 0.24, Color("525d60"))
		Props.table(room, Vector3(-2.7, 0, 0.5), Vector2(1.2, 0.9))
		for i in range(8):
			PoofShapes.box(room, Vector3(-3.1 + i * 0.1, 0.79, 0.5), Vector3(0.064, 0.008, 0.095), Color("823e43"))
		var house_sign := label_at(room, Vector3(0, 2.5, 4.88), "grandma_house")
		house_sign.rotation.y = PI
		house_sign.pixel_size = 0.004
		# Ajil and fruit set out beside the Haft-Seen.
		for i in range(12):
			Person.sphere(room, "Ajil", Vector3(0.5 + (i % 4) * 0.05, 0.85, -1.7 + (i / 4) * 0.04), Vector3(0.04, 0.035, 0.035), Color("ad8553"))
	else:
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
	PoofShapes.box(self, Vector3(-11.5, 1.5, -17.5), Vector3(5, 3, 0.2), Color("c4a178"), true)
	PoofShapes.box(self, Vector3(-11.5, 0.5, -16.5), Vector3(4.2, 1, 0.8), Props.WOOD, true)
	label_at(self, Vector3(-11.5, 2.2, -17.3), "pastry_shop")
	for i in range(12):
		Person.sphere(self, "Pastry", Vector3(-13 + (i % 6) * 0.5, 1.06, -16.7 + (i / 6) * 0.35), Vector3(0.25, 0.12, 0.22), Color("d2a16a") if i < 6 else Props.CREAM)
	pastry_box = Node3D.new()
	add_child(pastry_box)
	PoofShapes.box(pastry_box, Vector3.ZERO, Vector3(0.48, 0.2, 0.36), Color("efe0ce"))
	PoofShapes.box(pastry_box, Vector3(0, 0.105, 0), Vector3(0.5, 0.02, 0.38), Color("b57870"))
	pastry_box.hide()

func build_car() -> void:
	car = Node3D.new()
	add_child(car)
	car.position = Vector3(5.5, 0, -9)
	PoofShapes.box(car, Vector3(0, 0.58, 0), Vector3(1.75, 0.63, 3.7), Color("dfd9c7"), true)
	PoofShapes.box(car, Vector3(0, 1.12, 0.1), Vector3(1.5, 0.63, 1.85), Color("53696d"), true)
	PoofShapes.box(car, Vector3(0, 1.47, 0.1), Vector3(1.55, 0.08, 1.9), Color("dfd9c7"))
	for x in [-0.85, 0.85]:
		for z in [-1.15, 1.15]:
			var wheel := Props.round_shape(car, Vector3(x, 0.35, z), 0.32, 0.17, Color("303334"))
			wheel.rotation.z = PI / 2
	for x in [-0.58, 0.58]:
		PoofShapes.box(car, Vector3(x, 0.72, -1.86), Vector3(0.35, 0.2, 0.04), Color("eee5b8"))

func target(key: String, at: Vector3) -> void:
	var node := Node3D.new()
	node.position = at
	add_child(node)
	targets[key] = node

func person(at: Vector3, clothes: Color, style: int) -> Node3D:
	var node := Node3D.new()
	add_child(node)
	node.position = at
	Person.build(node, clothes, Color("c4977b"), Color("3b302e"), style)
	return node

func label_at(parent: Node3D, at: Vector3, key: String) -> Label3D:
	var label := PoofShapes.label(parent, at, game.localize(key), Color("f7e0ae"), 36)
	label.font = preload("res://assets/fonts/vazirmatn/Vazirmatn.ttf")
	label.pixel_size = 0.008
	labels.append({"label": label, "key": key})
	return label

func movement_locked() -> bool:
	return stage == 0 or transition_left > 0 or (is_instance_valid(cards) and cards.visible)

func spawn_player() -> void:
	game.player.position = Vector3(-4.7, 0.55, 3.3)
	game.player.camera.position.y = 0.65
	game.player.camera.rotation.x = 0.2
	game.player.set_gun_drawn(false)
	game.player.flashlight.hide()

func objective() -> String:
	return game.localize("action_" + STEPS[stage])

func prompt() -> String:
	if stage == 0:
		return game.localize("action_wake")
	if stage < STEPS.size() - 1 and game.near_and_visible(targets[STEPS[stage]]):
		return "[E]  " + objective()
	return cafe.prompt()

func interact() -> void:
	if transition_left > 0 or (is_instance_valid(cards) and cards.visible):
		return
	if stage == 0 or (stage < STEPS.size() - 1 and game.near_and_visible(targets[STEPS[stage]])):
		advance()
	else:
		cafe.interact()

func advance() -> void:
	var step: String = STEPS[stage]
	if step in ["car", "grandma", "home", "visits"]:
		transition_left = 0.7
	game.notify("line_" + step, 12)
	match step:
		"wake":
			teleport(Vector3(-3.1, 0.05, 2), Vector3(-3.6, 1.6, -4))
		"blinds":
			blinds.hide()
		"car":
			rules.minute = 9 * 60
			car.position = Vector3(-3.5, 0, -18.7)
			move_family(Vector3(-7.3, 0, -15))
			teleport(Vector3(-6, 0.05, -12.6), Vector3(-7.3, 1.5, -15))
		"stop":
			set_officer_visible(true)
		"scarf":
			scarf.show()
			sister.rotation.z = 0.045
		"pastry":
			pastry_box.show()
			pastry_box.position = sister.position + Vector3(0, 0.92, -0.3)
		"grandma":
			rules.minute = 10 * 60
			car.position = Vector3(5.5, 0, -36)
			move_family(Vector3(3, 0, -45))
			pastry_box.position = Vector3(0.6, 0.9, -45.8)
			teleport(Vector3(3.5, 0.05, -40.5), Vector3(0, 1.1, -46))
		"sal":
			rules.minute = 11 * 60
			game.play_tone(660, 0.6, 0.12)
		"help":
			rules.minute = 13 * 60
			serving.show()
		"lunch":
			rules.minute = 17 * 60
		"cards":
			cards = Hokm.new()
			cards.game = game
			game.hud.add_child(cards)
			cards.finished.connect(finish_cards)
			return
		"home":
			rules.minute = 20 * 60
			car.position = Vector3(5.5, 0, -9)
			move_family(Vector3(2, 0, 1))
			teleport(Vector3(3.5, 0.05, -7), Vector3(1, 1, -10))
		"visits":
			rules.minute = 21 * 60
			move_family(Vector3(3, 0, -45))
			teleport(Vector3(3.5, 0.05, -40.5), Vector3(0, 1, -42.5))
	stage = mini(stage + 1, STEPS.size() - 1)
	update_time()
	apply_language()

func finish_cards() -> void:
	stage = 13
	rules.minute = 19 * 60
	update_time()
	apply_language()
	game.notify("line_cards_done", 10)

func move_family(at: Vector3) -> void:
	for i in range(family.size()):
		family[i].position = at + Vector3(i * 1.1, 0, 0.5 if i > 0 else 0)

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

func set_officer_visible(value: bool) -> void:
	officer.visible = value
	officer.get_node("Body collider").collision_layer = 1 if value else 0

func drink() -> void:
	if movement_locked():
		return
	var at: Vector3 = game.player.global_position
	var in_public := at.z < -5 and at.z > -39
	# The bakery patrol witnesses public consumption; walls still block its view.
	var witnessed := in_public and at.distance_to(Vector3(-7.2, 0, -16.7)) < 9
	if witnessed:
		var query := PhysicsRayQueryParameters3D.create(at + Vector3(0, 1.5, 0), Vector3(-7.2, 1.5, -16.7), 1, [game.player.get_rid()])
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
		marker.text = "◇  " + objective()
		marker.position = targets[STEPS[stage]].position + Vector3(0, 2.25, 0)
		marker.visible = stage > 0 and stage < 15
	if is_instance_valid(cafe):
		cafe.refresh_language()
	if is_instance_valid(cards):
		cards.refresh()

func _process(delta: float) -> void:
	if not game.active:
		return
	transition_left = maxf(0, transition_left - delta)
	elapsed += delta
	for i in range(relatives.size()):
		relatives[i].rotation.y = sin(elapsed * 0.6 + i) * 0.08
	bird_left -= delta
	if bird_left <= 0 and rules.minute < SUNSET_MINUTE and game.player.position.z > -15:
		bird_left = 7
		game.play_tone(2300, 0.08, 0.015)
		game.play_tone(2850, 0.12, 0.009)
