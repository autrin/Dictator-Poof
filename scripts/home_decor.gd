extends RefCounted
## Original decorative motifs and domestic objects; passages remain unobstructed.
const Props := preload("res://scripts/domestic_props.gd")
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
		for pleat in range(7):
			var curtain := Person.sphere(decor, "Curtain fold", Vector3(x + (pleat - 3) * 0.10, 1.62, -4.67), Vector3(0.15, 1.62, 0.16), Color("7f4046").lightened(pleat % 2 * 0.035))
			curtain.rotation.z = (pleat - 3) * 0.012
		PoofShapes.box(decor, Vector3(x, 1.3, -4.55), Vector3(0.76, 0.055, 0.035), GOLD)
	# A display cabinet holds blue ceramics and family keepsakes.
	PoofShapes.box(decor, Vector3(-6.48, 1.05, -0.35), Vector3(0.75, 2.1, 2.4), WALNUT, true)
	for y in [0.6, 1.15, 1.72]:
		PoofShapes.box(decor, Vector3(-6.06, y, -0.35), Vector3(0.2, 0.04, 2.3), GOLD)
		for z in [-1.15, -0.4, 0.4]:
			vase(decor, Vector3(-5.96, y + 0.03, z), Color("3a778d"), y > 1.5)
	# A brass chandelier and hanging crystal drops.
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
	# Upholstered cushions and carved sofa arms.
	for x in [-5.7, 5.7]:
		for offset in [-0.7, 0, 0.7]:
			var cushion := Person.sphere(decor, "Embroidered cushion", Vector3(x + offset, 0.65, 3.65), Vector3(0.49, 0.42, 0.18), Color("984e50") if offset != 0 else Color("c1a56f"))
			cushion.rotation.z = offset * 0.15
	# Small tea service on an inlaid side table.
	Props.table(decor, Vector3(-3.5, 0, -3.7), Vector2(1.2, 0.65))
	Props.round_shape(decor, Vector3(-3.5, 0.8, -3.7), 0.28, 0.02, GOLD)
	for x in [-3.65, -3.35]:
		Props.cup(decor, Vector3(x, 0.82, -3.7))
	vase(decor, Vector3(-3.9, 0.8, -3.75), Color("af7856"), true)
	if grandparents:
		# Backsplash, cupboard fronts, chopping board, herbs and a simmering pot.
		for z in [-0.7, 0, 0.7]:
			PoofShapes.box(decor, Vector3(5.12, 0.48, z), Vector3(0.02, 0.65, 0.62), Color("b7986e"))
			PoofShapes.box(decor, Vector3(5.09, 0.7, z), Vector3(0.05, 0.025, 0.19), GOLD)
		PoofShapes.box(decor, Vector3(5.5, 0.93, -0.65), Vector3(0.58, 0.025, 0.48), Color("b39360"))
		for i in range(14):
			Person.sphere(decor, "Fresh herbs", Vector3(5.3 + (i % 4) * 0.1, 0.96, -0.8 + (i / 4) * 0.08), Vector3(0.12, 0.035, 0.1), Color("4c7044"))

static func vase(parent: Node3D, at: Vector3, color: Color, flowers: bool) -> void:
	Person.sphere(parent, "Ceramic vase", at + Vector3(0, 0.15, 0), Vector3(0.24, 0.3, 0.24), color)
	Props.round_shape(parent, at + Vector3(0, 0.31, 0), 0.065, 0.12, color)
	if flowers:
		for i in range(5):
			var top := at + Vector3(sin(i * 2.4) * 0.13, 0.51 + (i % 2) * 0.09, cos(i * 2.4) * 0.13)
			PoofShapes.box(parent, top - Vector3(0, 0.1, 0), Vector3(0.012, 0.22, 0.012), Color("566a3b"))
			Person.sphere(parent, "Hyacinth", top, Vector3(0.11, 0.17, 0.1), Color("a58ba7"))
