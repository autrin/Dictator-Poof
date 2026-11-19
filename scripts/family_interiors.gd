extends RefCounted
const Props := preload("res://scripts/domestic_props.gd")
const Person := preload("res://scripts/person_visual.gd")
const WOOD := Color("624534")
const BRASS := Color("bd9b63")
const WEAVE := preload("res://assets/textures/interiors/boteh_weave.svg")
const MOUNTAINS := preload("res://assets/textures/interiors/foothill_print.svg")
const ORCHARD := preload("res://assets/textures/interiors/pomegranate_panel.svg")

static func panel(parent: Node3D, at: Vector3, size: Vector2, texture: Texture2D) -> void:
	var art := MeshInstance3D.new()
	var face := QuadMesh.new()
	face.size = size
	art.mesh = face
	art.position = at
	art.material_override = PoofShapes.material(Color.WHITE)
	art.material_override.albedo_texture = texture
	parent.add_child(art)

static func frame(parent: Node3D, at: Vector3, size: Vector2, art: Texture2D) -> void:
	PoofShapes.box(parent, at, Vector3(size.x + 0.17, size.y + 0.17, 0.08), WOOD)
	PoofShapes.box(parent, at + Vector3(0, 0, 0.044), Vector3(size.x + 0.105, size.y + 0.105, 0.019), BRASS)
	PoofShapes.box(parent, at + Vector3(0, 0, 0.058), Vector3(size.x + 0.080, size.y + 0.080, 0.018), Color("e7ddc7"))
	panel(parent, at + Vector3(0, 0, 0.070), size, art)

static func wall(room: Node3D, at: Vector3, yaw: float) -> Node3D:
	var unit := Node3D.new()
	room.add_child(unit)
	unit.position = at
	unit.rotation.y = yaw
	return unit

static func sofa(unit: Node3D, x: float, width: float, upholstery: Color) -> void:
	var at := Vector3(x, 0, 0.55)
	for dx in [-1, 1]:
		for z in [0.25, 0.85]:
			PoofShapes.box(unit, Vector3(x + dx * (width / 2 - 0.14), 0.13, z), Vector3(0.10, 0.26, 0.10), WOOD)
		PoofShapes.box(unit, at + Vector3(dx * width / 2, 0.49, 0), Vector3(0.12, 0.45, 0.81), WOOD)
	PoofShapes.box(unit, at + Vector3.UP * 0.28, Vector3(width, 0.21, 0.86), WOOD, true)
	PoofShapes.box(unit, at + Vector3(0, 0.59, -0.33), Vector3(width, 0.65, 0.17), upholstery)
	for i in range(3):
		var dx := (i - 1) * (width - 0.21) / 3
		PoofShapes.box(unit, at + Vector3(dx, 0.424, 0.03), Vector3((width - 0.21) / 3 - 0.016, 0.16, 0.65), upholstery.lightened(0.06))
		var cushion := Person.sphere(unit, "Woven cushion", at + Vector3(dx, 0.70, -0.17), Vector3(0.50, 0.41, 0.20), Color.WHITE)
		cushion.material_override.albedo_texture = WEAVE
		cushion.rotation.z = dx * 0.12

static func books(parent: Node3D, at: Vector3, count: int) -> void:
	var colours := [Color("753f43"), Color("456760"), Color("bd9564"), Color("455364")]
	for i in range(count):
		var h := 0.26 + (i % 3) * 0.046
		var spine := PoofShapes.box(parent, at + Vector3(i * 0.091, h / 2, 0), Vector3(0.083, h, 0.22), colours[i % 4])
		for offset in [-0.36, 0.32]:
			PoofShapes.box(spine, Vector3(0, offset * h, 0.113), Vector3(0.066, 0.010, 0.005), BRASS)

