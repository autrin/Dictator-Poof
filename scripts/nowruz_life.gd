extends Node
## Choreography advances from arrivals, never from dialogue timers alone.
const Motion := preload("res://scripts/actor_motion.gd")
const Person := preload("res://scripts/person_visual.gd")
const Patrol := preload("res://scripts/patrol_visual.gd")
var chapter: Node3D
var motion := Motion.new()
var van: Node3D
var officers: Array[Node3D] = []
var patrol_phase := "idle"
var trip := ""
var trip_phase := ""
var road: Array[Vector3] = []
var elapsed := 0.0
var eating := false
var cooking_left := 0.0
var cook: Node3D
var spoon: Node3D
var diners: Array[Node3D] = []
var utensils: Array[Node3D] = []

func _ready() -> void:
	van = Patrol.van(chapter)
	van.position = Vector3(-8.7, 0, -31)
	van.rotation.y = PI
	van.get_node("Patrol sign").text = chapter.game.localize("van_sign")
	for i in range(2):
		var actor := Patrol.officer(chapter)
		actor.position = Vector3(-7.2 - i * 0.85, 0, -28)
		actor.hide()
		actor.get_node("Body collider").collision_layer = 0
		officers.append(actor)
	chapter.officer = officers[0]
	cook = chapter.person(Vector3(4.65, 0, -44), Color("b47c55"), 3)
	Motion.face(cook, Vector3(5.8, 0, -44))
	PoofShapes.box(cook, Vector3(0, 1.13, -0.145), Vector3(0.3, 0.49, 0.015), Color("e0d7bb"))
	Person.remember_pose(cook)
	spoon = utensil(cook, true)
	for i in range(chapter.relatives.size()):
		var actor: Node3D = chapter.relatives[i]
		diners.append(actor)
		utensils.append(utensil(actor, false))

func utensil(actor: Node3D, wooden: bool) -> Node3D:
	var root := Node3D.new()
	actor.get_node("Right arm/Forearm").add_child(root)
	root.position = Vector3(0, -0.33, -0.025)
	var color := Color("986f43") if wooden else Color("c0c5c4")
	PoofShapes.box(root, Vector3(0, 0, -0.075), Vector3(0.018, 0.018, 0.2), color)
	Person.sphere(root, "Spoon bowl", Vector3(0, 0, -0.19), Vector3(0.055, 0.014, 0.075), color)
	return root

func busy() -> bool:
	return trip != "" or patrol_phase in ["driving", "approaching"] or cooking_left > 0

func family_busy() -> bool:
	for actor in chapter.family:
		if motion.busy(actor):
			return true
	return false

func walk_to_car(from_house: bool, grandma: bool = false) -> void:
	for i in range(chapter.family.size()):
		var lane := 2.7 + i * 0.85
		var door_z := -39.0 if grandma else -5.0
		var side := 1.0 if grandma else -1.0
		var points: Array = []
		if from_house:
			points.append(Vector3(lane, 0, door_z - side * 1.5))
			points.append(Vector3(lane, 0, door_z + side * 1.5))
		# Separate positions keep the passengers from queuing on the same point.
		var outside_x: float = chapter.car.position.x - 3.7 + i * 0.7
		points.append(Vector3(outside_x, 0, door_z + side * 1.5 if from_house else -15))
		points.append(Vector3(outside_x, 0, chapter.car.position.z - 0.9 + i * 0.85))
		points.append(chapter.car.position + Vector3(-1.6, 0, -0.9 + i * 0.85))
		motion.walk(chapter.family[i], points)

func begin_trip(destination: String) -> void:
	trip = destination
	trip_phase = "boarding"
	if destination != "bakery":
		walk_to_car(destination != "grandma", destination == "home")
	chapter.game.notify("family_boarding", 5)

func board() -> void:
	var seats := [Vector3(0.4, 0, -0.4), Vector3(-0.4, 0, 0.65), Vector3(-0.4, 0, -0.4)]
	for i in range(chapter.family.size()):
		var actor: Node3D = chapter.family[i]
		actor.reparent(chapter.car)
		actor.position = seats[i]
		actor.rotation = Vector3.ZERO
		Person.sit(actor)
		actor.get_node("Body collider").collision_layer = 0
		if i == 2:
			for side in ["Left", "Right"]:
				actor.get_node(side + " arm").rotation.x = 0.7
				actor.get_node(side + " arm/Forearm").rotation.x = 1.9
	var player: Node3D = chapter.game.player
	player.collision_layer = 0
	player.velocity = Vector3.ZERO
	player.rotation.y = chapter.car.rotation.y
	player.camera.rotation = Vector3.ZERO
	player.camera.position.y = 1.3
	player.empty_hands.hide()
	match trip:
		"bakery": road = [Vector3(5.5, 0, -19), Vector3(-3.5, 0, -19)]
		"grandma": road = [Vector3(5.5, 0, -23), Vector3(5.5, 0, -36)]
		"home": road = [Vector3(5.5, 0, -25), Vector3(5.5, 0, -9)]
		"visits": road = [Vector3(5.5, 0, -24), Vector3(5.5, 0, -36)]
	trip_phase = "driving"
	chapter.game.notify("family_driving", 5)

