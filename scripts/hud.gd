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
var tagline: Label
var chapter: Label
var hud_title: Label
var hud_place: Label
var sensitivity_label: Label
var sound_button: CheckButton
var language_label: Label
var language_picker: OptionButton
var quit_button: Button
var menu_state := "title"

func _ready() -> void:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	var theme := Theme.new()
	theme.default_font_size = 18
	theme.default_font = preload("res://assets/fonts/vazirmatn/Vazirmatn.ttf")
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
	hud_title = text(top, "", 16, TEAL)
	objective = text(top, "LIGHT UP THE LANE   0 / 3", 25)
	hud_place = text(top, "", 12, Color("dbc1a4"))
	stats = Label.new()
	stats.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	stats.position = Vector2(32, -82)
	stats.add_theme_font_size_override("font_size", 24)
	hud.add_child(stats)
	controls = Label.new()
	controls.text = game.localize("controls")
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
	prompt.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	prompt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	prompt.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	prompt.position = Vector2(-450, -165)
	prompt.size = Vector2(900, 80)
	prompt.add_theme_font_size_override("font_size", 22)
	prompt.add_theme_font_override("font", preload("res://assets/fonts/vazirmatn/Vazirmatn.ttf"))
	prompt.modulate = TEAL
	hud.add_child(prompt)
	menu = PanelContainer.new()
	root.add_child(menu)
	menu.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	menu.offset_left = -285
	menu.offset_right = 285
	menu.offset_top = -350
	menu.offset_bottom = 350
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
	column.add_theme_constant_override("separation", 6)
	menu.add_child(column)
	tagline = text(column, "", 13, TEAL)
	heading = text(column, "DICTATOR POOF", 40)
	chapter = text(column, "", 18, Color("e6bb7d"))
	description = text(column, "Friends have laid out a rug. The street is dark.\nRestore three power boxes around the lane,\nthen return to the speaker beside your friends.\n\nEvade or fight the patrols. Bring back the light.", 17, Color("c1c6d0"))
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.custom_minimum_size.x = 490
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
	sensitivity_label = text(column, "", 14, Color("b3b5c0"))
	var sensitivity := HSlider.new()
	sensitivity.min_value = 0.0005
	sensitivity.max_value = 0.006
	sensitivity.step = 0.0001
	sensitivity.value = game.sensitivity
	sensitivity.value_changed.connect(func(value: float):
		game.sensitivity = value
		game.save_settings())
	column.add_child(sensitivity)
	sound_button = CheckButton.new()
	sound_button.button_pressed = game.sound_enabled
	sound_button.toggled.connect(func(enabled: bool):
		game.sound_enabled = enabled
		game.save_settings())
	column.add_child(sound_button)
	var language_row := HBoxContainer.new()
	language_row.add_theme_constant_override("separation", 16)
	column.add_child(language_row)
	language_label = text(language_row, "", 14, Color("b3b5c0"))
	language_picker = OptionButton.new()
	language_picker.add_item("English")
	language_picker.add_item("فارسی")
	language_picker.item_selected.connect(func(index: int): game.set_language("fa" if index == 1 else "en"))
	language_row.add_child(language_picker)
	hint = text(column, "", 13, Color("b3b5c0"))
	quit_button = Button.new()
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
	menu_state = state
	menu.visible = true
	hud.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	replay_button.visible = game.victory
	apply_language()
	start_button.grab_focus()

func apply_language() -> void:
	tagline.text = game.localize("tagline")
	chapter.text = game.localize("chapter")
	hud_title.text = game.localize("hud_title")
	hud_place.text = game.localize("hud_place")
	replay_button.text = game.localize("replay")
	blood_button.text = game.localize("blood")
	sensitivity_label.text = game.localize("sensitivity")
	sound_button.text = game.localize("sound")
	language_label.text = game.localize("language")
	language_picker.select(1 if game.language == "fa" else 0)
	hint.text = game.localize("hint")
	quit_button.text = game.localize("quit")
	match menu_state:
		"title":
			heading.text = game.localize("brand")
			description.text = game.localize("title_description")
			start_button.text = game.localize("start")
		"pause":
			heading.text = game.localize("pause_heading")
			description.text = game.localize("pause_description")
			start_button.text = game.localize("resume")
		"won":
			heading.text = game.localize("won_heading")
			description.text = game.localize("won_description")
			start_button.text = game.localize("join")
		"lost":
			heading.text = game.localize("lost_heading")
			description.text = game.localize("lost_description")
			start_button.text = game.localize("restart")
	update()

func hide_menu() -> void:
	menu.hide()
	hud.show()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	replay_button.hide()

func update() -> void:
	if not is_instance_valid(game.player):
		return
	var reload_text: String = game.localize("holstered") if not game.player.gun_drawn else game.localize("reloading") if game.player.reload_left > 0 else "%02d / 12" % game.player.ammo
	stats.text = game.localize("stats") % [game.player.health, reload_text]
	objective.text = game.localize("objective_power") % game.relays_online
	if game.relays_online == 3:
		objective.text = game.localize("objective_return")
	if game.victory:
		objective.text = game.localize("objective_won")
	controls.text = game.localize("controls_won") if game.victory else game.localize("controls")
	stats.visible = not game.victory
	crosshair.visible = not game.victory
	prompt.text = game.interaction_prompt()
	crosshair.text = "×" if game.hit_marker > 0 else "+"
	crosshair.modulate = Color("f4cd8a") if game.hit_marker > 0 else Color.WHITE
	damage.color.a = game.hurt_flash * 0.8 if game.active else 0.0