static func home(room: Node3D) -> void:
	var lounge := wall(room, Vector3(0.3, 0, 4.86), PI)
	# The deep painted wall and low sofa give the sitting room a center.
	PoofShapes.box(lounge, Vector3(-1.50, 1.50, 0), Vector3(8.12, 2.98, 0.048), Color("55736c"))
	frame(lounge, Vector3(-1.66, 1.88, 0.07), Vector2(3.25, 1.47), MOUNTAINS)
	sofa(lounge, -1.66, 3.12, Color("a99972"))
	Props.table(lounge, Vector3(-3.83, 0, 0.54), Vector2(0.72, 0.66))
	reading_lamp(lounge, Vector3(-3.83, 0.80, 0.54))
	var tv := wall(room, Vector3(6.83, 0, -1.4), -PI / 2)
	PoofShapes.box(tv, Vector3(0, 0.38, 0.17), Vector3(2.60, 0.69, 0.46), WOOD, true)
	for i in [-1, 0, 1]:
		PoofShapes.box(tv, Vector3(i * 0.82, 0.40, 0.409), Vector3(0.79, 0.50, 0.035), Color("977357"))
		PoofShapes.box(tv, Vector3(i * 0.82, 0.57, 0.44), Vector3(0.15, 0.017, 0.022), BRASS)
	books(tv, Vector3(-1.08, 0.739, 0.19), 4)
	# A fern and record sleeves share the wall with Mum's Nowruz concert.
	for i in range(2):
		var x := -2.67 + i * 0.64
		PoofShapes.box(tv, Vector3(x, 1.61, 0.055), Vector3(0.56, 0.58, 0.047), WOOD)
		PoofShapes.box(tv, Vector3(x, 1.61, 0.086), Vector3(0.50, 0.51, 0.021), Color("c19470") if i == 0 else Color("608584"))
		for j in range(3):
			var disc := Props.round_shape(tv, Vector3(x, 1.63, 0.106 + j * 0.01), 0.17 - j * 0.055, 0.008, [Color("324247"), Color("ba9365"), Color("613b3c")][j])
			disc.rotation.x = PI / 2
	houseplant(tv, Vector3(2.07, 0, 0.42))
	var bedroom := wall(room, Vector3(-4.7, 0, 4.87), PI)
	PoofShapes.box(bedroom, Vector3(0, 0.65, 0), Vector3(2.27, 1.23, 0.08), WOOD)
	frame(bedroom, Vector3(0, 1.93, 0.03), Vector2(0.71, 0.99), ORCHARD)
	var quilt := PoofShapes.box(room, Vector3(-4.7, 0.661, 2.51), Vector3(2.03, 0.045, 1.88), Color.WHITE)
	quilt.material_override.albedo_texture = WEAVE
	# A timber screen gives the bed a private corner; the foot is open toward the garden.
	var screen := wall(room, Vector3(-3.35, 0, 3.75), PI / 2)
	for i in range(12):
		PoofShapes.box(screen, Vector3((i - 5.5) * 0.175, 0.91, 0), Vector3(0.064, 1.82, 0.09), WOOD)
	for y in [0.12, 1.02, 1.82]:
		PoofShapes.box(screen, Vector3(0, y, 0), Vector3(2.02, 0.086, 0.12), Color("926c50"))
	PoofShapes.box(screen, Vector3(0, 0.32, 0), Vector3(2.02, 0.64, 0.10), WOOD, true)

