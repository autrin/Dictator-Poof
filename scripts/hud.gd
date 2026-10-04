extends CanvasLayer
## Native Godot GUI. Anchors and containers keep it usable when resizing.

const TEAL := Color("8de0d0")
var game: Node3D
var menu: PanelContainer
var hud: Control
var stats: Label
var objective: Label
var prompt: Label
var crosshair: Label
var damage: ColorRect
var heading: Label
var description: Label
var start_button: Button
var blood_button: CheckButton
var hint: Label
var replay_button: Button
var controls: Label

func _ready() -> void:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	var theme := Theme.new()
	theme.default_font_size = 18
	root.theme = theme
	damage = ColorRect.new()
	damage.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	damage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	damage.color = Color(0.65, 0.09, 0.09, 0)
	root.add_child(damage)
	hud = Control.new()
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(hud)
	var top := VBoxContainer.new()
	top.position = Vector2(32, 26)
	hud.add_child(top)
	text(top, "D I C T A T O R   P O O F   /   0 1", 16, TEAL)
	objective = text(top, "LIGHT UP THE LANE   0 / 3", 25)
	text(top, "KAVEH LANE · DUSK", 12, Color("dbc1a4"))
	stats = Label.new()
	stats.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	stats.position = Vector2(32, -82)
	stats.add_theme_font_size_override("font_size", 24)
	hud.add_child(stats)
	controls = Label.new()
	controls.text = "WASD  Move   /   SHIFT  Sprint   /   CTRL  Crouch   /   LMB  Fire   /   R  Reload   /   E  Interact   /   ESC  Pause"
	controls.add_theme_font_size_override("font_size", 14)
	controls.modulate = Color("b3b5c0")
	controls.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	controls.position = Vector2(32, -38)
	hud.add_child(controls)
	crosshair = Label.new()
	crosshair.text = "+"
	crosshair.add_theme_font_size_override("font_size", 28)
	crosshair.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	crosshair.position = Vector2(-9, -20)
	hud.add_child(crosshair)
	prompt = Label.new()
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	prompt.position = Vector2(-300, -140)
	prompt.size = Vector2(600, 40)
	prompt.add_theme_font_size_override("font_size", 22)
	prompt.add_theme_font_override("font", preload("res://assets/fonts/vazirmatn/Vazirmatn.ttf"))
	prompt.modulate = TEAL
	hud.add_child(prompt)
	menu = PanelContainer.new()
	root.add_child(menu)
	menu.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	menu.offset_left = -285
	menu.offset_right = 285
	menu.offset_top = -305
	menu.offset_bottom = 305
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.055, 0.09, 0.97)
	style.border_color = Color("407b7e")
	style.set_border_width_all(1)
	style.content_margin_left = 34
	style.content_margin_right = 34
	style.content_margin_top = 22
	style.content_margin_bottom = 22
	menu.add_theme_stylebox_override("panel", style)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 9)
	menu.add_child(column)
	text(column, "AN OPEN-SOURCE RESISTANCE GAME", 13, TEAL)
	heading = text(column, "DICTATOR POOF", 40)
	text(column, "01  /  A NIGHT ON KAVEH LANE", 18, Color("e6bb7d"))
	description = text(column, "Friends have laid out a rug. The street is dark.\nRestore three power boxes around the lane,\nthen return to the speaker beside your friends.\n\nEvade or fight the patrols. Bring back the light.", 17, Color("c1c6d0"))
	start_button = Button.new()
	start_button.text = "STEP INTO THE LANE"
	start_button.custom_minimum_size.y = 48
	start_button.pressed.connect(func(): game.start_or_resume())
	column.add_child(start_button)
	replay_button = Button.new()
	replay_button.text = "REPLAY THE NIGHT"
	replay_button.pressed.connect(func(): game.restart_mission())
	column.add_child(replay_button)
	replay_button.hide()
	blood_button = CheckButton.new()
	blood_button.text = "Blood effects"
	blood_button.button_pressed = game.blood_enabled
	blood_button.toggled.connect(func(enabled: bool):
		game.blood_enabled = enabled
		game.save_settings())
	column.add_child(blood_button)
	text(column, "Mouse sensitivity", 14, Color("b3b5c0"))
	var sensitivity := HSlider.new()
	sensitivity.min_value = 0.0005
	sensitivity.max_value = 0.006
	sensitivity.step = 0.0001
	sensitivity.value = game.sensitivity
	sensitivity.value_changed.connect(func(value: float):
		game.sensitivity = value
		game.save_settings())
	column.add_child(sensitivity)
	var sound := CheckButton.new()
	sound.text = "Sound"
	sound.button_pressed = game.sound_enabled
	sound.toggled.connect(func(enabled: bool):
		game.sound_enabled = enabled
		game.save_settings())
	column.add_child(sound)
	hint = text(column, "WASD · Mouse · LMB fire · E interact\nR reload · Ctrl crouch · Shift sprint · Space jump\nEsc pause", 14, Color("b3b5c0"))
	var quit_button := Button.new()
	quit_button.text = "QUIT"
	quit_button.pressed.connect(func(): get_tree().quit())
	column.add_child(quit_button)
	show_menu("title")

func text(parent: Node, words: String, size: int, color: Color = Color("edf0f2")) -> Label:
	var label := Label.new()
	label.text = words
	label.add_theme_font_size_override("font_size", size)
	label.modulate = color
	parent.add_child(label)
	return label

func show_menu(state: String) -> void:
	menu.visible = true
	hud.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	replay_button.visible = game.victory
	match state:
		"pause":
			heading.text = "TAKE A BREATH"
			description.text = "Mission paused.\nYour progress is safe for this session."
			start_button.text = "RESUME"
		"won":
			heading.text = "THE LANE IS ALIVE"
			description.text = "Windows glow. Friends begin to dance.\nTonight, there is room to breathe.\n\nStay for the gathering, or play the night again."
			start_button.text = "JOIN YOUR FRIENDS"
		"lost":
			heading.text = "TRY AGAIN"
			description.text = "Use planters and the fountain to break sight.\nPatrol visors brighten just before they fire.\nRestoring a power box recovers 25 health."
			start_button.text = "RESTART MISSION"
	start_button.grab_focus()

func hide_menu() -> void:
	menu.hide()
	hud.show()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	replay_button.hide()

func update() -> void:
	if not is_instance_valid(game.player):
		return
	var reload_text := "RELOADING" if game.player.reload_left > 0 else "%02d / 12" % game.player.ammo
	stats.text = "HEALTH  %03d     /     AMMO  %s" % [game.player.health, reload_text]
	objective.text = "LIGHT UP THE LANE   %d / 3" % game.relays_online
	if game.relays_online == 3:
		objective.text = "RETURN TO YOUR FRIENDS  /  SOUTH COURTYARD"
	if game.victory:
		objective.text = "TONIGHT, WE LIVE"
	controls.text = "WASD  Move   /   E  Speak with friends   /   ESC  Pause" if game.victory else "WASD  Move   /   SHIFT  Sprint   /   CTRL  Crouch   /   LMB  Fire   /   R  Reload   /   E  Interact   /   ESC  Pause"
	stats.visible = not game.victory
	crosshair.visible = not game.victory
	prompt.text = game.interaction_prompt()
	crosshair.text = "×" if game.hit_marker > 0 else "+"
	crosshair.modulate = Color("f4cd8a") if game.hit_marker > 0 else Color.WHITE
	damage.color.a = game.hurt_flash * 0.8 if game.active else 0.0
