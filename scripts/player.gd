extends CharacterBody3D
## Physics and aiming live here; mission rules live in game.gd.

const SPEED := 5.0
const SPRINT_SPEED := 7.5
const MAGAZINE := 12
const FIRE_INTERVAL := 0.22

var game: Node3D
var camera: Camera3D
var weapon: Node3D
var empty_hands: Node3D
var muzzle_tip: Marker3D
var muzzle_flash: Node3D
var gun_drawn := true
var health := 100
var ammo := MAGAZINE
var reload_left := 0.0
var fire_left := 0.0
var recoil := 0.0
var muzzle_flash_left := 0.0
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
	flashlight.shadow_bias = 0.05
	flashlight.shadow_normal_bias = 2.0
	camera.add_child(flashlight)
	weapon = Node3D.new()
	weapon.name = "Held gun"
	camera.add_child(weapon)
	weapon.position = Vector3(0.3, -0.25, -0.52)
	build_gun()
	empty_hands = Node3D.new()
	empty_hands.name = "Empty hands"
	camera.add_child(empty_hands)
	build_hand(empty_hands, -1, Vector3(-0.29, -0.36, -0.65))
	build_hand(empty_hands, 1, Vector3(0.29, -0.36, -0.65))
	update_viewmodel()

func build_gun() -> void:
	var steel := Color("343d46")
	var dark := Color("171d25")
	var brass := Color("c58c4c")
	var glow := Color("65e6db")
	# Slide, exposed barrel, and frame form a readable pistol silhouette.
	PoofShapes.box(weapon, Vector3(0, 0.035, -0.055), Vector3(0.18, 0.13, 0.49), steel)
	PoofShapes.box(weapon, Vector3(0, -0.055, 0.015), Vector3(0.16, 0.09, 0.34), dark)
	PoofShapes.box(weapon, Vector3(0, 0.035, -0.315), Vector3(0.12, 0.105, 0.11), brass)
	var muzzle := CylinderMesh.new()
	muzzle.top_radius = 0.057
	muzzle.bottom_radius = 0.057
	muzzle.height = 0.13
	var barrel := MeshInstance3D.new()
	barrel.mesh = muzzle
	barrel.material_override = PoofShapes.material(dark)
	barrel.position = Vector3(0, 0.035, -0.37)
	barrel.rotation.x = PI / 2.0
	weapon.add_child(barrel)
	PoofShapes.box(weapon, Vector3(0, -0.175, 0.13), Vector3(0.12, 0.24, 0.16), dark)
	PoofShapes.box(weapon, Vector3(0, -0.295, 0.13), Vector3(0.15, 0.035, 0.18), steel)
	# The open trigger guard and rear slide serrations keep the small model legible.
	for z in [-0.13, 0.09]:
		PoofShapes.box(weapon, Vector3(0, -0.15, z), Vector3(0.025, 0.1, 0.025), steel)
	PoofShapes.box(weapon, Vector3(0, -0.2, -0.02), Vector3(0.025, 0.025, 0.25), steel)
	PoofShapes.box(weapon, Vector3(0, -0.12, 0.015), Vector3(0.025, 0.065, 0.025), brass)
	for z in [0.065, 0.105, 0.145]:
		for side in [-1, 1]:
			PoofShapes.box(weapon, Vector3(side * 0.093, 0.04, z), Vector3(0.008, 0.09, 0.013), dark)
	for side in [-1, 1]:
		PoofShapes.box(weapon, Vector3(side * 0.095, -0.175, 0.13), Vector3(0.012, 0.16, 0.1), brass.darkened(0.25))
		PoofShapes.box(weapon, Vector3(side * 0.092, 0.055, -0.13), Vector3(0.009, 0.018, 0.24), brass)
	PoofShapes.box(weapon, Vector3(0, 0.12, 0.16), Vector3(0.105, 0.045, 0.045), dark)
	PoofShapes.box(weapon, Vector3(0, 0.125, -0.265), Vector3(0.075, 0.045, 0.04), dark)
	PoofShapes.box(weapon, Vector3(0, 0.152, -0.265), Vector3(0.025, 0.009, 0.026), glow, false, 0.7)
	PoofShapes.box(weapon, Vector3(0, 0.107, -0.055), Vector3(0.035, 0.012, 0.21), glow, false, 0.45)
	muzzle_tip = Marker3D.new()
	muzzle_tip.position = Vector3(0, 0.035, -0.45)
	weapon.add_child(muzzle_tip)
	muzzle_flash = Node3D.new()
	muzzle_tip.add_child(muzzle_flash)
	PoofShapes.box(muzzle_flash, Vector3(0, 0, -0.045), Vector3(0.035, 0.035, 0.09), Color("ffe3a0"), false, 2.0)
	PoofShapes.box(muzzle_flash, Vector3(0, 0, -0.025), Vector3(0.09, 0.015, 0.055), Color("ff9a5b"), false, 1.5)
	muzzle_flash.hide()
	# A visible right hand grips the pistol, with a left hand supporting it.
	build_hand(weapon, 1, Vector3(0.12, -0.27, 0.14))
	build_hand(weapon, -1, Vector3(-0.17, -0.2, -0.07))

