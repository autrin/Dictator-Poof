extends RefCounted
const Props := preload("res://scripts/domestic_props.gd")
const Person := preload("res://scripts/person_visual.gd")
const WOOD := Color("614735")
const BRASS := Color("c19a65")
const BRICK := preload("res://assets/textures/interiors/courtyard_brick.svg")

static func build(room: Node3D, grandparents: bool) -> void:
	var front := Node3D.new()
	front.name = "Street porch" if grandparents else "Garden porch"
	room.add_child(front)
	var face := 1.0 if grandparents else -1.0
	front.position.z = 5 * face
	var enamel := Color("326761") if grandparents else Color("4d6470")
	# Brick facing wraps the sill, lintel and doorway pier without covering the windows.
	for panel in [[-2.5, 0.42, 9.0, 0.84], [-2.5, 2.71, 9.0, 0.78], [6.0, 1.55, 2.0, 3.1]]:
		var size := Vector3(panel[2], panel[3], 0.055)
		var brick := PoofShapes.box(front, Vector3(panel[0], panel[1], 0.13 * face), size, Color("e3d0b5"))
		brick.material_override.albedo_texture = BRICK
		brick.material_override.uv1_scale = Vector3(size.x / 0.82, size.y / 0.40, 1)
	for x in [-6.88, -2.50, 1.88]:
		PoofShapes.box(front, Vector3(x, 1.58, 0), Vector3(0.15, 1.55, 0.32), WOOD, true)
	for x: float in [-4.69, -0.31]:
		for y in [0.86, 1.90, 2.28]:
			PoofShapes.box(front, Vector3(x, y, 0), Vector3(4.25, 0.065, 0.30), WOOD)
		for j in range(7):
			var cx := x + (j - 3) * 0.59
			var pane := PoofShapes.box(front, Vector3(cx, 2.09, 0), Vector3(0.214, 0.214, 0.035),
				[Color("a5614a"), Color("4e8686"), Color("cdac67")][j % 3])
			pane.rotation.z = PI / 4
			for side in [-1, 1]:
				var lattice := PoofShapes.box(front, Vector3(cx + side * 0.146, 2.09, 0), Vector3(0.031, 0.47, 0.08), WOOD)
				lattice.rotation.z = side * 0.68
		for offset in [-1.4, 0, 1.4]:
			PoofShapes.box(front, Vector3(x + offset, 1.38, 0), Vector3(0.045, 1.02, 0.11), WOOD)
	PoofShapes.box(front, Vector3(-2.5, 0.84, 0.18 * face), Vector3(9.05, 0.10, 0.34), Color("ae9c84"))
	# A shallow porch and high transom keep the full-width path into the house open.
	PoofShapes.box(front, Vector3(3.50, 2.98, 0.46 * face), Vector3(3.52, 0.15, 1.18), WOOD)
	for x in [2.04, 4.96]:
		PoofShapes.box(front, Vector3(x, 1.41, 0.28 * face), Vector3(0.17, 2.82, 0.19), enamel)
		for y in [0.13, 2.62, 2.74]:
			PoofShapes.box(front, Vector3(x, y, 0.28 * face), Vector3(0.24, 0.08, 0.25), BRASS)
	PoofShapes.box(front, Vector3(3.5, 2.73, 0.25 * face), Vector3(2.92, 0.29, 0.14), enamel)
	for j in range(9):
		var glint := PoofShapes.box(front, Vector3(2.30 + j * 0.30, 2.73, 0.34 * face), Vector3(0.102, 0.102, 0.018), BRASS)
		glint.rotation.z = PI / 4
	var light := OmniLight3D.new()
	light.position = Vector3(1.55, 1.95, 0.50 * face)
	light.light_color = Color("ffdb9d")
	light.light_energy = 0.36
	light.omni_range = 3
	front.add_child(light)
	PoofShapes.box(front, light.position, Vector3(0.16, 0.28, 0.12), Color("eac997"), false, 0.6)
	for y in [1.8, 2.1]:
		PoofShapes.box(front, Vector3(1.55, y, 0.5 * face), Vector3(0.21, 0.035, 0.16), WOOD)
	for x in [-5.85, -0.95, 5.8]:
		geranium(front, Vector3(x, 0.0, 0.54 * face), int(absf(x) * 10))

static func geranium(parent: Node3D, at: Vector3, seed_offset: int) -> void:
	var pot := Props.round_shape(parent, at + Vector3.UP * 0.16, 0.22, 0.32, Color("ab6d50"))
	pot.mesh.bottom_radius = 0.15
	Props.round_shape(parent, at + Vector3.UP * 0.32, 0.228, 0.047, Color("bd8060"))
	Props.round_shape(parent, at + Vector3.UP * 0.347, 0.19, 0.015, Color("584b37"))
	for i in range(7):
		var a := i * 2.4 + seed_offset
		var offset := Vector3(cos(a) * 0.13, 0.0, sin(a) * 0.13)
		var stalk := at + offset + Vector3.UP * (0.48 + 0.04 * sin(2 * a))
		PoofShapes.box(parent, stalk, Vector3(0.012, 0.27, 0.012), Color("596c48"))
		var leaf := Person.sphere(parent, "Geranium leaf", stalk + offset * 0.65, Vector3(0.17, 0.038, 0.15), Color("567354"))
		leaf.rotation.z = 0.35 * cos(a)
		for j in range(3):
			var bloom := stalk + Vector3(0.035 * cos(j * 2.1), 0.145, 0.035 * sin(j * 2.1))
			Person.sphere(parent, "Geranium", bloom, Vector3(0.065, 0.059, 0.066), Color("bb5157").lightened(j * 0.07))
