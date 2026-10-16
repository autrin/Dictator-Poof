extends RefCounted
## Reusable, stylized adult figure with distinct proportions, face, and hair.

static func build(parent: Node3D, clothes: Color, skin: Color, hair: Color, style: int, scarf: bool = false, tattoo: bool = false) -> void:
	# All pieces belong to the character root so existing scene animation can move it.
	sphere(parent, "Pelvis", Vector3(0, 0.83, 0), Vector3(0.42, 0.27, 0.29), clothes.darkened(0.14))
	sphere(parent, "Torso", Vector3(0, 1.13, 0), Vector3(0.49, 0.72, 0.32), clothes)
	sphere(parent, "Neck", Vector3(0, 1.51, 0), Vector3(0.16, 0.2, 0.15), skin)
	sphere(parent, "Head", Vector3(0, 1.73, 0), Vector3(0.33, 0.43, 0.32), skin)
	for side in [-1, 1]:
		sphere(parent, "Ear", Vector3(side * 0.17, 1.72, 0), Vector3(0.07, 0.12, 0.06), skin)
		var upper_arm := capsule(parent, "Left arm" if side < 0 else "Right arm", Vector3(side * 0.34, 1.11, 0), 0.11, 0.49, clothes)
		upper_arm.rotation.z = side * 0.12
		capsule(parent, "Forearm", Vector3(side * 0.39, 0.79, -0.02), 0.085, 0.35, skin)
		sphere(parent, "Left hand" if side < 0 else "Right hand", Vector3(side * 0.4, 0.59, -0.02), Vector3(0.11, 0.15, 0.09), skin)
		capsule(parent, "Thigh", Vector3(side * 0.13, 0.61, 0), 0.15, 0.46, clothes.darkened(0.18))
		capsule(parent, "Shin", Vector3(side * 0.13, 0.28, 0.01), 0.105, 0.42, Color("39424a"))
		sphere(parent, "Shoe", Vector3(side * 0.13, 0.08, -0.09), Vector3(0.23, 0.14, 0.36), Color("302e34"))
		sphere(parent, "Eye", Vector3(side * 0.082, 1.77, -0.151), Vector3(0.035, 0.037, 0.02), Color("29232a"))
		if not scarf:
			make_hair_lock(parent, Vector3(side * 0.18, 1.63, 0.06), style, hair)
	sphere(parent, "Nose", Vector3(0, 1.69, -0.17), Vector3(0.055, 0.085, 0.05), skin.darkened(0.08))
	sphere(parent, "Smile", Vector3(0, 1.59, -0.151), Vector3(0.14, 0.023, 0.015), Color("884f4d"))
	build_hair(parent, hair, style, scarf)
	if tattoo:
		PoofShapes.box(parent, Vector3(0.4, 0.78, -0.11), Vector3(0.08, 0.15, 0.018), Color("344457"))
	for side in [-1, 1]:
		var tear := sphere(parent, "Tear left" if side < 0 else "Tear right", Vector3(side * 0.11, 1.65, -0.166), Vector3(0.04, 0.1, 0.025), Color("8bcad1"))
		tear.visible = false

static func build_hair(parent: Node3D, hair: Color, style: int, scarf: bool) -> void:
	sphere(parent, "Hair crown", Vector3(0, 1.94, 0.02), Vector3(0.36, 0.22, 0.35), hair)
	match style % 5:
		0: # short curls
			for i in range(9):
				var angle := float(i) / 9.0 * TAU
				sphere(parent, "Curl", Vector3(cos(angle) * 0.15, 2.02 + sin(i * 2.0) * 0.035, sin(angle) * 0.12), Vector3(0.11, 0.12, 0.11), hair.lightened(0.05))
		1: # long waves
			for side in [-1, 1]:
				for segment in range(4):
					sphere(parent, "Wave", Vector3(side * (0.18 + sin(segment * 1.5) * 0.03), 1.81 - segment * 0.14, 0.06), Vector3(0.14, 0.22, 0.15), hair.lightened(segment * 0.025))
		2: # tied back
			sphere(parent, "Hair tie", Vector3(0, 1.88, 0.23), Vector3(0.14, 0.11, 0.13), Color("c68d68"))
			for segment in range(3):
				sphere(parent, "Ponytail", Vector3(0.02, 1.75 - segment * 0.15, 0.29 + segment * 0.045), Vector3(0.15, 0.2, 0.14), hair)
		3: # shoulder-length curls
			for side in [-1, 1]:
				for segment in range(3):
					sphere(parent, "Ringlet", Vector3(side * 0.2, 1.83 - segment * 0.16, 0.01), Vector3(0.16, 0.17, 0.16), hair.lightened(0.035 * segment))
		4: # side part
			sphere(parent, "Side sweep", Vector3(-0.09, 1.93, -0.09), Vector3(0.26, 0.16, 0.18), hair.lightened(0.08))
			sphere(parent, "Side lock", Vector3(0.19, 1.81, -0.04), Vector3(0.12, 0.22, 0.12), hair)
	if scarf:
		sphere(parent, "Loose scarf", Vector3(0, 1.98, 0.09), Vector3(0.4, 0.13, 0.34), Color("a8899a"))

static func make_hair_lock(parent: Node3D, at: Vector3, style: int, hair: Color) -> void:
	if style % 5 == 0 or style % 5 == 4:
		return
	sphere(parent, "Hair framing face", at, Vector3(0.11, 0.24, 0.12), hair)

static func sphere(parent: Node3D, name: String, at: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var shape := SphereMesh.new()
	shape.radius = 0.5
	shape.height = 1.0
	shape.radial_segments = 16
	shape.rings = 8
	mesh.name = name
	mesh.mesh = shape
	mesh.position = at
	mesh.scale = size
	mesh.material_override = PoofShapes.material(color)
	parent.add_child(mesh)
	return mesh

static func capsule(parent: Node3D, name: String, at: Vector3, radius: float, height: float, color: Color) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var shape := CapsuleMesh.new()
	shape.radius = radius
	shape.height = height
	mesh.name = name
	mesh.mesh = shape
	mesh.position = at
	mesh.material_override = PoofShapes.material(color)
	parent.add_child(mesh)
	return mesh
