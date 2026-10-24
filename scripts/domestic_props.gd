extends RefCounted
## Shared furniture at human scale. Collision belongs to the furniture, not decorations.
const Person := preload("res://scripts/person_visual.gd")
const WOOD := Color("684736")
const CREAM := Color("eee0c4")

static func round_shape(parent: Node3D, at: Vector3, radius: float, height: float, color: Color) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = radius
	cylinder.bottom_radius = radius
	cylinder.height = height
	cylinder.radial_segments = 24
	mesh.mesh = cylinder
	mesh.material_override = PoofShapes.material(color)
	parent.add_child(mesh)
	mesh.position = at
	return mesh

static func table(parent: Node3D, at: Vector3, size: Vector2 = Vector2(1.4, 0.85)) -> void:
	PoofShapes.box(parent, at + Vector3(0, 0.74, 0), Vector3(size.x, 0.08, size.y), WOOD, true)
	for x in [-1, 1]:
		for z in [-1, 1]:
			PoofShapes.box(parent, at + Vector3(x * (size.x / 2 - 0.1), 0.35, z * (size.y / 2 - 0.1)), Vector3(0.07, 0.7, 0.07), WOOD, true)

static func chair(parent: Node3D, at: Vector3, angle: float = 0.0) -> Node3D:
	var chair_root := Node3D.new()
	parent.add_child(chair_root)
	chair_root.position = at
	chair_root.rotation.y = angle
	PoofShapes.box(chair_root, Vector3(0, 0.46, 0), Vector3(0.48, 0.08, 0.48), WOOD, true)
	PoofShapes.box(chair_root, Vector3(0, 0.75, 0.21), Vector3(0.48, 0.5, 0.065), WOOD, true)
	PoofShapes.box(chair_root, Vector3(0, 0.51, -0.02), Vector3(0.43, 0.04, 0.4), Color("557c77"))
	for x in [-0.18, 0.18]:
		for z in [-0.18, 0.18]:
			PoofShapes.box(chair_root, Vector3(x, 0.22, z), Vector3(0.045, 0.44, 0.045), WOOD, true)
	return chair_root

static func cup(parent: Node3D, at: Vector3) -> Node3D:
	var root := Node3D.new()
	parent.add_child(root)
	root.position = at
	round_shape(root, Vector3.ZERO, 0.105, 0.015, CREAM)
	round_shape(root, Vector3(0, 0.055, 0), 0.063, 0.1, CREAM)
	round_shape(root, Vector3(0, 0.107, 0), 0.052, 0.003, Color("442d20"))
	var handle := MeshInstance3D.new()
	var ring := TorusMesh.new()
	ring.inner_radius = 0.019
	ring.outer_radius = 0.033
	handle.mesh = ring
	handle.material_override = PoofShapes.material(CREAM)
	handle.position = Vector3(0.066, 0.055, 0)
	handle.rotation.x = PI / 2
	root.add_child(handle)
	return root

static func rug(parent: Node3D, at: Vector3, size: Vector2) -> void:
	var carpet := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = size
	carpet.mesh = plane
	carpet.position = at
	carpet.material_override = PoofShapes.material(Color.WHITE)
	parent.add_child(carpet)
	carpet.material_override.albedo_texture = load("res://assets/textures/interiors/nowruz_carpet.svg")

static func surface_texture() -> NoiseTexture2D:
	var texture := NoiseTexture2D.new()
	texture.width = 256
	texture.height = 256
	texture.seamless = true
	var noise := FastNoiseLite.new()
	noise.seed = 1427
	noise.frequency = 0.055
	noise.fractal_octaves = 3
	texture.noise = noise
	var ramp := Gradient.new()
	ramp.colors = PackedColorArray([Color("e4e2dc"), Color("f6f4ee")])
	texture.color_ramp = ramp
	return texture

static func haftseen(parent: Node3D, at: Vector3) -> void:
	table(parent, at, Vector2(2.1, 1.0))
	PoofShapes.box(parent, at + Vector3(0, 0.787, 0), Vector3(1.95, 0.012, 0.9), CREAM)
	# Sabzeh, samanu, senjed, seer, seeb, somaq and serkeh.
	var colors := [Color("658744"), Color("795137"), Color("af7548"), CREAM, Color("ba4736"), Color("9a463c"), Color("834b29")]
	for i in range(7):
		var p := at + Vector3(-0.75 + (i % 4) * 0.48, 0.81, -0.22 + (i / 4) * 0.4)
		round_shape(parent, p, 0.16, 0.04, Color("408b89"))
		if i == 0:
			for j in range(18):
				PoofShapes.box(parent, p + Vector3(sin(j * 2.4) * 0.1, 0.1, cos(j * 2.4) * 0.1), Vector3(0.013, 0.16, 0.015), colors[i])
		else:
			for j in range(3):
				Person.sphere(parent, "Seen", p + Vector3((j - 1) * 0.06, 0.045, 0), Vector3(0.08, 0.07, 0.08), colors[i])
	PoofShapes.box(parent, at + Vector3(0, 1.08, -0.43), Vector3(0.48, 0.57, 0.055), WOOD)
	PoofShapes.box(parent, at + Vector3(0, 1.08, -0.394), Vector3(0.4, 0.49, 0.008), Color("b9cdd0"))
	for x in [-0.8, 0.8]:
		round_shape(parent, at + Vector3(x, 0.94, -0.35), 0.035, 0.22, CREAM)
		Person.sphere(parent, "Candle flame", at + Vector3(x, 1.065, -0.35), Vector3(0.025, 0.06, 0.025), Color("ffd784"))
