class_name PoofShapes
extends RefCounted
## Small reusable helpers. All prototype art is made from original primitives.

static func material(color: Color, glow: float = 0.0) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = color
	result.roughness = 0.85
	if glow > 0.0:
		result.emission_enabled = true
		result.emission = color
		result.emission_energy_multiplier = glow
	return result

static func box(parent: Node3D, at: Vector3, size: Vector3, color: Color,
		collidable: bool = false, glow: float = 0.0) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var shape := BoxMesh.new()
	shape.size = size
	mesh.mesh = shape
	mesh.material_override = material(color, glow)
	parent.add_child(mesh)
	mesh.position = at
	if collidable:
		mesh.add_to_group("level_geometry")
		var body := StaticBody3D.new()
		var collision := CollisionShape3D.new()
		var bounds := BoxShape3D.new()
		bounds.size = size
		collision.shape = bounds
		mesh.add_child(body)
		body.add_child(collision)
	return mesh

static func label(parent: Node3D, at: Vector3, words: String,
		color: Color = Color.WHITE, font_size: int = 44) -> Label3D:
	var result := Label3D.new()
	result.text = words
	result.font_size = font_size
	result.pixel_size = 0.01
	result.modulate = color
	result.outline_size = 5
	parent.add_child(result)
	result.position = at
	return result
