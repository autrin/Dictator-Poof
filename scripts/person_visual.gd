extends RefCounted
## Reusable, stylized adult figure with distinct proportions, face, and hair.

static func build(parent: Node3D, clothes: Color, skin: Color, hair: Color, style: int, scarf: bool = false, tattoo: bool = false) -> void:
	# All pieces belong to the character root so existing scene animation can move it.
	var body := AnimatableBody3D.new()
	body.name = "Body collider"
	# The character root is animated directly; keep this child at the root's transform.
	body.sync_to_physics = false
	body.collision_layer = 1
	body.collision_mask = 0
	parent.add_child(body)
	var collision := CollisionShape3D.new()
	var capsule_shape := CapsuleShape3D.new()
	capsule_shape.radius = 0.28
	capsule_shape.height = 1.7
	collision.shape = capsule_shape
	collision.position.y = 0.9
	body.add_child(collision)
	sphere(parent, "Pelvis", Vector3(0, 0.91, 0), Vector3(0.34, 0.26, 0.25), clothes.darkened(0.14))
	tailored_torso(parent, clothes)
	sphere(parent, "Neck", Vector3(0, 1.51, 0), Vector3(0.16, 0.2, 0.15), skin)
	sphere(parent, "Head", Vector3(0, 1.72, 0), Vector3(0.265, 0.34, 0.27), skin)
	for side in [-1, 1]:
		sphere(parent, "Ear", Vector3(side * 0.139, 1.72, 0), Vector3(0.046, 0.08, 0.045), skin)
		var upper_arm := Node3D.new()
		upper_arm.name = "Left arm" if side < 0 else "Right arm"
		upper_arm.set_meta("part", str(upper_arm.name))
		upper_arm.position = Vector3(side * 0.235, 1.43, 0)
		upper_arm.rotation.z = side * 0.1
		parent.add_child(upper_arm)
		capsule(upper_arm, "Sleeve", Vector3(0, -0.16, 0), 0.075, 0.34, clothes)
		var forearm := Node3D.new()
		forearm.name = "Forearm"
		forearm.position = Vector3(0, -0.32, 0)
		upper_arm.add_child(forearm)
		capsule(forearm, "Skin", Vector3(0, -0.145, 0), 0.055, 0.29, skin)
		sphere(forearm, "Left hand" if side < 0 else "Right hand", Vector3(0, -0.33, 0), Vector3(0.08, 0.14, 0.055), skin)
		capsule(parent, "Thigh", Vector3(side * 0.1, 0.69, 0), 0.093, 0.47, clothes.darkened(0.18))
		capsule(parent, "Shin", Vector3(side * 0.1, 0.3, 0.01), 0.067, 0.44, clothes.darkened(0.23))
		sphere(parent, "Shoe", Vector3(side * 0.1, 0.065, -0.065), Vector3(0.14, 0.13, 0.28), Color("302e34"))
		sphere(parent, "Eye", Vector3(side * 0.056, 1.755, -0.125), Vector3(0.021, 0.012, 0.013), Color("29232a"))
		sphere(parent, "Brow", Vector3(side * 0.058, 1.78, -0.12), Vector3(0.047, 0.009, 0.012), hair)
	sphere(parent, "Nose", Vector3(0, 1.71, -0.139), Vector3(0.038, 0.068, 0.039), skin.darkened(0.04))
	sphere(parent, "Smile", Vector3(0, 1.651, -0.124), Vector3(0.068, 0.012, 0.012), Color("98665c"))
	build_hair(parent, hair, style, scarf)
	if tattoo:
		PoofShapes.box(parent.get_node("Right arm/Forearm"), Vector3(0, 0, -0.055), Vector3(0.04, 0.1, 0.006), Color("344457"))
	for side in [-1, 1]:
		var tear := sphere(parent, "Tear left" if side < 0 else "Tear right", Vector3(side * 0.061, 1.705, -0.133), Vector3(0.019, 0.05, 0.013), Color("8bcad1"))
		tear.visible = false
	remember_pose(parent)

static func remember_pose(parent: Node3D) -> void:
	var rest: Dictionary = {}
	for part in parent.get_children():
		if part is Node3D and not part is PhysicsBody3D:
			rest[part] = part.transform
	parent.set_meta("standing_pose", rest)

static func stand(parent: Node3D) -> void:
	var rest: Dictionary = parent.get_meta("standing_pose")
	for part: Node3D in rest:
		part.transform = rest[part]
	for side in ["Left", "Right"]:
		parent.get_node(side + " arm/Forearm").rotation = Vector3.ZERO
	var collision: CollisionShape3D = parent.get_node("Body collider").get_child(0)
	collision.shape.height = 1.7
	collision.position.y = 0.9

