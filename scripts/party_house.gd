extends Node3D
## A private, walkable courtyard house beyond the north gate.

const PersonVisual := preload("res://scripts/person_visual.gd")
const PersianFont := preload("res://assets/fonts/vazirmatn/Vazirmatn.ttf")
const PLASTER := Color("c6a885")
const BRICK := Color("a27055")
const TILE := Color("287f81")
const WOOD := Color("584136")

var game: Node3D
var guests: Array[Node3D] = []
var bubbles: Array[Label3D] = []
var held_cups: Dictionary = {}
var sign: Label3D
var elapsed := 0.0
var raided := false
var raid_elapsed := 0.0
var arrest_announced := false
var music_left := 0.0
var music_beat := 0

const GUEST_POSITIONS := [
	Vector3(-3.2, 0, 3.0), Vector3(-3.2, 0, -1.5),
	Vector3(3.4, 0, -2.5), Vector3(2.8, 0, 1.7),
	Vector3(-3.2, 0, -4.4), Vector3(4.5, 0, 3.7),
]

func _ready() -> void:
	build_house()
	build_people()
	apply_language()

func build_house() -> void:
	name = "Private courtyard party house"
	PoofShapes.box(self, Vector3(0, -0.015, 0), Vector3(16, 0.03, 16), Color("c6b18d"))
	# The small entrance opens directly toward the lane; the walls shield the party.
	for side in [-1, 1]:
		PoofShapes.box(self, Vector3(side * 4.9, 1.9, 7.5), Vector3(6.2, 3.8, 0.55), PLASTER, true)
		PoofShapes.box(self, Vector3(side * 7.8, 1.9, 0), Vector3(0.55, 3.8, 15.5), BRICK, true)
		PoofShapes.box(self, Vector3(side * 5.9, 3.9, 0), Vector3(3.8, 0.3, 15.5), WOOD)
		PoofShapes.box(self, Vector3(side * 1.9, 1.4, 7.7), Vector3(0.22, 2.8, 0.25), TILE)
		for z in [-5.5, -2.0, 1.5, 5.0]:
			PoofShapes.box(self, Vector3(side * 7.45, 2.1, z), Vector3(0.08, 1.6, 1.15), WOOD)
			PoofShapes.box(self, Vector3(side * 7.39, 2.1, z), Vector3(0.07, 1.4, 0.95), Color("375c65"))
			for offset in [-0.23, 0.23]:
				PoofShapes.box(self, Vector3(side * 7.33, 2.1, z + offset), Vector3(0.06, 1.4, 0.055), Color("d2b37e"))
	PoofShapes.box(self, Vector3(0, 3.4, 7.5), Vector3(3.6, 1.0, 0.55), BRICK, true)
	# The entry screen bends the view so the private courtyard is not exposed to the street.
	PoofShapes.box(self, Vector3(0, 1.25, 5.1), Vector3(2.7, 2.5, 0.28), PLASTER, true)
	PoofShapes.box(self, Vector3(0, 1.35, 5.28), Vector3(2.3, 1.8, 0.035), TILE)
	PoofShapes.box(self, Vector3(0, 1.9, -7.65), Vector3(16, 3.8, 0.55), PLASTER, true)
	# A shallow iwan and a central water pool mark the private courtyard.
	PoofShapes.box(self, Vector3(0, 0.34, -6.2), Vector3(5.8, 0.68, 2.3), BRICK, true)
	PoofShapes.box(self, Vector3(0, 3.5, -6.0), Vector3(6.2, 0.26, 2.7), WOOD)
	for x in [-3.0, 3.0]:
		PoofShapes.box(self, Vector3(x, 1.75, -5.3), Vector3(0.28, 3.5, 0.28), PLASTER)
		PoofShapes.box(self, Vector3(x, 3.55, -5.3), Vector3(0.53, 0.2, 0.53), TILE)
	PoofShapes.box(self, Vector3(0, 0.2, -1.1), Vector3(2.3, 0.4, 1.45), TILE, true)
	PoofShapes.box(self, Vector3(0, 0.415, -1.1), Vector3(1.95, 0.025, 1.1), Color("497e88"))
	for x in [-1.07, 1.07]:
		PoofShapes.box(self, Vector3(x, 0.44, -1.1), Vector3(0.1, 0.12, 1.45), Color("eed1a0"))
	for z in [-1.75, -0.45]:
		PoofShapes.box(self, Vector3(0, 0.44, z), Vector3(2.3, 0.12, 0.1), Color("eed1a0"))
	for side in [-1, 1]:
		PoofShapes.box(self, Vector3(side * 4.8, 0.035, -1.1), Vector3(2.8, 0.02, 5.8), Color("8b4050"))
		PoofShapes.box(self, Vector3(side * 4.8, 0.052, -1.1), Vector3(2.5, 0.015, 5.45), Color("c09166"))
		for z in range(-6, 7, 2):
			PoofShapes.box(self, Vector3(side * 7.4, 0.08, z), Vector3(0.16, 0.03, 0.7), TILE)
	PoofShapes.box(self, Vector3(5.15, 0.65, 3.0), Vector3(1.55, 0.18, 0.9), WOOD, true)
	for x in [4.55, 5.75]:
		PoofShapes.box(self, Vector3(x, 0.32, 3.0), Vector3(0.13, 0.64, 0.13), WOOD)
	for x in [4.7, 5.05, 5.4]:
		make_cup(self, Vector3(x, 0.81, 2.9))
	make_bottle(Vector3(5.65, 0.92, 3.0))
	for x in [-5.8, 5.8]:
		var lamp := OmniLight3D.new()
		lamp.position = Vector3(x, 3.2, -3.8)
		lamp.light_color = Color("ffca88")
		lamp.light_energy = 1.4
		lamp.omni_range = 7.0
		add_child(lamp)
		PoofShapes.box(self, lamp.position, Vector3(0.35, 0.45, 0.25), Color("eebd7d"), false, 0.8)
	sign = PoofShapes.label(self, Vector3(0, 3.0, 7.82), "", Color("f5d8a1"), 42)
	sign.font = PersianFont
	sign.pixel_size = 0.008

