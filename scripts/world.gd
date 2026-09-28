extends Node3D
## An after-hours censorship office. Original primitive art, no external assets.

const SAND := Color("81766f")
const DARK := Color("30394a")
const TILE := Color("297d86")
var game: Node3D

func _ready() -> void:
	var environment := WorldEnvironment.new()
	var settings := Environment.new()
	settings.background_mode = Environment.BG_COLOR
	settings.background_color = Color("111c31")
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color = Color("a4bbd5")
	settings.ambient_light_energy = 0.36
	settings.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.environment = settings
	add_child(environment)
	var moon := DirectionalLight3D.new()
	moon.rotation_degrees = Vector3(-48, -28, 0)
	moon.light_color = Color("b7cde5")
	moon.light_energy = 0.35
	moon.shadow_enabled = true
	add_child(moon)
	PoofShapes.box(self, Vector3(0, -0.3, 0), Vector3(32, 0.6, 48), Color("454953"), true)
	PoofShapes.box(self, Vector3(0, 6.6, 0), Vector3(32, 0.4, 48), DARK, true)
	for z in range(-18, 21, 8):
		lamp(Vector3(-5, 5.8, z), Color("b5d9cb"))
		lamp(Vector3(5, 5.8, z), Color("b5d9cb"))
	for x in range(-14, 16, 2):
		PoofShapes.box(self, Vector3(x, 0.006, 0), Vector3(0.025, 0.01, 48), Color("74747a"))
	for z in range(-22, 24, 2):
		PoofShapes.box(self, Vector3(0, 0.008, z), Vector3(32, 0.01, 0.025), Color("74747a"))
	for side in [-1, 1]:
		PoofShapes.box(self, Vector3(side * 16, 3, 0), Vector3(1, 6, 48), SAND, true)
		PoofShapes.box(self, Vector3(side * 15.45, 1.2, 0), Vector3(0.05, 0.3, 47), TILE)
		for z in range(-20, 23, 6):
			PoofShapes.box(self, Vector3(side * 15.35, 3, z), Vector3(0.3, 3.4, 2.6), DARK)
			PoofShapes.box(self, Vector3(side * 15.15, 4.7, z), Vector3(0.45, 0.18, 3), TILE)
			lamp(Vector3(side * 14.7, 3.8, z), Color("ffd5a0"))
			PoofShapes.box(self, Vector3(side * 18, 4, z), Vector3(4, 8 + abs(z) * 0.12, 5), DARK)
	PoofShapes.box(self, Vector3(0, 3, 24), Vector3(32, 6, 1), SAND, true)
	PoofShapes.box(self, Vector3(0, 4, -24), Vector3(32, 8, 1), SAND, true)
	PoofShapes.box(self, Vector3(0, 3.4, -23.35), Vector3(9, 5.7, 0.3), DARK)
	PoofShapes.box(self, Vector3(0, 6.4, -23.1), Vector3(10, 0.3, 0.35), TILE)
	PoofShapes.label(self, Vector3(0, 5.2, -22.9), "BREAK THE BLACKOUT", Color("c9eee8"), 48)
	PoofShapes.label(self, Vector3(0, 4.35, -22.9), "D E P A R T M E N T   O F   N O", Color("d9c69b"), 24)
	# Cover is low enough to see over while standing and tall enough to block fire.
	for at in [Vector3(-4, 0.65, 10), Vector3(4, 0.65, 7), Vector3(-5, 0.65, -5), Vector3(5, 0.65, -12)]:
		PoofShapes.box(self, at, Vector3(3, 1.3, 1.4), SAND, true)
		PoofShapes.box(self, at + Vector3(0, 0.67, 0), Vector3(3.1, 0.1, 1.5), TILE)
		PoofShapes.box(self, at + Vector3(0, 1.02, 0), Vector3(0.7, 0.6, 0.2), DARK, true)
		PoofShapes.box(self, at + Vector3(0, 1.02, 0.12), Vector3(0.6, 0.45, 0.025), Color("478478"), false, 0.6)
		for pile in range(3):
			PoofShapes.box(self, at + Vector3(0.8, 0.76 + pile * 0.045, 0), Vector3(0.45, 0.035, 0.55), Color("d4c4a5"))
	# A dry central fountain leaves two readable routes around the courtyard.
	PoofShapes.box(self, Vector3(0, 0.4, 0), Vector3(5, 0.8, 5), TILE, true)
	PoofShapes.box(self, Vector3(0, 0.83, 0), Vector3(4.5, 0.05, 4.5), Color("182e42"))
	PoofShapes.box(self, Vector3(0, 1.3, 0), Vector3(0.7, 1, 0.7), SAND, true)
	for i in range(3):
		var locations := [Vector3(-11, 0, 7), Vector3(11, 0, -5), Vector3(-9, 0, -17)]
		terminal(locations[i], i)
	var exit := Node3D.new()
	exit.position = Vector3(0, 0, -21)
	add_child(exit)
	PoofShapes.box(exit, Vector3(0, 0.8, 0), Vector3(1.8, 1.6, 0.8), DARK, true)
	game.broadcast_screen = PoofShapes.box(exit, Vector3(0, 1.1, 0.42), Vector3(1.5, 0.6, 0.03), Color("8b575e"), false, 1.0)
	PoofShapes.label(exit, Vector3(0, 2.5, 0), "UPLINK", Color("f4d9a0"), 40)
	game.broadcast = exit
	PoofShapes.label(self, Vector3(0, 2.8, 13), "01 / RESTORE THE SIGNAL", Color("dbeae8"), 34)
	PoofShapes.label(self, Vector3(0, 2.25, 13), "Find the three amber relay terminals", Color("c0bcb0"), 22)
	PoofShapes.label(self, Vector3(-9, 3.3, -22.9), "PERMISSION REQUIRED\nTO REQUEST PERMISSION", Color("d9c69b"), 25)
	PoofShapes.label(self, Vector3(9, 3.3, -22.9), "EMPLOYEE OF THE MONTH:\nTHE SURVEILLANCE CAMERA", Color("d9c69b"), 24)

func lamp(at: Vector3, color: Color) -> void:
	PoofShapes.box(self, at, Vector3(0.18, 0.45, 0.18), color, false, 1.5)
	var light := OmniLight3D.new()
	light.position = at
	light.light_color = color
	light.light_energy = 1.5
	light.omni_range = 5
	add_child(light)

func terminal(at: Vector3, index: int) -> void:
	var root := Node3D.new()
	add_child(root)
	root.position = at
	PoofShapes.box(root, Vector3(0, 0.7, 0), Vector3(1.2, 1.4, 0.65), DARK, true)
	var screen := PoofShapes.box(root, Vector3(0, 1, 0.34), Vector3(0.95, 0.55, 0.04), Color("f0b86c"), false, 1.0)
	var caption := PoofShapes.label(root, Vector3(0, 2.5, 0), "RELAY 0%d" % (index + 1), Color("f0b86c"), 36)
	caption.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	game.relays.append({"node": root, "screen": screen, "label": caption, "online": false})