static func grandparents(room: Node3D) -> void:
	var gallery := wall(room, Vector3(-6.83, 0, 0), PI / 2)
	PoofShapes.box(gallery, Vector3(0, 1.52, 0), Vector3(9.60, 3.0, 0.08), Color("a8886e"))
	frame(gallery, Vector3(-0.4, 1.80, 0.09), Vector2(1.32, 1.83), ORCHARD)
	for x in [-3.02, 2.29]:
		var shelf := wall(gallery, Vector3(x, 0, 0.07), 0)
		PoofShapes.box(shelf, Vector3(0, 1.40, 0), Vector3(2.12, 2.27, 0.10), Color("466864"))
		PoofShapes.box(shelf, Vector3(0, 0.32, 0.13), Vector3(2.15, 0.62, 0.36), WOOD, true)
		for edge in [-1.04, 1.04]:
			PoofShapes.box(shelf, Vector3(edge, 1.43, 0.13), Vector3(0.09, 2.31, 0.27), WOOD)
		for y in [0.63, 1.29, 1.94, 2.56]:
			PoofShapes.box(shelf, Vector3(0, y, 0.14), Vector3(2.18, 0.06, 0.36), WOOD)
			PoofShapes.box(shelf, Vector3(0, y, 0.325), Vector3(2.10, 0.014, 0.009), BRASS)
		books(shelf, Vector3(-0.77, 0.665, 0.18), 7 if x < 0 else 4)
		books(shelf, Vector3(0.18, 1.975, 0.17), 5)
		for i in range(3):
			var dish := Props.round_shape(shelf, Vector3(-0.61 + 0.57 * i, 1.56, 0.11), 0.23, 0.042, Color("e5d4ae"))
			dish.rotation.x = 1.40
			var medallion := Props.round_shape(dish, Vector3(0, 0.024, 0), 0.185, 0.008, Color("38777b"))
			Props.round_shape(medallion, Vector3(0, 0.009, 0), 0.14, 0.01, Color("d4baa0"))
	sofa(gallery, -0.40, 2.16, Color("526f69"))
	var kitchen := wall(room, Vector3(6.84, 0, 0), -PI / 2)
	var splash := PoofShapes.box(kitchen, Vector3(0, 1.38, 0), Vector3(3.8, 0.95, 0.06), Color.WHITE)
	splash.material_override.albedo_texture = preload("res://assets/textures/interiors/garden_tile.svg")
	splash.material_override.uv1_scale = Vector3(10, 3, 1)
	PoofShapes.box(kitchen, Vector3(0, 2.16, 0.15), Vector3(3.62, 0.07, 0.36), WOOD)
	for i in range(5):
		var jar := Props.round_shape(kitchen, Vector3(-1.48 + i * 0.30, 2.32, 0.14), 0.112, 0.25, [Color("a57c5d"), Color("4b7370"), Color("d4ba89")][i % 3])
		Props.round_shape(jar, Vector3.UP * 0.135, 0.115, 0.035, BRASS)
	for i in range(3):
		var x := 0.25 + i * 0.51
		PoofShapes.box(kitchen, Vector3(x, 1.93, 0.26), Vector3(0.026, 0.36, 0.03), BRASS)
		var pan := Props.round_shape(kitchen, Vector3(x, 1.64, 0.26), 0.16 + i * 0.017, 0.085, Color("af7753"))
		pan.rotation.x = PI / 2
	# The rear window opens onto a narrow planted strip between house and courtyard wall.
	PoofShapes.box(room, Vector3(-2.9, 0.14, -6.16), Vector3(7.5, 0.28, 1.0), Color("9a775c"), true)
	PoofShapes.box(room, Vector3(-2.9, 0.28, -6.16), Vector3(7.34, 0.035, 0.86), Color("685946"))
	for i in range(4):
		houseplant(room, Vector3(-5.7 + i * 1.84, 0.29, -6.18))

static func houseplant(parent: Node3D, at: Vector3) -> void:
	var pot := Props.round_shape(parent, at + Vector3.UP * 0.21, 0.23, 0.42, Color("9c6a4d"))
	pot.mesh.bottom_radius = 0.16
	Props.round_shape(parent, at + Vector3.UP * 0.42, 0.24, 0.054, Color("b37c58"))
	Props.round_shape(parent, at + Vector3.UP * 0.45, 0.216, 0.014, Color("4c4736"))
	for i in range(6):
		var spread := Vector3(cos(i * 2.4), 0, sin(i * 2.4))
		var height := 0.40 + (i % 3) * 0.15
		var stem := Props.round_shape(parent, at + spread * 0.076 + Vector3.UP * (0.45 + height / 2), 0.011, height, Color("63704b"))
		for j in range(3):
			var pos := stem.position + Vector3.UP * (j * 0.09) + spread * 0.16
			var leaf := Person.sphere(parent, "Leaf", pos, Vector3(0.43 - j * 0.05, 0.042, 0.15), Color("487057").lightened((i % 3) * 0.065))
			leaf.rotation = Vector3(0, -i * 2.4, 0.43 - j * 0.13)

static func reading_lamp(parent: Node3D, at: Vector3) -> void:
	Props.round_shape(parent, at, 0.16, 0.03, BRASS)
	Person.sphere(parent, "Glazed lamp", at + Vector3.UP * 0.19, Vector3(0.24, 0.35, 0.24), Color("406c72"))
	var shade := Props.round_shape(parent, at + Vector3.UP * 0.47, 0.25, 0.28, Color("ecd5a6"))
	shade.mesh.top_radius = 0.16
	var glow := OmniLight3D.new()
	glow.position = at + Vector3.UP * 0.49
	glow.light_energy = 0.36
	glow.light_color = Color("ffdaa0")
	glow.omni_range = 3.4
	parent.add_child(glow)
