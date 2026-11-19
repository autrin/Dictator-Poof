extends Node
## Choreography advances from arrivals, never from dialogue timers alone.
const Motion := preload("res://scripts/actor_motion.gd")
const Person := preload("res://scripts/person_visual.gd")
const Patrol := preload("res://scripts/patrol_visual.gd")
# Three lanes clear both the porch posts and the parked car's swept capsule margin.
const DOOR_LANES := [2.65, 3.38, 4.11]
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
var placing_time := 0.0
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
	cook = chapter.person(Vector3(4.81, 0, -44), Color("b47c55"), 3)
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
		var lane: float = DOOR_LANES[i]
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
			var lane: float = DOOR_LANES[i]
			var door := -5.0 if home else -39.0
			var direction := 1.0 if home else -1.0
			points = [Vector3(lane, 0, door - direction * 1.5), Vector3(lane, 0, door + direction * 1.5), Vector3(lane, 0, -42 if not home else -2), Vector3(2.5 + i * 0.7, 0, -42 if not home else -2), Vector3(2.5 + i * 0.7, 0, 0 if home else -46)]
			if trip == "grandma" and i == 0:
				points.append_array([Vector3(2.5, 0, -46.99), Vector3(chapter.targets.gift.position.x, 0, -46.99)])
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
	motion.walk(cook, [Vector3(4.75, 0, -45.4), Vector3(4.81, 0, -44)], 1.0)

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
		if trip == "grandma":
			trip_phase = "setting_down"
			placing_time = 0.0
		else:
			finish_arrival()
	elif trip_phase == "setting_down":
		placing_time += delta
		var sister: Node3D = chapter.sister
		sister.rotation.y = rotate_toward(sister.rotation.y, 0, 3.8 * delta)
		if placing_time >= 1.75 and chapter.pastry_box.get_parent() == sister:
			chapter.set_out_pastries()
		if placing_time >= 2.40:
			motion.walk(sister, [Vector3(2.50, 0, -46.99), Vector3(2.50, 0, -46)])
			finish_arrival()
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
	animate_meal(delta)
	animate_family(delta)

func finish_arrival() -> void:
	var bakery := trip == "bakery"
	trip = ""
	trip_phase = ""
	chapter.game.notify("line_" + chapter.STEPS[chapter.stage], 10)
	chapter.complete_step()
	if bakery:
		start_patrol()

func animate_family(delta: float) -> void:
	var player: Node3D = chapter.game.player
	for i in range(chapter.family.size()):
		var actor: Node3D = chapter.family[i]
		var carries_box: bool = i == 0 and chapter.pastry_box.get_parent() == actor
		var setting_down := i == 0 and trip_phase == "setting_down"
		if carries_box or setting_down:
			var seated := trip_phase == "driving"
			var placement := smoothstep(0.58, 1.62, placing_time) * (1 - smoothstep(1.75, 2.40, placing_time)) if setting_down else 0.0
			var tabletop: Vector3 = actor.to_local(chapter.targets.gift.global_position + Vector3.UP * 0.79)
			var box_at := Vector3(0, 0.56 if seated else 0.94, -0.31).lerp(tabletop, placement)
			if carries_box:
				chapter.pastry_box.position = box_at
			if setting_down:
				var bend := Basis(Vector3.RIGHT, -0.32 * placement)
				var hip := Vector3.UP * 0.91
				var shift := hip - bend * hip + Vector3.DOWN * 0.09 * placement
				actor.get_node("Torso").transform = Transform3D(bend, shift)
				for joint in ["Neck", "Gaze"]:
					var part: Node3D = actor.get_node(joint)
					var rest: Transform3D = actor.get_meta("standing_pose")[part]
					part.position = bend * rest.origin + shift
			for side in ["Left arm", "Right arm"]:
				var arm: Node3D = actor.get_node(side)
				arm.position.z = -0.16 * placement
				arm.position.y = (1.05 if seated else 1.43) - 0.13 * placement
				var grip := box_at + Vector3(-0.25 if side == "Left arm" else 0.25, 0.035, 0.083)
				reach(arm, grip, Vector2(0.33, 0.0))
			if setting_down:
				Person.look_toward(actor, chapter.pastry_box.global_position, delta)
				continue
		if motion.busy(actor) or trip_phase == "driving":
			continue
		if chapter.stage in [5, 6, 7]:
			if i == 0:
				Person.look_toward(actor, chapter.officer.position + Vector3.UP * 1.72, delta)
			continue
		var target: Vector3 = chapter.family[(i + 1) % 3].global_position + Vector3.UP * 1.71
		if chapter.stage <= 2 and i == 1:
			target = Vector3(6.78, 1.47, -1.4)
		var close := actor.global_position.distance_to(player.global_position) < 3.2
		if close:
			target = player.camera.global_position
		var speaking: bool = chapter.game.notification_left > 0 and ((i == 1 and chapter.game.message_key == "line_tv") or (i == 0 and chapter.game.message_key == "pastry_gift_cream"))
		if speaking:
			target = player.camera.global_position
		var direction := target - actor.global_position
		actor.rotation.y = rotate_toward(actor.rotation.y, atan2(-direction.x, -direction.z), delta * 1.55)
		Person.look_toward(actor, target, delta, sin(elapsed * 3.8) * 0.055 if speaking else 0.0)
		if not carries_box:
			var arm: Node3D = actor.get_node("Right arm")
			arm.rotation.x = move_toward(arm.rotation.x, 0.40 if speaking else 0.06, delta * 1.9)
			var elbow: Node3D = arm.get_node("Forearm")
			elbow.rotation.x = move_toward(elbow.rotation.x, 0.85 + sin(elapsed * 2.4) * 0.16 if speaking else 0.14, delta * 2.8)

