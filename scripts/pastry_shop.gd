extends Node3D
signal wrapped
const Art := preload("res://scripts/pastry_art.gd")
const Copy := preload("res://scripts/nowruz_text.gd")
const FONT := preload("res://assets/fonts/vazirmatn/Vazirmatn.ttf")
const TRAY_X := [-1.63, -0.61, 0.41]
const JADE := Color("295856")
const BRASS := Color("c89f5f")
const CAPACITY := 4
var game: Node
var language := "en"
var selection: Array[int] = []
var stock: Array[Array] = [[], [], []]
var packed_pieces: Array[Node3D] = []
var gift: Node3D
var cover: Node3D
var camera := Camera3D.new()
var overlay := CanvasLayer.new()
var footer := PanelContainer.new()
var picks: Array[Button] = []
var count_label := Label.new()
var note := Label.new()
var undo := Button.new()
var finish := Button.new()
var packing := false
var sealed := false
var flights: Dictionary = {}

func _ready() -> void:
	build_counter()
	add_child(camera)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.keep_aspect = Camera3D.KEEP_WIDTH
	camera.size = 4.85
	camera.position = Vector3(0, 3.15, 1.95)
	camera.look_at(to_global(Vector3(0, 1.27, -0.03)))
	build_controls()
	if game == null:
		var config := ConfigFile.new()
		if config.load("user://settings.cfg") == OK and config.get_value("preferences", "language", "en") == "fa":
			language = "fa"
		var sun := DirectionalLight3D.new()
		sun.rotation_degrees = Vector3(-54, -26, 0)
		sun.shadow_enabled = true
		sun.light_energy = 0.83
		add_child(sun)
		open()

func build_counter() -> void:
	PoofShapes.box(self, Vector3(0, 1.53, -1.03), Vector3(5.1, 3.06, 0.16), Color("e6c8a5"), true)
	PoofShapes.box(self, Vector3(0, 0.49, 0), Vector3(4.64, 0.98, 1.49), JADE, true)
	var worktop := PoofShapes.box(self, Vector3(0, 1.0, -0.09), Vector3(4.83, 0.06, 1.75), Color("9b7556"))
	var grain := preload("res://scripts/domestic_props.gd").surface_texture()
	grain.noise.frequency = 0.023
	grain.color_ramp.colors = PackedColorArray([Color("927c68"), Color("efdfc9")])
	worktop.material_override.albedo_texture = grain
	worktop.material_override.uv1_scale = Vector3(1.3, 9, 1)
	for x in range(5):
		PoofShapes.box(self, Vector3(-1.85 + x * 0.925, 0.50, 0.75), Vector3(0.83, 0.62, 0.018), Color("48726a"))
	for y in [0.12, 0.88]:
		PoofShapes.box(self, Vector3(0, y, 0.763), Vector3(4.64, 0.016, 0.015), BRASS)
	for i in range(15):
		var at := Vector3((i - 7) * 0.34, 1.35, -0.932)
		var tile := PoofShapes.box(self, at, Vector3(0.329, 0.34, 0.025), JADE)
		var motif := PoofShapes.box(tile, Vector3(0, 0, 0.017), Vector3(0.145, 0.145, 0.013), Color("8bb4a2"))
		motif.rotation.z = PI / 4
		PoofShapes.box(motif, Vector3(0, 0, 0.012), Vector3(0.064, 0.064, 0.012), BRASS)
	var signboard := PoofShapes.box(self, Vector3(0, 1.94, -0.89), Vector3(2.45, 0.61, 0.09), JADE)
	for y in [-0.26, 0.26]:
		PoofShapes.box(signboard, Vector3(0, y, 0.05), Vector3(2.36, 0.009, 0.01), BRASS)
	for side in [-1, 1]:
		for j in range(3):
			var lozenge := PoofShapes.box(signboard, Vector3(side * (0.86 + j * 0.106), 0, 0.05), Vector3.ONE * (0.062 if j == 1 else 0.032), BRASS)
			lozenge.rotation.z = PI / 4
	var sign_label := PoofShapes.label(signboard, Vector3(0, 0.01, 0.055), "قنادی بهار", Art.PAPER, 86)
	sign_label.font = FONT
	sign_label.outline_size = 0
	sign_label.pixel_size = 0.0045
	for i in range(17):
		var x := (i - 8) * 0.30
		var color := Art.PLUM if i % 2 == 0 else Art.PAPER
		var awning := PoofShapes.box(self, Vector3(x, 3.08, -0.66), Vector3(0.301, 0.065, 0.87), color)
		awning.rotation.x = 0.12
		PoofShapes.box(self, Vector3(x, 2.96, -0.23), Vector3(0.301, 0.16, 0.04), color)
	for kind in range(3):
		var x: float = TRAY_X[kind]
		PoofShapes.box(self, Vector3(x, 1.047, 0), Vector3(0.93, 0.034, 0.81), Color("82786a"))
		PoofShapes.box(self, Vector3(x, 1.066, 0), Vector3(0.87, 0.009, 0.75), Color("e0c5a2"))
		for i in range(6):
			var pastry := Art.piece(kind)
			add_child(pastry)
			pastry.position = display_spot(kind, i)
			pastry.rotation.y = sin(i * 2.6 + kind) * 0.4
			stock[kind].append(pastry)
	gift = Art.box_base(self)
	gift.position = Vector3(1.52, 1.042, 0)
	cover = Art.lid(gift)
	position_lid(false)
	# The serving tongs rest in the gap between the last tray and the gift box.
	var tongs := Node3D.new()
	add_child(tongs)
	tongs.position = Vector3(1.03, 1.053, -0.06)
	tongs.rotation.y = -0.18
	for side in [-1, 1]:
		var arm := PoofShapes.box(tongs, Vector3(side * 0.032, 0, 0), Vector3(0.022, 0.018, 0.39), Color("bbb4a3"))
		arm.rotation.y = side * 0.13
		var tip := PoofShapes.box(tongs, Vector3(side * 0.056, 0.005, 0.205), Vector3(0.05, 0.019, 0.088), Color("c5bba4"))
		tip.rotation.y = side * 0.13
	var lamp := OmniLight3D.new()
	lamp.position = Vector3(-0.8, 2.8, 0.9)
	lamp.light_color = Color("fff0d9")
	lamp.light_energy = 0.32
	lamp.omni_range = 5
	add_child(lamp)

