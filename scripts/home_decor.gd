extends RefCounted
## Original decorative motifs and domestic objects; passages remain unobstructed.
const Props := preload("res://scripts/domestic_props.gd")
const Interiors := preload("res://scripts/family_interiors.gd")
const Person := preload("res://scripts/person_visual.gd")
const GOLD := Color("b8995b")
const WALNUT := Color("543a30")

static func furnish(room: Node3D, grandparents: bool) -> void:
	var decor := Node3D.new()
	decor.name = "House decoration"
	room.add_child(decor)
	# Plaster cornices and walnut skirting on the long walls.
	for x in [-6.85, 6.85]:
		for y in [0.14, 2.86, 2.98]:
			PoofShapes.box(decor, Vector3(x, y, 0), Vector3(0.13, 0.09, 9.9), WALNUT if y < 1 else Color("e7d3ae"))
		PoofShapes.box(decor, Vector3(x, 2.9, 0), Vector3(0.14, 0.018, 9.9), GOLD)
	# Tiled dado below the garden window, with repeated glazed rosettes.
	for i in range(18):
		var tile := MeshInstance3D.new()
		var face := QuadMesh.new()
		face.size = Vector2(0.46, 0.46)
		tile.mesh = face
		tile.position = Vector3(-6.7 + i * 0.48, 0.49, -4.88)
		tile.material_override = PoofShapes.material(Color.WHITE)
		decor.add_child(tile)
		tile.material_override.albedo_texture = load("res://assets/textures/interiors/garden_tile.svg")
		tile.material_override.roughness = 0.35
	# Draped curtains, tiebacks and a brass rail.
	PoofShapes.box(decor, Vector3(-2.5, 2.43, -4.7), Vector3(8.7, 0.035, 0.035), GOLD)
	for x in [-6.35, 1.4]:
		curtain(decor, x, Color("86665d") if grandparents else Color("456c70"))
	# A display cabinet holds blue ceramics and family keepsakes.
	if not grandparents:
		PoofShapes.box(decor, Vector3(-6.48, 0.48, -0.35), Vector3(0.75, 0.96, 2.4), WALNUT, true)
		for z in [-1.40, 0.70]:
			PoofShapes.box(decor, Vector3(-6.46, 1.51, z), Vector3(0.66, 1.10, 0.05), WALNUT)
		for y in [0.99, 1.52, 2.06]:
			PoofShapes.box(decor, Vector3(-6.44, y, -0.35), Vector3(0.74, 0.045, 2.2), WALNUT)
		vase(decor, Vector3(-6.4, 1.02, -0.84), Color("477d89"), false)
		vase(decor, Vector3(-6.4, 1.55, 0.32), Color("ad7d58"), false)
		var book_row := Interiors.wall(decor, Vector3(-6.36, 1.55, -0.42), PI / 2)
		Interiors.books(book_row, Vector3.ZERO, 6)
	# A brass chandelier and hanging crystal drops.
	for i in range(3):
		var moulding := Props.round_shape(decor, Vector3(0.3, 3.01 - i * 0.014, 0.8), 0.69 - i * 0.14, 0.027, Color("e6d7bc").darkened(i % 2 * 0.085))
		moulding.mesh.radial_segments = 32
	Props.round_shape(decor, Vector3(0.3, 2.92, 0.8), 0.18, 0.08, GOLD)
	Props.round_shape(decor, Vector3(0.3, 2.65, 0.8), 0.025, 0.5, GOLD)
	for i in range(6):
		var angle := i * TAU / 6
		var at := Vector3(0.3 + cos(angle) * 0.55, 2.42, 0.8 + sin(angle) * 0.55)
		var arm := PoofShapes.box(decor, (at + Vector3(0.3, 2.42, 0.8)) / 2, Vector3(0.55, 0.025, 0.025), GOLD)
		arm.rotation.y = -angle
		Props.round_shape(decor, at, 0.12, 0.045, GOLD)
		Person.sphere(decor, "Lamp glass", at + Vector3(0, 0.09, 0), Vector3(0.11, 0.2, 0.11), Color("f7e8c7"))
		for j in range(3):
			Person.sphere(decor, "Crystal drop", at + Vector3((j - 1) * 0.075, -0.1 - (j % 2) * 0.05, 0), Vector3(0.04, 0.15, 0.04), Color("cfddd6"))
	# Small tea service on an inlaid side table.
	Props.table(decor, Vector3(-3.31 if grandparents else -3.5, 0, -3.7), Vector2(1.9 if grandparents else 1.2, 0.65))
	Props.round_shape(decor, Vector3(-3.5, 0.8, -3.7), 0.28, 0.02, GOLD)
	for x in [-3.65, -3.35]:
		Props.tea_glass(decor, Vector3(x, 0.82, -3.7))
	Props.round_shape(decor, Vector3(-3.51, 0.84, -3.55), 0.077, 0.057, Color("61888c"))
	for j in range(4):
		var cube := PoofShapes.box(decor, Vector3(-3.53 + 0.037 * (j % 2), 0.872, -3.57 + 0.035 * (j / 2)), Vector3.ONE * 0.034, Color("f4ecd6"))
		cube.rotation.y = j * 0.43
	vase(decor, Vector3(-3.9, 0.8, -3.75), Color("af7856"), true)
	if grandparents:
		# Backsplash, cupboard fronts, chopping board, herbs and a simmering pot.
		for z in [-0.7, 0, 0.7]:
			PoofShapes.box(decor, Vector3(5.12, 0.48, z), Vector3(0.02, 0.65, 0.62), Color("b7986e"))
			PoofShapes.box(decor, Vector3(5.09, 0.7, z), Vector3(0.05, 0.025, 0.19), GOLD)
		PoofShapes.box(decor, Vector3(5.5, 0.93, -0.65), Vector3(0.58, 0.025, 0.48), Color("b39360"))
		for i in range(14):
			Person.sphere(decor, "Fresh herbs", Vector3(5.3 + (i % 4) * 0.1, 0.96, -0.8 + (i / 4) * 0.08), Vector3(0.12, 0.035, 0.1), Color("4c7044"))