func make_cup(parent: Node3D, at: Vector3) -> Node3D:
	var vessel := Node3D.new()
	vessel.position = at
	parent.add_child(vessel)
	var cup := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.105
	mesh.bottom_radius = 0.075
	mesh.height = 0.18
	cup.mesh = mesh
	cup.material_override = PoofShapes.material(Color("e5cca9"))
	vessel.add_child(cup)
	PoofShapes.box(vessel, Vector3(0, 0.09, 0), Vector3(0.13, 0.018, 0.13), Color("af5d4d"))
	return vessel

func make_bottle(at: Vector3) -> void:
	var body := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.12
	mesh.bottom_radius = 0.16
	mesh.height = 0.32
	body.mesh = mesh
	body.position = at
	body.material_override = PoofShapes.material(Color("496745"))
	add_child(body)
	PoofShapes.box(self, at + Vector3(0, 0.22, 0), Vector3(0.09, 0.14, 0.09), Color("496745"))
	PoofShapes.box(self, at, Vector3(0.29, 0.1, 0.29), Color("d8b98c"))

func build_people() -> void:
	var clothes := [Color("8b5f75"), Color("377d81"), Color("b77c4e"), Color("697ab2"), Color("ad6e68"), Color("6c8d67")]
	var hair := [Color("37292a"), Color("68402f"), Color("24262b"), Color("50332e"), Color("221f24"), Color("795037")]
	var skin := [Color("be9272"), Color("9c684f"), Color("c49d7c"), Color("ae7d61"), Color("d2aa88"), Color("a77558")]
	for i in range(GUEST_POSITIONS.size()):
		var guest := Node3D.new()
		guest.name = "Party guest %d" % (i + 1)
		guest.position = GUEST_POSITIONS[i]
		guest.set_meta("line_key", "party_guest_%d" % i)
		add_child(guest)
		PersonVisual.build(guest, clothes[i], skin[i], hair[i], i % 5)
		if i == 3 or i == 5:
			held_cups[i] = make_cup(guest, Vector3(0.4, 0.62, -0.06))
		var bubble := PoofShapes.label(guest, Vector3(0, 2.25, 0), "", Color("ffe0ac"), 20)
		bubble.font = PersianFont
		bubble.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		bubble.pixel_size = 0.007
		bubble.visible = false
		bubbles.append(bubble)
		guests.append(guest)

