extends CharacterBody3D
## Fictional armed combatant with line-of-sight checks and telegraphed fire.
## Intentionally simple AI: no navigation mesh or sophisticated pathfinding yet.

var game: Node3D
var health := 100
var alive := true
var attack_left := 1.5
var visual: Node3D
var visor: MeshInstance3D
var patrol_origin := Vector3.ZERO
var elapsed := 0.0
var guard_index := 0
var legs: Array[MeshInstance3D] = []
var bark: Label3D
var chase_memory := 0.0
var last_seen := Vector3.ZERO
var path: PackedVector2Array = PackedVector2Array()
var path_left := 0.0

func _ready() -> void:
	collision_layer = 4
	collision_mask = 1 | 2 | 4
	patrol_origin = position
	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.36
	capsule.height = 1.8
	collision.shape = capsule
	collision.position.y = 0.9
	add_child(collision)
	visual = Node3D.new()
	add_child(visual)
	PoofShapes.box(visual, Vector3(0, 1.05, 0), Vector3(0.64, 0.65, 0.34), Color("5f5961"))
	PoofShapes.box(visual, Vector3(0, 1.63, 0), Vector3(0.7, 0.58, 0.54), Color("b79887"))
	PoofShapes.box(visual, Vector3(0, 1.97, 0), Vector3(0.83, 0.13, 0.68), Color("31333e"))
	visor = PoofShapes.box(visual, Vector3(0, 1.64, -0.285), Vector3(0.58, 0.13, 0.025), Color("ed8575"), false, 1.2)
	for side in [-1.0, 1.0]:
		PoofShapes.box(visual, Vector3(side * 0.17, 1.66, -0.31), Vector3(0.15, 0.15, 0.05), Color("fff4d8"))
		PoofShapes.box(visual, Vector3(side * 0.17, 1.64, -0.35), Vector3(0.055, 0.07, 0.03), Color("121823"))
	for side in [-1.0, 1.0]:
		legs.append(PoofShapes.box(visual, Vector3(side * 0.19, 0.36, 0), Vector3(0.23, 0.7, 0.28), Color("292e38")))
		PoofShapes.box(visual, Vector3(side * 0.4, 1.03, -0.06), Vector3(0.18, 0.56, 0.23), Color("5f5961"))
	PoofShapes.box(visual, Vector3(0.26, 1.04, -0.4), Vector3(0.14, 0.15, 0.62), Color("181f2b"))
	bark = PoofShapes.label(self, Vector3(0, 2.65, 0), "", Color("f9d7a0"), 24)
	bark.billboard = BaseMaterial3D.BILLBOARD_ENABLED

func _physics_process(delta: float) -> void:
	if not alive or not game.active:
		return
	elapsed += delta
	var target: Vector3 = game.player.global_position
	var flat := Vector3(target.x, global_position.y, target.z)
	var distance := global_position.distance_to(target)
	var visible := can_see_player()
	if distance < 23.0 and visible:
		chase_memory = 6.0
		last_seen = target
	else:
		chase_memory = maxf(0.0, chase_memory - delta)
	if chase_memory > 0.0:
		if flat.distance_to(global_position) > 0.01:
			look_at(flat, Vector3.UP)
		path_left -= delta
		if path_left <= 0.0:
			path_left = 0.35
			path = game.chase_path(global_position, last_seen)
		var waypoint := last_seen
		if path.size() > 1:
			waypoint = Vector3(path[1].x, global_position.y, path[1].y)
		var toward := waypoint - global_position
		toward.y = 0
		toward = toward.normalized()
		velocity.x = toward.x * (3.5 if distance > 2.3 else 0.0)
		velocity.z = toward.z * (3.5 if distance > 2.3 else 0.0)
		# Ranged attacks remain slow and telegraphed while the guards pursue.
		if visible:
			attack_left -= delta
		visor.material_override.albedo_color = Color("fff1c2") if attack_left < 0.4 else Color("ed8575")
		bark.text = ["STOP! YOU NEED A FORM!", "RUNNING IS NOT APPROVED!", "I AM THE MANAGER!"][guard_index % 3]
		if attack_left <= 0.0 and visible:
			attack_left = 2.1
			game.tracer(global_position + Vector3(0, 1.25, 0), game.player.camera.global_position, Color("ff726e"))
			game.player.take_damage(8)
	else:
		attack_left = 1.2
		bark.text = ""
		var patrol_target := patrol_origin + Vector3(sin(elapsed * 0.35) * 1.8, 0, 0)
		var drift := patrol_target - global_position
		drift.y = 0
		velocity.x = clampf(drift.x, -0.8, 0.8)
		velocity.z = clampf(drift.z, -0.8, 0.8)
		if drift.length() > 0.1:
			look_at(global_position + drift, Vector3.UP)
	if not is_on_floor():
		velocity.y -= 22.0 * delta
	move_and_slide()
	var running := Vector2(velocity.x, velocity.z).length() > 0.3
	visual.rotation.z = sin(elapsed * 13.0) * 0.11 if running else 0.0
	visual.position.y = absf(sin(elapsed * 13.0)) * 0.06 if running else 0.0
	for i in range(legs.size()):
		legs[i].rotation.x = sin(elapsed * 13.0 + i * PI) * 0.6 if running else 0.0

func can_see_player() -> bool:
	var from := global_position + Vector3(0, 1.5, 0)
	var query := PhysicsRayQueryParameters3D.create(from, game.player.camera.global_position, 1 | 2, [get_rid()])
	var result := get_world_3d().direct_space_state.intersect_ray(query)
	return not result.is_empty() and result.collider == game.player

func take_damage(amount: int, point: Vector3) -> void:
	if not alive:
		return
	health -= amount
	game.impact(point, true)
	if health <= 0:
		alive = false
		bark.text = "ON AN UNSCHEDULED BREAK."
		visual.rotation = Vector3.ZERO
		collision_layer = 0
		collision_mask = 0
		game.guards_defeated += 1
		var tween := create_tween()
		tween.tween_property(visual, "rotation:x", -PI / 2.0, 0.3)
		tween.parallel().tween_property(visual, "position:y", 0.22, 0.3)
		# Bodies stay in the level; no smoke or disappearing death effect.