func build_hand(parent: Node3D, side: int, at: Vector3) -> void:
	var skin := Color("bd8b6e")
	var sleeve := Color("4c5961")
	PoofShapes.box(parent, at + Vector3(side * 0.035, -0.17, 0.13), Vector3(0.19, 0.25, 0.22), sleeve)
	PoofShapes.box(parent, at + Vector3(0, -0.07, 0.03), Vector3(0.16, 0.08, 0.14), Color("b58a57"))
	add_hand_curve(parent, at, Vector3(0.105, 0.115, 0.07), skin)
	for finger in range(4):
		var x := at.x + (float(finger) - 1.5) * 0.044
		add_hand_curve(parent, Vector3(x, at.y + 0.105, at.z - 0.065), Vector3(0.022, 0.065 - finger * 0.004, 0.025), skin)
	add_hand_curve(parent, at + Vector3(side * 0.095, 0.015, -0.035), Vector3(0.038, 0.06, 0.035), skin)

func add_hand_curve(parent: Node3D, at: Vector3, size: Vector3, color: Color) -> void:
	var part := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 1.0
	mesh.height = 2.0
	part.mesh = mesh
	part.material_override = PoofShapes.material(color)
	part.position = at
	part.scale = size
	parent.add_child(part)

func set_gun_drawn(value: bool) -> void:
	gun_drawn = value and not game.victory
	update_viewmodel()

func update_viewmodel() -> void:
	weapon.visible = gun_drawn and not game.victory
	empty_hands.visible = not weapon.visible

func _unhandled_input(event: InputEvent) -> void:
	if not game.active or Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * game.sensitivity)
		camera.rotation.x = clampf(camera.rotation.x - event.relative.y * game.sensitivity, -1.45, 1.45)

func _physics_process(delta: float) -> void:
	if not game.active:
		return
	if Input.is_action_just_pressed("holster"):
		set_gun_drawn(not gun_drawn)
	fire_left = maxf(0.0, fire_left - delta)
	muzzle_flash_left = maxf(0.0, muzzle_flash_left - delta)
	muzzle_flash.visible = muzzle_flash_left > 0.0
	if reload_left > 0.0:
		reload_left = maxf(0.0, reload_left - delta)
		if reload_left == 0.0:
			ammo = MAGAZINE
	if gun_drawn and Input.is_action_just_pressed("reload"):
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
	if not game.active or game.victory or not gun_drawn or fire_left > 0.0 or reload_left > 0.0:
		return
	if ammo <= 0:
		reload()
		return
	ammo -= 1
	fire_left = FIRE_INTERVAL
	recoil = 0.075
	muzzle_flash_left = 0.055
	muzzle_flash.show()
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
	game.tracer(muzzle_tip.global_position, to, Color("f6d995"))

func take_damage(amount: int) -> void:
	if not game.active or game.victory:
		return
	health = maxi(0, health - amount)
	game.hurt_flash = 0.28
	if health == 0:
		game.finish(false)