func apply_language() -> void:
	sign.text = game.localize("party_house_sign")
	sign.language = game.language
	sign.text_direction = TextServer.DIRECTION_RTL if game.language == "fa" else TextServer.DIRECTION_LTR
	for i in range(bubbles.size()):
		bubbles[i].text = game.localize("party_bubble_%d" % i)
		bubbles[i].language = game.language
		bubbles[i].text_direction = TextServer.DIRECTION_RTL if game.language == "fa" else TextServer.DIRECTION_LTR

func _process(delta: float) -> void:
	if not game.active:
		return
	elapsed += delta
	if not raided and not game.victory and game.player.global_position.distance_to(global_position) < 15.0:
		music_left -= delta
		if music_left <= 0.0:
			music_left = 0.38
			var notes := [220.0, 261.63, 293.66, 329.63, 293.66, 261.63, 246.94, 196.0]
			game.play_tone(notes[music_beat % notes.size()], 0.26, 0.045)
			music_beat += 1
	if not raided:
		for child in game.world.get_children():
			if child is CharacterBody3D and child.has_method("can_see_player") and child.alive and absf(child.global_position.x) < 7.5 and child.global_position.z < -32.0:
				start_raid()
				break
	else:
		raid_elapsed += delta
		if raid_elapsed >= 4.0 and not arrest_announced:
			arrest_announced = true
			game.notify("party_arrest", 4.0)
	for i in range(guests.size()):
		var person := guests[i]
		if raided:
			var target := Vector3(-0.6 if i == 1 else 0.6, 0, 6.3) if i == 1 or i == 2 else Vector3(-5.9 if i % 2 == 0 else 5.9, 0, -4.7 + float(i / 2) * 1.4)
			person.position = person.position.move_toward(target, delta * 3.3)
			person.rotation.y = -0.5 if i % 2 == 0 else 0.5
		else:
			var home: Vector3 = GUEST_POSITIONS[i]
			person.position = home + Vector3(sin(elapsed * 1.5 + i) * (0.18 if i > 0 else 0.03), absf(sin(elapsed * 4.2 + i)) * (0.06 if i > 0 else 0.015), cos(elapsed * 1.2 + i) * 0.12)
			person.rotation.y = sin(elapsed * 0.8 + i) * (0.55 if i > 0 else 0.1)
			person.rotation.z = sin(elapsed * 3.8 + i) * (0.12 if i > 0 else 0.025)
			var left_arm := person.get_node("Left arm") as MeshInstance3D
			var right_arm := person.get_node("Right arm") as MeshInstance3D
			left_arm.rotation.z = -0.4 + sin(elapsed * 3.8 + i) * 0.38 if i > 0 else -0.12
			right_arm.rotation.z = 0.4 + sin(elapsed * 3.8 + i + PI) * 0.38 if i > 0 else 0.12
			if held_cups.has(i):
				var sip := pow(maxf(0.0, sin(elapsed * 1.5 + i)), 3.0)
				var to_mouth := Vector3(0.17, 1.56, -0.2)
				var from_hand := Vector3(0.4, 0.62, -0.06)
				held_cups[i].position = from_hand.lerp(to_mouth, sip)
				(person.get_node("Right hand") as MeshInstance3D).position = Vector3(0.4, 0.59, -0.02).lerp(to_mouth, sip)
				right_arm.position = Vector3(0.34, 1.11, 0).lerp(Vector3(0.26, 1.4, -0.08), sip)
				right_arm.rotation.z = lerpf(right_arm.rotation.z, -0.7, sip)
		bubbles[i].visible = not raided and i == int(elapsed / 4.0) % guests.size()

func start_raid() -> void:
	raided = true
	game.notify("party_raid", 5.0)
	for bubble in bubbles:
		bubble.hide()
	for cup in held_cups.values():
		cup.hide()