static func curtain(parent: Node3D, x: float, tint: Color) -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var heights := [2.43, 1.92, 1.34, 0.79]
	var widths := [0.91, 0.68, 0.32, 0.59]
	for row in range(3):
		for col in range(24):
			for corner: Vector2i in [Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(0, 0), Vector2i(1, 1), Vector2i(1, 0)]:
				var level := row + corner.y
				var u := (col + corner.x) / 24.0
				var ripple := cos(u * TAU * 6)
				var drape := 0.17 * sin(level * 0.83) * (-1 if x < 0 else 1)
				surface.add_vertex(Vector3(x + (u - 0.5) * widths[level] + drape, heights[level] + (0.022 * ripple if level == 3 else 0.0), -4.68 + ripple * 0.055))
	surface.generate_normals()
	var cloth := MeshInstance3D.new()
	cloth.mesh = surface.commit()
	cloth.material_override = PoofShapes.material(tint)
	cloth.material_override.cull_mode = BaseMaterial3D.CULL_DISABLED
	parent.add_child(cloth)
	PoofShapes.box(parent, Vector3(x + (-0.17 if x < 0 else 0.17), 1.34, -4.61), Vector3(0.33, 0.044, 0.04), GOLD)

static func vase(parent: Node3D, at: Vector3, color: Color, flowers: bool) -> void:
	Person.sphere(parent, "Ceramic vase", at + Vector3(0, 0.15, 0), Vector3(0.24, 0.3, 0.24), color)
	Props.round_shape(parent, at + Vector3(0, 0.31, 0), 0.065, 0.12, color)
	if flowers:
		for i in range(5):
			var top := at + Vector3(sin(i * 2.4) * 0.13, 0.51 + (i % 2) * 0.09, cos(i * 2.4) * 0.13)
			PoofShapes.box(parent, top - Vector3(0, 0.1, 0), Vector3(0.012, 0.22, 0.012), Color("566a3b"))
			Person.sphere(parent, "Hyacinth", top, Vector3(0.11, 0.17, 0.1), Color("a58ba7"))
