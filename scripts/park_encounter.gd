extends Node3D
## A short, player-triggered park encounter on Kaveh Lane.

const PersianFont := preload("res://assets/fonts/vazirmatn/Vazirmatn.ttf")
const UNIFORM := Color("626b4e")

var game: Node3D
var van: Node3D
var civilians: Array[Node3D] = []
var officers: Array[Node3D] = []
var elapsed := 0.0
var started := false
var completed := false
var shown_beat := -1

const BEAT_TIMES := [2.3, 5.2, 8.2, 11.1, 14.1, 17.1, 20.1]
const BEAT_LINES := [
	"گشت ارشاد: شما کی هستید؟ چه نسبتی با هم دارید؟",
	"گشت ارشاد: روسری‌هاتون رو درست کنید. موهاتون رو بپوشونید.",
	"گشت ارشاد: تتو ممنوعه! با زن نامحرم چرا می‌گردی؟",
	"دوست: ما فقط داریم توی پارک قدم می‌زنیم!",
	"دختر (گریه‌کنان): ولم کنید! کمک!",
	"پسر: به سرم نزنید! بذارید بریم!",
	"دوست‌ها: نه! ما رو سوار ون نکنید!",
]

func _ready() -> void:
	build_park()
	build_van()
	var colors := [Color("527b8c"), Color("ae6d75"), Color("b39457"), Color("716b9b")]
	for i in range(4):
		var person := make_person(colors[i], i % 2 == 1, false)
		person.position = Vector3(-3.1 + i * 0.65, 0, 1.0 + i * 0.55)
		civilians.append(person)
	for i in range(4):
		var officer := make_person(UNIFORM, false, true)
		officer.position = Vector3(4.0 + (i % 2) * 0.6, 0, 5.0 + (i / 2) * 0.5)
		officer.visible = false
		officers.append(officer)

func build_park() -> void:
	PoofShapes.box(self, Vector3(-0.6, 0.012, 0), Vector3(8.7, 0.025, 7.3), Color("43634b"))
	PoofShapes.box(self, Vector3(-0.6, 0.028, 0), Vector3(1.1, 0.01, 7.3), Color("a99a80"))
	for x in [-4.6, 3.4]:
		PoofShapes.box(self, Vector3(x, 0.25, -2.7), Vector3(0.25, 0.5, 0.25), Color("544336"))
		for offset in [-0.28, 0.28]:
			PoofShapes.box(self, Vector3(x + offset, 0.95, -2.7), Vector3(0.22, 1.2, 0.22), Color("544336"))
		PoofShapes.box(self, Vector3(x, 0.65, -2.7), Vector3(1.6, 0.17, 0.5), Color("8c6946"))
		PoofShapes.box(self, Vector3(x, 1.05, -2.95), Vector3(1.6, 0.65, 0.14), Color("8c6946"))
	for at in [Vector3(-4.4, 0, 2.7), Vector3(3.3, 0, -2.8)]:
		PoofShapes.box(self, at + Vector3(0, 0.9, 0), Vector3(0.2, 1.8, 0.2), Color("514334"))
		var crown := sphere(self, at + Vector3(0, 2.1, 0), Vector3(1.45, 1.5, 1.45), Color("45634c"))
		crown.name = "Park tree"
	var sign := PoofShapes.label(self, Vector3(-0.6, 2.5, -3.3), "پارک", Color("d7c69d"), 40)
	sign.font = PersianFont
	sign.text_direction = TextServer.DIRECTION_RTL
	sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED

func build_van() -> void:
	van = Node3D.new()
	van.name = "Morality police van"
	van.position = Vector3(4.7, 0, 7.0)
	add_child(van)
	PoofShapes.box(van, Vector3(0, 1.13, 0), Vector3(2.55, 2.1, 4.5), Color("deded8"))
	PoofShapes.box(van, Vector3(0, 2.16, 0.55), Vector3(2.5, 0.16, 3.15), Color("f3f1e9"))
	for side in [-1, 1]:
		PoofShapes.box(van, Vector3(side * 1.28, 1.17, 0), Vector3(0.035, 0.44, 4.36), Color("15966b"))
		for z in [-1.2, 0.05, 1.3]:
			PoofShapes.box(van, Vector3(side * 1.31, 1.75, z), Vector3(0.045, 0.57, 0.95), Color("273b44"))
		for z in [-1.55, 1.55]:
			sphere(van, Vector3(side * 1.25, 0.47, z), Vector3(0.38, 0.75, 0.75), Color("24282a"))
	PoofShapes.box(van, Vector3(0, 1.68, -2.26), Vector3(2.1, 0.7, 0.04), Color("283f49"))
	for x in [-0.92, 0.92]:
		PoofShapes.box(van, Vector3(x, 0.72, -2.28), Vector3(0.37, 0.22, 0.06), Color("f4e8b2"))
	var title := PoofShapes.label(van, Vector3(-1.34, 1.16, 0.05), "گشت ارشاد", Color("f0e5ae"), 35)
	title.font = PersianFont
	title.text_direction = TextServer.DIRECTION_RTL
	title.rotation.y = -PI / 2.0
	title.pixel_size = 0.006