static func walk_pose(parent: Node3D, phase: float, amount: float) -> void:
	var rest: Dictionary = parent.get_meta("standing_pose")
	for part: Node3D in rest:
		var original: Transform3D = rest[part]
		var kind: String = part.get_meta("part", "")
		var side := -1.0 if original.origin.x < 0 else 1.0
		var swing := sin(phase) * side * 0.32 * amount
		if kind in ["Thigh", "Shin", "Shoe"]:
			var hip := Vector3(original.origin.x, 0.9, 0)
			part.position = hip + Basis(Vector3.RIGHT, swing) * (original.origin - hip)
			part.rotation.x = swing
		elif kind in ["Left arm", "Right arm"]:
			part.rotation.x = -swing * 0.75

static func build_hair(parent: Node3D, hair: Color, style: int, scarf: bool) -> void:
	sphere(parent, "Hair crown", Vector3(0, 1.855, 0.025), Vector3(0.278, 0.13, 0.275), hair)
	match style % 5:
		0:
			for i in range(7):
				var angle := i * TAU / 7
				sphere(parent, "Curl", Vector3(cos(angle) * 0.095, 1.905, sin(angle) * 0.07), Vector3(0.067, 0.045, 0.07), hair)
		1:
			sphere(parent, "Hair back", Vector3(0, 1.65, 0.09), Vector3(0.29, 0.53, 0.15), hair)
			for side in [-1, 1]:
				var lock := sphere(parent, "Wave", Vector3(side * 0.135, 1.67, 0.015), Vector3(0.09, 0.47, 0.16), hair)
				lock.rotation.z = side * 0.08
		2:
			sphere(parent, "Hair tie", Vector3(0, 1.78, 0.145), Vector3(0.08, 0.055, 0.08), Color("a77964"))
			sphere(parent, "Ponytail", Vector3(0, 1.59, 0.17), Vector3(0.11, 0.39, 0.12), hair)
		3:
			sphere(parent, "Hair back", Vector3(0, 1.71, 0.08), Vector3(0.31, 0.34, 0.19), hair)
			for side in [-1, 1]:
				sphere(parent, "Ringlet", Vector3(side * 0.14, 1.73, -0.005), Vector3(0.095, 0.28, 0.16), hair)
		4:
			var sweep := sphere(parent, "Side sweep", Vector3(-0.035, 1.853, -0.067), Vector3(0.22, 0.09, 0.14), hair)
			sweep.rotation.z = -0.22
	if scarf:
		sphere(parent, "Loose scarf", Vector3(0, 1.84, 0.05), Vector3(0.3, 0.11, 0.28), Color("a8899a"))

static func tailored_torso(parent: Node3D, color: Color) -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rings := [Vector3(0.165, 0.96, 0.125), Vector3(0.145, 1.12, 0.12), Vector3(0.215, 1.4, 0.135), Vector3(0.085, 1.48, 0.075)]
	for level in range(rings.size() - 1):
		for segment in range(16):
			var points: Array[Vector3] = []
			for pair in [Vector2i(level, segment), Vector2i(level + 1, segment), Vector2i(level + 1, segment + 1), Vector2i(level, segment + 1)]:
				var r: Vector3 = rings[pair.x]
				var angle: float = pair.y * TAU / 16
				points.append(Vector3(cos(angle) * r.x, r.y, sin(angle) * r.z))
			for index in [0, 2, 1, 0, 3, 2]:
				surface.add_vertex(points[index])
	surface.generate_normals()
	var mesh := MeshInstance3D.new()
	mesh.name = "Torso"
	mesh.mesh = surface.commit()
	mesh.material_override = PoofShapes.material(color)
	parent.add_child(mesh)

static func sit(parent: Node3D) -> void:
	# Bend at hips and knees; feet remain on the floor.
	stand(parent)
	for child: Node3D in parent.get_meta("standing_pose"):
		if child is Node3D and not child is PhysicsBody3D:
			if child.get_meta("part", "") == "Thigh":
				child.position.y = 0.54
				child.position.z = -0.2
				child.rotation.x = PI / 2
			elif child.get_meta("part", "") == "Shin":
				child.position = Vector3(child.position.x, 0.29, -0.4)
			elif child.get_meta("part", "") == "Shoe":
				child.position.z = -0.46
			else:
				child.position.y -= 0.38
	var collision := parent.get_node("Body collider").get_child(0) as CollisionShape3D
	collision.shape.height = 1.35
	collision.position.y = 0.7

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
	mesh.set_meta("part", name)
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
	mesh.set_meta("part", name)
	return mesh