func position_lid(closed: bool) -> void:
	cover.position = Vector3(0, 0.166, 0) if closed else Vector3(0, 0.25, -0.47)
	cover.rotation.x = 0 if closed else 1.12

func display_spot(kind: int, i: int) -> Vector3:
	return Vector3(TRAY_X[kind] + ((i % 3) - 1) * 0.257, 1.072, -0.173 + (i / 3) * 0.33)

func build_controls() -> void:
	add_child(overlay)
	overlay.layer = 2
	overlay.hide()
	var ui := Control.new()
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(ui)
	var theme := Theme.new()
	theme.default_font = FONT
	theme.default_font_size = 19
	var style := StyleBoxFlat.new()
	style.bg_color = Color("254542")
	style.set_corner_radius_all(5)
	style.border_color = BRASS
	style.set_border_width_all(1)
	style.set_content_margin_all(9)
	for state in ["normal", "hover", "pressed", "disabled"]:
		var variant := style.duplicate() as StyleBoxFlat
		if state in ["hover", "pressed"]:
			variant.bg_color = Color("42736b")
		theme.set_stylebox(state, "Button", variant)
	ui.theme = theme
	for kind in range(3):
		var button := Button.new()
		ui.add_child(button)
		button.pressed.connect(add_piece.bind(kind))
		picks.append(button)
	ui.add_child(footer)
	footer.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	footer.offset_top = -102
	footer.grow_vertical = Control.GROW_DIRECTION_BEGIN
	var paper := StyleBoxFlat.new()
	paper.bg_color = Color("f5e7ce")
	paper.content_margin_left = 36
	paper.content_margin_right = 36
	paper.content_margin_top = 12
	paper.content_margin_bottom = 12
	footer.add_theme_stylebox_override("panel", paper)
	var row := HBoxContainer.new()
	footer.add_child(row)
	row.add_theme_constant_override("separation", 16)
	var words := VBoxContainer.new()
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(words)
	words.add_child(count_label)
	words.add_child(note)
	count_label.add_theme_font_size_override("font_size", 25)
	count_label.add_theme_color_override("font_color", JADE)
	note.add_theme_color_override("font_color", Color("5a4033"))
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	for button: Button in [undo, finish]:
		row.add_child(button)
		button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	undo.pressed.connect(undo_piece)
	finish.pressed.connect(wrap_box)
	get_viewport().size_changed.connect(position_buttons)

func words(key: String) -> String:
	return game.localize(key) if game != null else Copy.text(language, key)

