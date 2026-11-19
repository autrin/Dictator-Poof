extends RefCounted
## Shared pastry meshes let the same pieces travel from the display to the family box.
const FLAVOURS := ["cream", "rice", "chickpea"]
const PAPER := Color("fae8c9")
const PLUM := Color("833d50")
static var meshes: Array[ArrayMesh] = []

static func piece(kind: int) -> MeshInstance3D:
	if meshes.is_empty():
		for i in range(FLAVOURS.size()):
			meshes.append(bake(i))
	var pastry := MeshInstance3D.new()
	pastry.mesh = meshes[kind]
	pastry.name = FLAVOURS[kind]
	return pastry

static func bake(kind: int) -> ArrayMesh:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var material := PoofShapes.material(Color.WHITE)
	material.vertex_color_use_as_albedo = true
	surface.set_material(material)
	match kind:
		0: # Split choux shell with a piped cream seam.
			loft(surface, [Vector2(0.002, 0), Vector2(0.076, 0.006), Vector2(0.10, 0.043), Vector2(0.084, 0.057), Vector2(0.001, 0.057)], Color("c38242"), 8, 0.045)
			loft(surface, [Vector2(0.074, 0.045), Vector2(0.096, 0.061), Vector2(0.095, 0.073), Vector2(0.074, 0.081)], Color("fff1cf"), 10, 0.06)
			loft(surface, [Vector2(0.080, 0.072), Vector2(0.102, 0.081), Vector2(0.084, 0.105), Vector2(0.050, 0.126), Vector2(0.001, 0.134)], Color("dea05b"), 7, 0.08)
			for i in range(26):
				var radius := sqrt(float(i) / 26.0) * 0.071
				var y := 0.135 - radius * 0.18 - maxf(0, radius - 0.048) * 0.52
				var at := Vector3(cos(i * 2.4) * radius, y, sin(i * 2.4) * radius)
				loft(surface, [Vector2(0.0035, 0), Vector2(0.001, 0.0015)], Color("fff1d0"), 1, 0, at, 5)
		1: # A pale rice cookie, thumb-pressed and dotted with poppy seeds.
			loft(surface, [Vector2(0.002, 0), Vector2(0.089, 0.005), Vector2(0.104, 0.024), Vector2(0.096, 0.045), Vector2(0.059, 0.055), Vector2(0.021, 0.048), Vector2(0.001, 0.047)], Color("f4d79c"), 12, 0.027)
			for i in range(11):
				var radius := 0.008 + (i % 4) * 0.006
				var at := Vector3(cos(i * 2.4) * radius, 0.050, sin(i * 2.4) * radius)
				loft(surface, [Vector2(0.004, 0), Vector2(0.004, 0.003), Vector2(0.001, 0.004)], Color("463a32"), 1, 0.0, at, 6)
		2: # Clover-cut chickpea shortbread with pistachio slivers.
			loft(surface, [Vector2(0.001, 0), Vector2(0.077, 0.002), Vector2(0.082, 0.014), Vector2(0.081, 0.042), Vector2(0.075, 0.051), Vector2(0.001, 0.052)], Color("dbad64"), 4, 0.24)
			for i in range(3):
				var at := Vector3((i - 1) * 0.014, 0.052, sin(i * 3.7) * 0.012)
				loft(surface, [Vector2(0.007, 0), Vector2(0.007, 0.004), Vector2(0.001, 0.007)], Color("799242"), 1, 0, at, 8, 2.0)
	surface.index()
	surface.generate_normals()
	return surface.commit()

static func loft(surface: SurfaceTool, profile: Array, tint: Color, lobes: int, flute: float,
		offset := Vector3.ZERO, segments := 48, depth := 1.0) -> void:
	var vertices := PackedVector3Array()
	var colours := PackedColorArray()
	for ring in range(profile.size()):
		var p: Vector2 = profile[ring]
		for i in range(segments):
			var a := TAU * i / segments
			var r := p.x * (1.0 + flute * cos(a * lobes))
			var shade := 0.88 + 0.10 * float(ring) / (profile.size() - 1) + 0.027 * sin(i * 2.7 + ring)
			colours.append(Color(tint.r * shade, tint.g * shade, tint.b * shade))
			vertices.append(offset + Vector3(cos(a) * r, p.y, sin(a) * r * depth))
	for ring in range(profile.size() - 1):
		for i in range(segments):
			var a := ring * segments + i
			var b := ring * segments + (i + 1) % segments
			for index in [a, b, a + segments, b, b + segments, a + segments]:
				surface.set_color(colours[index])
				surface.add_vertex(vertices[index])

static func box_base(parent: Node3D) -> Node3D:
	var box := Node3D.new()
	parent.add_child(box)
	PoofShapes.box(box, Vector3.ZERO, Vector3(0.56, 0.016, 0.54), PAPER)
	for side in [-1, 1]:
		PoofShapes.box(box, Vector3(side * 0.279, 0.072, 0), Vector3(0.014, 0.16, 0.55), PLUM)
		PoofShapes.box(box, Vector3(0, 0.072, side * 0.269), Vector3(0.56, 0.16, 0.014), PLUM)
		PoofShapes.box(box, Vector3(0, 0.115, side * 0.277), Vector3(0.56, 0.009, 0.002), PAPER)
	return box

static func lid(parent: Node3D) -> Node3D:
	var top := PoofShapes.box(parent, Vector3(0, 0.166, 0), Vector3(0.58, 0.043, 0.56), PAPER)
	PoofShapes.box(top, Vector3(0, 0.023, 0), Vector3(0.056, 0.004, 0.56), PLUM)
	PoofShapes.box(top, Vector3(0, 0.026, 0), Vector3(0.58, 0.004, 0.045), PLUM)
	return top

static func slot(i: int) -> Vector3:
	return Vector3(-0.122 + (i % 2) * 0.245, 0.012, -0.124 + (i / 2) * 0.248)
