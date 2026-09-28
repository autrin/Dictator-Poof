extends CharacterBody3D
## Physics and aiming live here; mission rules live in game.gd.

const SPEED := 5.0
const SPRINT_SPEED := 7.5
const MAGAZINE := 12
const FIRE_INTERVAL := 0.22

var game: Node3D
var camera: Camera3D
var weapon: Node3D
var health := 100
var ammo := MAGAZINE
var reload_left := 0.0
var fire_left := 0.0
var recoil := 0.0
var collider: CollisionShape3D

func _ready() -> void:
	collision_layer = 2
	collision_mask = 1 | 4
	collider = CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.32
	capsule.height = 1.8
	collider.shape = capsule
	collider.position.y = 0.9
	add_child(collider)
	camera = Camera3D.new()
	camera.position.y = 1.62
	camera.fov = 80
	camera.current = true
	camera.near = 0.05
	add_child(camera)
	var flashlight := SpotLight3D.new()
	flashlight.light_color = Color("e0e7ee")
	flashlight.light_energy = 2.0
	flashlight.spot_range = 24.0
	flashlight.spot_angle = 35.0
	flashlight.shadow_enabled = true
	camera.add_child(flashlight)
	weapon = Node3D.new()
	camera.add_child(weapon)
	weapon.position = Vector3(0.3, -0.25, -0.52)
	PoofShapes.box(weapon, Vector3.ZERO, Vector3(0.14, 0.16, 0.4), Color("34444c"))
	PoofShapes.box(weapon, Vector3(0, -0.12, 0.1), Vector3(0.11, 0.24, 0.13), Color("17232e"))
	PoofShapes.box(weapon, Vector3(0, 0.09, -0.1), Vector3(0.035, 0.025, 0.15), Color("75e1ce"), false, 1.0)

func _unhandled_input(event: InputEvent) -> void:
	if not game.active or Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * game.sensitivity)
		camera.rotation.x = clampf(camera.rotation.x - event.relative.y * game.sensitivity, -1.45, 1.45)

func _physics_process(delta: float) -> void:
	if not game.active:
		return
	fire_left = maxf(0.0, fire_left - delta)
	if reload_left > 0.0:
		reload_left = maxf(0.0, reload_left - delta)
		if reload_left == 0.0:
			ammo = MAGAZINE
	if Input.is_action_just_pressed("reload"):
		reload()
	if Input.is_action_pressed("fire"):
		shoot()
	if Input.is_action_just_pressed("interact"):
		game.interact()
	var direction := Input.get_vector("left", "right", "forward", "back")
	var world_direction := transform.basis * Vector3(direction.x, 0, direction.y)
	var speed := SPRINT_SPEED if Input.is_action_pressed("sprint") else SPEED
	var crouching := Input.is_action_pressed("crouch")
	if crouching:
		speed = 2.8
	camera.position.y = move_toward(camera.position.y, 0.92 if crouching else 1.62, delta * 6.0)
	collider.shape.height = 1.1 if crouching else 1.8
	collider.position.y = 0.55 if crouching else 0.9
	velocity.x = world_direction.x * speed
	velocity.z = world_direction.z * speed
	if not is_on_floor():
		velocity.y -= 22.0 * delta
	elif Input.is_action_just_pressed("jump"):
		velocity.y = 6.5
	move_and_slide()
	recoil = move_toward(recoil, 0.0, delta * 0.5)
	weapon.position.z = -0.52 + recoil
	weapon.rotation.x = -0.55 * (reload_left / 1.25)
	if global_position.y < -10.0:
		take_damage(100)

func reload() -> void:
	if reload_left <= 0.0 and ammo < MAGAZINE:
		reload_left = 1.25
		game.play_tone(260.0, 0.09, 0.15)

func shoot() -> void:
	if not game.active or fire_left > 0.0 or reload_left > 0.0:
		return
	if ammo <= 0:
		reload()
		return
	ammo -= 1
	fire_left = FIRE_INTERVAL
	recoil = 0.075
	game.play_tone(95.0, 0.07, 0.25)
	var from := camera.global_position
	var to := from - camera.global_basis.z * 65.0
	var query := PhysicsRayQueryParameters3D.create(from, to, 1 | 4, [get_rid()])
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		to = hit.position
		if hit.collider.has_method("take_damage"):
			hit.collider.take_damage(34, hit.position)
			game.hit_marker = 0.12
		else:
			game.impact(hit.position, false)
	game.tracer(weapon.global_position - camera.global_basis.z * 0.2, to, Color("f6d995"))

func take_damage(amount: int) -> void:
	if not game.active:
		return
	health = maxi(0, health - amount)
	game.hurt_flash = 0.28
	if health == 0:
		game.finish(false)
