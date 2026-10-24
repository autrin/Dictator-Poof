extends RefCounted
## Authored routes with swept collision, plus poses derived from the standing model.
const Person := preload("res://scripts/person_visual.gd")
var routes: Dictionary = {}
var walked: Dictionary = {}

func walk(actor: Node3D, points: Array, speed: float = 1.5) -> void:
	Person.stand(actor)
	routes[actor] = {"points": points.duplicate(), "speed": speed}
	walked[actor] = 0.0

func busy(actor: Node3D) -> bool:
	return routes.has(actor)

func tick(delta: float, player: CharacterBody3D) -> void:
	for actor: Node3D in routes.keys():
		var route: Dictionary = routes[actor]
		var to: Vector3 = route.points[0] - actor.position
		to.y = 0
		if to.length() < 0.06:
			route.points.pop_front()
			if route.points.is_empty():
				routes.erase(actor)
				Person.stand(actor)
			continue
		var motion := to.normalized() * minf(to.length(), route.speed * delta)
		# Leave personal space rather than letting an animated body push the player.
		var separation: Vector3 = actor.global_position - player.global_position
		var horizontal := Vector2(separation.x, separation.z)
		var next := horizontal + Vector2(motion.x, motion.z)
		if player.collision_layer != 0 and absf(separation.y) < 1.7 and next.length() < 0.68 and next.length() < horizontal.length():
			Person.walk_pose(actor, walked[actor], 0)
			continue
		var body: AnimatableBody3D = actor.get_node("Body collider")
		var collider: CollisionShape3D = body.get_child(0)
		var query := PhysicsShapeQueryParameters3D.new()
		query.shape = collider.shape
		query.transform = collider.global_transform
		query.motion = motion
		query.collision_mask = 3
		query.exclude = [body.get_rid()]
		var safe := actor.get_world_3d().direct_space_state.cast_motion(query)
		motion *= safe[0]
		actor.position += motion
		actor.rotation.y = lerp_angle(actor.rotation.y, atan2(-to.x, -to.z), minf(8 * delta, 1))
		walked[actor] += motion.length()
		Person.walk_pose(actor, walked[actor] * 5, minf(motion.length() / maxf(delta, 0.001), 1.0))

static func face(actor: Node3D, toward: Vector3) -> void:
	var direction := toward - actor.position
	actor.rotation.y = atan2(-direction.x, -direction.z)
