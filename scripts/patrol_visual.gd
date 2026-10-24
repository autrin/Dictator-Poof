extends RefCounted
const Person := preload("res://scripts/person_visual.gd")

static func van(parent: Node3D) -> Node3D:
	var van := Node3D.new()
	van.name = "Morality police van"
	parent.add_child(van)
	var van_body := AnimatableBody3D.new()
	van_body.name = "Van collider"
	# The van root moves during the encounter, so its child collider follows it.
	van_body.sync_to_physics = false
	van_body.collision_layer = 1
	van_body.collision_mask = 0
	van.add_child(van_body)
	var van_collision := CollisionShape3D.new()
	var van_shape := BoxShape3D.new()
	van_shape.size = Vector3(2.55, 2.1, 4.5)
	van_collision.shape = van_shape
	van_collision.position.y = 1.13
	van_body.add_child(van_collision)
	PoofShapes.box(van, Vector3(0, 1.13, 0), Vector3(2.55, 2.1, 4.5), Color("deded8"))
	PoofShapes.box(van, Vector3(0, 2.16, 0.55), Vector3(2.5, 0.16, 3.15), Color("f3f1e9"))
	for side in [-1, 1]:
		PoofShapes.box(van, Vector3(side * 1.28, 1.17, 0), Vector3(0.035, 0.44, 4.36), Color("15966b"))
		for z in [-1.2, 0.05, 1.3]:
			PoofShapes.box(van, Vector3(side * 1.31, 1.75, z), Vector3(0.045, 0.57, 0.95), Color("273b44"))
		for z in [-1.55, 1.55]:
			Person.sphere(van, "Wheel", Vector3(side * 1.25, 0.47, z), Vector3(0.38, 0.75, 0.75), Color("24282a"))
	PoofShapes.box(van, Vector3(0, 1.68, -2.26), Vector3(2.1, 0.7, 0.04), Color("283f49"))
	for x in [-0.92, 0.92]:
		PoofShapes.box(van, Vector3(x, 0.72, -2.28), Vector3(0.37, 0.22, 0.06), Color("f4e8b2"))
	var van_sign := PoofShapes.label(van, Vector3(-1.34, 1.16, 0.05), "", Color("f0e5ae"), 35)
	van_sign.name = "Patrol sign"
	van_sign.font = preload("res://assets/fonts/vazirmatn/Vazirmatn.ttf")
	van_sign.rotation.y = -PI / 2.0
	van_sign.pixel_size = 0.006
	var other_sign := van_sign.duplicate() as Label3D
	other_sign.name = "Patrol sign right"
	other_sign.position.x = 1.34
	other_sign.rotation.y = PI / 2
	van.add_child(other_sign)
	return van

static func officer(parent: Node3D) -> Node3D:
	var actor := Node3D.new()
	actor.name = "Morality patrol officer"
	parent.add_child(actor)
	Person.build(actor, Color("53624b"), Color("ba8e70"), Color("282b27"), 0)
	Person.sphere(actor, "Uniform cap", Vector3(0, 1.91, 0), Vector3(0.31, 0.12, 0.3), Color("394934"))
	PoofShapes.box(actor, Vector3(0, 1.88, -0.14), Vector3(0.25, 0.024, 0.17), Color("394934"))
	PoofShapes.box(actor, Vector3(0, 1.02, -0.012), Vector3(0.34, 0.06, 0.26), Color("292d27"))
	PoofShapes.box(actor, Vector3(0.095, 1.34, -0.135), Vector3(0.065, 0.085, 0.015), Color("b6aa70"))
	PoofShapes.box(actor, Vector3(-0.12, 1.29, -0.15), Vector3(0.07, 0.13, 0.035), Color("202a25"))
	for x in [-0.21, 0.21]:
		PoofShapes.box(actor, Vector3(x, 1.41, 0), Vector3(0.07, 0.025, 0.13), Color("bdac70"))
	Person.remember_pose(actor)
	return actor