func make_person(clothes: Color, woman: bool, officer: bool) -> Node3D:
	var person := Node3D.new()
	person.name = "Officer" if officer else ("Woman friend" if woman else "Man friend")
	add_child(person)
	sphere(person, Vector3(0, 1.53, 0), Vector3(0.32, 0.38, 0.32), Color("b48969"))
	sphere(person, Vector3(0, 1.76, -0.03), Vector3(0.34, 0.19, 0.34), Color("292b2b"))
	PoofShapes.box(person, Vector3(0, 1.0, 0), Vector3(0.48, 0.73, 0.3), clothes)
	for side in [-1, 1]:
		var arm := PoofShapes.box(person, Vector3(side * 0.33, 1.03, 0), Vector3(0.16, 0.63, 0.16), clothes)
		arm.name = "Left arm" if side < 0 else "Right arm"
		PoofShapes.box(person, Vector3(side * 0.14, 0.34, 0), Vector3(0.18, 0.68, 0.2), Color("39424a"))
	if woman:
		# Loose scarf and visible hair make the shouted order legible in the scene.
		PoofShapes.box(person, Vector3(0, 1.55, 0.17), Vector3(0.36, 0.42, 0.16), Color("292b2b"))
		PoofShapes.box(person, Vector3(0.05, 1.76, 0), Vector3(0.45, 0.11, 0.37), clothes.lightened(0.18))
	elif officer:
		PoofShapes.box(person, Vector3(0, 1.82, 0), Vector3(0.44, 0.14, 0.4), UNIFORM.darkened(0.3))
	else:
		# A visible tattoo on the forearm is mentioned by the officer.
		PoofShapes.box(person, Vector3(0.33, 0.88, -0.09), Vector3(0.13, 0.15, 0.025), Color("273d48"))
	if not officer:
		for side in [-1, 1]:
			var tear := sphere(person, Vector3(side * 0.105, 1.45, -0.16), Vector3(0.055, 0.13, 0.025), Color("8bcad1"))
			tear.name = "Tear left" if side < 0 else "Tear right"
			tear.visible = false
	return person

func sphere(parent: Node3D, at: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var shape := SphereMesh.new()
	shape.radius = 0.5
	shape.height = 1.0
	mesh.mesh = shape
	mesh.position = at
	mesh.scale = size
	mesh.material_override = PoofShapes.material(color)
	parent.add_child(mesh)
	return mesh

func _process(delta: float) -> void:
	if completed or not game.active or game.victory:
		return
	if not started:
		elapsed += delta
		for i in range(civilians.size()):
			civilians[i].position.z = 1.0 + i * 0.55 - minf(elapsed * 0.18, 1.1)
			civilians[i].position.y = absf(sin(elapsed * 6.0 + i)) * 0.025
		if game.player.global_position.distance_to(global_position) < 7.0:
			started = true
			elapsed = 0.0
		return
	elapsed += delta
	van.position.z = lerpf(7.0, 3.3, clampf(elapsed / 2.2, 0.0, 1.0))
	for i in range(civilians.size()):
		var person := civilians[i]
		var home := Vector3(-3.1 + i * 0.65, 0, -0.1 + i * 0.55)
		var fleeing := home + Vector3(-1.4 + (i % 2) * 0.5, 0, -0.9)
		var caught := Vector3(2.45 + (i % 2) * 0.32, 0, 0.8 + i * 0.7)
		if elapsed < 11.5:
			person.position = home
		elif elapsed < 14.8:
			person.position = home.lerp(fleeing, clampf((elapsed - 11.5) / 3.3, 0, 1))
		else:
			person.position = fleeing.lerp(caught, clampf((elapsed - 14.8) / 7.0, 0, 1))
		person.position.y = absf(sin(elapsed * (11.0 if elapsed > 11.5 else 4.0) + i)) * 0.04
		person.get_node("Tear left").visible = elapsed >= 14.1
		person.get_node("Tear right").visible = elapsed >= 14.1
		if elapsed > 14.8:
			person.rotation.z = (-0.24 if i % 2 == 1 else 0.18) + sin(elapsed * 9.0 + i) * 0.06
		else:
			person.rotation.z = sin(elapsed * 4.0 + i) * 0.025
	for i in range(officers.size()):
		var officer := officers[i]
		officer.visible = elapsed >= 2.2
		var arrival := Vector3(3.6 + (i % 2) * 0.55, 0, 2.5 + (i / 2) * 0.5)
		var approach := Vector3(-3.1 + i * 0.65 + 0.5, 0, -0.1 + i * 0.55)
		var pursuit := civilians[i].position + Vector3(0.46, 0, 0.05)
		if elapsed < 6.0:
			officer.position = arrival.lerp(approach, clampf((elapsed - 2.2) / 3.8, 0, 1))
		elif elapsed < 14.8:
			officer.position = approach
		else:
			officer.position = pursuit
		var left_arm := officer.get_node("Left arm") as MeshInstance3D
		if elapsed > 14.8:
			# One officer grabs near each woman's hair; the others strike and shove the men.
			left_arm.position.y = 1.51 if i % 2 == 1 else 1.35 + sin(elapsed * 15.0 + i) * 0.23
			left_arm.rotation.z = -0.65 if i % 2 == 1 else sin(elapsed * 15.0 + i) * 0.8
		else:
			left_arm.position.y = 1.03
			left_arm.rotation.z = 0.0
	for i in range(BEAT_TIMES.size()):
		if elapsed >= BEAT_TIMES[i] and shown_beat < i:
			shown_beat = i
			game.message_text = BEAT_LINES[i]
			game.notification_left = 3.1
	if elapsed >= 23.2:
		completed = true