func refresh_language() -> void:
	if picks.is_empty():
		return
	for i in range(3):
		picks[i].text = words("pastry_" + Art.FLAVOURS[i])
		picks[i].disabled = sealed or selection.size() >= CAPACITY
	count_label.text = words("pastry_count") % [selection.size(), CAPACITY]
	var lang: String = game.language if game != null else language
	footer.layout_direction = Control.LAYOUT_DIRECTION_RTL if lang == "fa" else Control.LAYOUT_DIRECTION_LTR
	note.text = words(reaction() if sealed else "pastry_note")
	undo.text = words("pastry_undo")
	undo.disabled = sealed or selection.is_empty()
	finish.text = words("pastry_again" if sealed else "pastry_wrap")
	finish.disabled = selection.size() != CAPACITY
	position_buttons()

func position_buttons() -> void:
	if not packing:
		return
	for i in range(picks.size()):
		var button := picks[i]
		button.reset_size()
		button.position = camera.unproject_position(to_global(Vector3(TRAY_X[i], 1.035, 0.55))) - button.size / 2

func open() -> void:
	packing = true
	camera.make_current()
	overlay.show()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	refresh_language()

func add_piece(kind: int) -> void:
	if not overlay.visible or sealed or selection.size() == CAPACITY or not has_stock(kind):
		return
	take_from_tray(kind)
	refresh_language()

func take_from_tray(kind: int) -> void:
	var pastry: Node3D = stock[kind].pop_back()
	move_piece(pastry, gift.position + Art.slot(selection.size()))
	selection.append(kind)
	packed_pieces.append(pastry)

func has_stock(kind: int, count: int = 1) -> bool:
	return kind >= 0 and kind < stock.size() and stock[kind].size() >= count

## Prepare a complete story gift without opening the counter or changing cameras.
func pack_assortment(kinds: Array[int]) -> bool:
	if packing or sealed or not selection.is_empty() or kinds.size() != CAPACITY:
		return false
	for kind in kinds:
		if not has_stock(kind, kinds.count(kind)):
			return false
	for kind in kinds:
		take_from_tray(kind)
	seal_box()
	return true

func undo_piece() -> void:
	if not overlay.visible or sealed or selection.is_empty():
		return
	var kind: int = selection.pop_back()
	var pastry: Node3D = packed_pieces.pop_back()
	move_piece(pastry, display_spot(kind, stock[kind].size()))
	stock[kind].append(pastry)
	refresh_language()

func move_piece(pastry: Node3D, destination: Vector3) -> void:
	flights[pastry] = {"from": pastry.position, "to": destination, "time": 0.0}

func _process(delta: float) -> void:
	if not overlay.visible:
		return
	for pastry: Node3D in flights.keys():
		var flight: Dictionary = flights[pastry]
		flight.time = minf(1, flight.time + delta * 3.7)
		var t: float = flight.time
		pastry.position = flight.from.lerp(flight.to, smoothstep(0, 1, t)) + Vector3.UP * (sin(t * PI) * 0.29)
		if t >= 1:
			flights.erase(pastry)

func wrap_box() -> void:
	if not overlay.visible or selection.size() != CAPACITY:
		return
	if sealed:
		sealed = false
		while not selection.is_empty():
			undo_piece()
		position_lid(false)
		refresh_language()
	else:
		seal_box()

func seal_box() -> void:
	for pastry: Node3D in flights:
		pastry.position = flights[pastry].to
	flights.clear()
	sealed = true
	position_lid(true)
	if game != null:
		if packing:
			packing = false
			overlay.hide()
			camera.clear_current(false)
		wrapped.emit()
	refresh_language()

func reaction() -> String:
	var most := 0
	var favourite := -1
	for kind in range(3):
		var count := selection.count(kind)
		if count > most:
			most = count
			favourite = kind
		elif count == most:
			favourite = -1
	return "pastry_mixed" if favourite < 0 else "pastry_gift_" + Art.FLAVOURS[favourite]

func _unhandled_input(event: InputEvent) -> void:
	if not overlay.visible:
		return
	if game == null and event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F2:
		language = "en" if language == "fa" else "fa"
		refresh_language()
		get_viewport().set_input_as_handled()
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and not sealed:
		var plane := Plane(Vector3.UP, global_position.y + 1.075)
		var hit = plane.intersects_ray(camera.project_ray_origin(event.position), camera.project_ray_normal(event.position))
		if hit != null:
			var point := to_local(hit)
			for i in range(3):
				if absf(point.x - TRAY_X[i]) <= 0.465 and absf(point.z) <= 0.405:
					add_piece(i)
					get_viewport().set_input_as_handled()
					return