func disembark() -> void:
	chapter.car.rotation.y = 0
	var bakery := trip == "bakery"
	var home := trip == "home"
	for i in range(chapter.family.size()):
		var actor: Node3D = chapter.family[i]
		actor.reparent(chapter)
		actor.position = chapter.car.position + Vector3(-1.6, 0, -0.9 + i * 0.85)
		actor.get_node("Body collider").collision_layer = 1
		var points: Array
		if bakery:
			points = [Vector3(-7.2 - i * 0.95, 0, -15)]
		else:
			var lane := 2.7 + i * 0.85
			var door := -5.0 if home else -39.0
			var direction := 1.0 if home else -1.0
			points = [Vector3(lane, 0, door - direction * 1.5), Vector3(lane, 0, door + direction * 1.5), Vector3(lane, 0, -42 if not home else -2), Vector3(2.5 + i * 0.7, 0, -42 if not home else -2), Vector3(2.5 + i * 0.7, 0, 0 if home else -46)]
		motion.walk(actor, points)
	chapter.game.player.collision_layer = 2
	chapter.game.player.empty_hands.show()
	# Step out beside the rear passenger door, clear of the walking lanes.
	var at: Vector3 = chapter.car.position + Vector3(1.6, 0.05, 1.7)
	chapter.teleport(at, Vector3(-7.2, 1.5, -15) if bakery else Vector3(3.6, 1.5, -5 if home else -39))
	trip_phase = "arriving"
	chapter.rules.minute = {"bakery": 540, "grandma": 600, "home": 1200, "visits": 1260}[trip]
	chapter.update_time()

func start_patrol() -> void:
	patrol_phase = "driving"
	chapter.game.notify("patrol_arriving", 5)

func start_cooking() -> void:
	cooking_left = 8.0
	motion.walk(cook, [Vector3(4.65, 0, -45.4), Vector3(4.65, 0, -44)], 1.0)

func _physics_process(delta: float) -> void:
	if not chapter.game.active:
		return
	elapsed += delta
	motion.tick(delta, chapter.game.player)
	if trip_phase == "boarding" and not family_busy():
		board()
	elif trip_phase == "driving":
		var to: Vector3 = road[0] - chapter.car.position
		var old_angle: float = chapter.car.rotation.y
		chapter.car.rotation.y = lerp_angle(old_angle, atan2(-to.x, -to.z), minf(delta * 3, 1))
		chapter.car.position = chapter.car.position.move_toward(road[0], delta * 3.8)
		chapter.game.player.position = chapter.car.to_global(Vector3(0.4, 0.05, 0.65))
		chapter.game.player.rotation.y += angle_difference(old_angle, chapter.car.rotation.y)
		for wheel in chapter.car.get_meta("wheels"):
			wheel.rotate_y(delta * 3.8 / 0.32)
		if chapter.car.position.distance_to(road[0]) < 0.05:
			road.pop_front()
			if road.is_empty():
				disembark()
	elif trip_phase == "arriving" and not family_busy():
		var arrived := trip
		trip = ""
		trip_phase = ""
		chapter.game.notify("line_" + chapter.STEPS[chapter.stage], 10)
		chapter.complete_step()
		if arrived == "bakery":
			start_patrol()
		elif arrived in ["grandma", "visits"]:
			chapter.pastry_box.reparent(chapter)
			chapter.pastry_box.position = Vector3(0.6, 0.9, -45.8)
	if patrol_phase == "driving":
		van.position.z = move_toward(van.position.z, -22.8, delta * 3)
		if van.position.z >= -22.85:
			for i in range(officers.size()):
				var actor := officers[i]
				actor.show()
				actor.get_node("Body collider").collision_layer = 1
				actor.position = Vector3(-7.0 + i, 0, -22.8)
				motion.walk(actor, [Vector3(-7.1 - i * 0.8, 0, -18.6), Vector3(-6.0 + i * 1.0, 0, -16.2)], 1.3)
			patrol_phase = "approaching"
	elif patrol_phase == "approaching" and not motion.busy(officers[0]) and not motion.busy(officers[1]):
		patrol_phase = "ready"
		for actor in officers:
			Motion.face(actor, chapter.sister.position)
		Motion.face(chapter.sister, officers[0].position)
		chapter.game.notify("patrol_ready", 5)
	if chapter.stage == 6:
		officers[0].get_node("Right arm").rotation.x = 0.8
		officers[0].get_node("Right arm/Forearm").rotation.x = 0.6 + sin(elapsed * 3) * 0.08
	else:
		officers[0].get_node("Right arm").rotation.x = 0
	if cooking_left > 0 and not motion.busy(cook):
		Motion.face(cook, Vector3(5.8, 0, -44))
		cooking_left = maxf(0, cooking_left - delta)
		if cooking_left == 0:
			chapter.serving.show()
			chapter.complete_step()
	animate_meal()

func animate_meal() -> void:
	var stirring: bool = chapter.stage >= 9 and chapter.stage <= 11 and not motion.busy(cook)
	spoon.visible = stirring
	if stirring:
		cook.get_node("Right arm").rotation.x = 0.35
		cook.get_node("Right arm/Forearm").rotation.x = 1.1
		cook.get_node("Right arm/Forearm").rotation.z = sin(elapsed * 2.5) * 0.18
	for i in range(diners.size()):
		var actor := diners[i]
		utensils[i].visible = eating
		var sip := (sin(elapsed * 1.6 + i * 1.9) + 1) * 0.5
		actor.get_node("Right arm").rotation.x = lerpf(0.3, 0.9, sip) if eating else sin(elapsed + i) * 0.08
		actor.get_node("Right arm/Forearm").rotation.x = lerpf(0.6, 1.95, sip) if eating else 0.4
		actor.get_node("Head").rotation.y = sin(elapsed * 0.5 + i) * 0.08
