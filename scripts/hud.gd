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
var music_label: Label
var music_slider: HSlider
var language_label: Label
var language_picker: OptionButton
var quit_button: Button
var menu_state := "title"
var night_button: Button
var transition: ColorRect

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
	transition = ColorRect.new()
	transition.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	transition.mouse_filter = Control.MOUSE_FILTER_IGNORE
	transition.color = Color(0, 0, 0, 0)
	root.add_child(transition)
	hud = Control.new()
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(hud)
	var top := VBoxContainer.new()
	var top_panel := PanelContainer.new()
	top_panel.position = Vector2(20, 18)
	var top_style := StyleBoxFlat.new()
	top_style.bg_color = Color(0.035, 0.05, 0.06, 0.78)
	top_style.set_content_margin_all(12)
	top_panel.add_theme_stylebox_override("panel", top_style)
	hud.add_child(top_panel)
	top_panel.add_child(top)
	hud_title = text(top, "", 16, TEAL)
	objective = text(top, "LIGHT UP THE LANE   0 / 3", 25)
	objective.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	objective.custom_minimum_size.x = 620
	hud_place = text(top, "", 12, Color("dbc1a4"))
	stats = Label.new()
	stats.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	stats.position = Vector2(32, -82)
	stats.add_theme_font_size_override("font_size", 24)
	hud.add_child(stats)
	controls = Label.new()
	controls.text = game.localize("controls")
	controls.add_theme_font_size_override("font_size", 14)
	controls.add_theme_color_override("font_shadow_color", Color.BLACK)
	controls.add_theme_constant_override("shadow_offset_y", 2)
	controls.add_theme_constant_override("shadow_outline_size", 2)
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
	prompt.add_theme_color_override("font_shadow_color", Color.BLACK)
	prompt.add_theme_constant_override("shadow_outline_size", 5)
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
	column.add_theme_constant_override("separation", 4)
	menu.add_child(column)
	tagline = text(column, "", 13, TEAL)
	heading = text(column, "DICTATOR POOF", 34)
	chapter = text(column, "", 18, Color("e6bb7d"))
	description = text(column, "Friends have laid out a rug. The street is dark.\nRestore three power boxes around the lane,\nthen return to the speaker beside your friends.\n\nEvade or fight the patrols. Bring back the light.", 17, Color("c1c6d0"))
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.custom_minimum_size.x = 490
	start_button = Button.new()
	start_button.text = "STEP INTO THE LANE"
	start_button.custom_minimum_size.y = 48
	start_button.pressed.connect(func(): game.start_or_resume())
	column.add_child(start_button)
	night_button = Button.new()
	night_button.pressed.connect(func(): game.start_night())
	column.add_child(night_button)
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
	music_label = text(column, "", 14, Color("b3b5c0"))
	music_slider = HSlider.new()
	music_slider.min_value = 0.0
	music_slider.max_value = 1.0
	music_slider.step = 0.01
	music_slider.value = game.music_volume
	music_slider.value_changed.connect(func(value: float):
		game.music_volume = value
		game.save_settings())
	column.add_child(music_slider)
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
	if game.story_mode and is_instance_valid(game.world.cards):
		game.world.cards.hide()
	replay_button.visible = game.victory or (game.story_mode and state == "pause")
	apply_language()
	start_button.grab_focus()

func apply_language() -> void:
	tagline.text = game.localize("tagline")
	chapter.text = game.localize("chapter")
	hud_title.text = game.localize("hud_title")
	hud_place.text = game.localize("lane_night_place" if game.late_night else "hud_place")
	replay_button.text = game.localize("story_restart" if game.story_mode else "replay")
	blood_button.text = game.localize("blood")
	sensitivity_label.text = game.localize("sensitivity")
	sound_button.text = game.localize("sound")
	music_label.text = game.localize("music_volume")
	language_label.text = game.localize("language")
	language_picker.select(1 if game.language == "fa" else 0)
	hint.text = game.localize("hint")
	quit_button.text = game.localize("quit")
	night_button.text = game.localize("night_start")
	night_button.visible = menu_state == "title" and game.story_mode
	blood_button.visible = not game.story_mode
	if game.story_mode:
		hud_title.text = game.localize("nowruz_chapter")
		hint.text = game.localize("story_controls")
		hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	chapter.text = game.localize("nowruz_chapter") if game.story_mode else game.localize("chapter")
	match menu_state:
		"title":
			heading.text = game.localize("brand")
			description.text = game.localize("title_description")
			start_button.text = game.localize("start")
			if game.story_mode:
				description.text = game.localize("nowruz_description")
				start_button.text = game.localize("nowruz_start")
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
	if game.story_mode and is_instance_valid(game.world.cards):
		game.world.cards.show()
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
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
	transition.color.a = clampf(game.world.transition_left * 2, 0, 1) if game.story_mode else 0.0
	if game.story_mode:
		objective.text = game.world.objective()
		hud_place.text = game.localize("story_time") % game.world.rules.clock_text()
		controls.text = game.localize("story_controls")
		stats.visible = false
		crosshair.text = "·"
		crosshair.visible = true
		if is_instance_valid(game.world.cards) and game.world.cards.visible:
			prompt.text = ""
			crosshair.hide()