func animate_meal(delta: float) -> void:
	var stirring: bool = chapter.stage >= 9 and chapter.stage <= 11 and not motion.busy(cook)
	spoon.visible = stirring
	if stirring:
		var bowl := Vector3(5.42 + 0.08 * cos(elapsed * 2.25), 1.16, -43.95 + 0.10 * sin(elapsed * 2.25))
		reach(cook.get_node("Right arm"), cook.to_local(bowl), Vector2(0.33, 0.215))
		Person.look_toward(cook, bowl, delta)
	elif not motion.busy(cook):
		var arm: Node3D = cook.get_node("Right arm")
		arm.rotation = arm.rotation.lerp(Vector3(0.08, 0, 0.10), minf(1, delta * 3))
		var elbow: Node3D = arm.get_node("Forearm")
		elbow.rotation.x = move_toward(elbow.rotation.x, 0.18, delta * 2)
	for i in range(diners.size()):
		var actor := diners[i]
		utensils[i].visible = eating
		var phase := fmod(elapsed + i * 0.91, 4.2 + i * 0.15)
		var bite := smoothstep(0.0, 1.18, phase) * (1.0 - smoothstep(1.46, 2.62, phase))
		var across: Node3D = diners[(i + 3) % diners.size()]
		var gaze := across.global_position + Vector3.UP * 1.33
		if eating:
			# Spoon tip travels between the plate and mouth with a pause at each end.
			var scoop := Vector3(0.09 * sin(phase * 2.0), 0.87, -0.55)
			var mouth := Vector3(0.035, 1.28, -0.166)
			reach(actor.get_node("Right arm"), scoop.lerp(mouth, bite), Vector2(0.33, 0.215))
			if phase < 2.62:
				gaze = actor.to_global(Vector3(0, 0.8, -0.68))
		else:
			actor.get_node("Right arm").rotation = Vector3(0.19, 0, 0.1)
			actor.get_node("Right arm/Forearm").rotation = Vector3(0.48, 0, 0)
		var eye: Vector3 = chapter.game.player.camera.global_position
		if actor.global_position.distance_to(eye) < 2.7 and actor.to_local(eye).z < -0.05:
			gaze = eye
		Person.look_toward(actor, gaze, delta)

func reach(arm: Node3D, target: Vector3, tip: Vector2) -> void:
	var forearm: Node3D = arm.get_node("Forearm")
	var aim := target - arm.position
	var reach := Vector2(aim.x, aim.z).length()
	# Solve shoulder and elbow together; the second link ends at the palm or spoon bowl.
	var upper := absf(forearm.position.y)
	var lower := tip.length()
	var d := clampf(aim.length(), absf(upper - lower) + 0.001, upper + lower - 0.001)
	var shoulder := acos(clampf((upper * upper + d * d - lower * lower) / (2 * upper * d), -1, 1))
	var elbow := acos(clampf((d * d - upper * upper - lower * lower) / (2 * upper * lower), -1, 1))
	arm.rotation = Vector3(atan2(reach, -aim.y) - shoulder, atan2(-aim.x, -aim.z), 0)
	forearm.rotation = Vector3(elbow - atan2(tip.y, tip.x), 0, 0)
