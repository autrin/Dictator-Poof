extends CanvasLayer
## Native Godot GUI. Anchors and containers keep it usable when resizing.

const TEAL := Color("8de0d0")
const Album := preload("res://scripts/family_album.gd")
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
var album := Album.new()
var spread := HBoxContainer.new()
var cover := TextureRect.new()
var actions := VBoxContainer.new()
var settings := VBoxContainer.new()
var profile_row := HBoxContainer.new()
var profile_picker := OptionButton.new()
var name_input := LineEdit.new()
var profile_label: Label
var status_label: Label
var settings_button := Button.new()
var album_button := Button.new()
var title_button := Button.new()
var back_button := Button.new()
var photo_hint: Label
var error_key := ""
var confirm_restart := ConfirmationDialog.new()
var confirm_quit := ConfirmationDialog.new()
var shade := ColorRect.new()
var print_toast := PanelContainer.new()
var print_preview := TextureRect.new()
var print_caption: Label
var print_index := -1
var print_until := 0.0

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
	objective.custom_minimum_size.x = 454
	hud_place = text(top, "", 12, Color("dbc1a4"))
	photo_hint = text(top, "", 16, TEAL)
	photo_hint.hide()
	stats = Label.new()
	stats.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	stats.offset_left = 32
	stats.offset_top = -82
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
	controls.offset_left = 32
	controls.offset_top = -38
	hud.add_child(controls)
	crosshair = Label.new()
	crosshair.text = "+"
	crosshair.add_theme_font_size_override("font_size", 28)
	crosshair.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	crosshair.offset_left = -9
	crosshair.offset_top = -20
	hud.add_child(crosshair)
	prompt = Label.new()
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	prompt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	prompt.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	prompt.offset_left = -450
	prompt.offset_right = 450
	prompt.offset_top = -165
	prompt.offset_bottom = -85
	prompt.add_theme_font_size_override("font_size", 22)
	prompt.add_theme_color_override("font_shadow_color", Color.BLACK)
	prompt.add_theme_constant_override("shadow_outline_size", 5)
	prompt.add_theme_font_override("font", preload("res://assets/fonts/vazirmatn/Vazirmatn.ttf"))
	prompt.modulate = TEAL
	hud.add_child(prompt)
	hud.add_child(print_toast)
	print_toast.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	print_toast.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	print_toast.offset_left = -224
	print_toast.offset_right = -22
	print_toast.offset_top = 20
	var mat := StyleBoxFlat.new()
	mat.bg_color = Album.PAPER
	mat.set_content_margin_all(10)
	print_toast.add_theme_stylebox_override("panel", mat)
	var print_column := VBoxContainer.new()
	print_toast.add_child(print_column)
	print_column.add_child(print_preview)
	print_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	print_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	print_preview.custom_minimum_size.y = 128
	print_caption = text(print_column, "", 15, Album.INK)
	print_caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	print_toast.hide()
	root.add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.035, 0.065, 0.055, 0.66)
	menu = PanelContainer.new()
	root.add_child(menu)
	menu.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	menu.offset_left = -526
	menu.offset_right = 526
	menu.offset_top = -315
	menu.offset_bottom = 315
	var style := StyleBoxFlat.new()
	style.bg_color = Color("182f2c")
	style.border_color = Color("b99b6c")
	style.set_border_width_all(1)
	style.content_margin_left = 34
	style.content_margin_right = 34
	style.content_margin_top = 22
	style.content_margin_bottom = 22
	menu.add_theme_stylebox_override("panel", style)
	var pages := Control.new()
	menu.add_child(pages)
	pages.add_child(spread)
	spread.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	spread.add_theme_constant_override("separation", 32)
	cover.texture = Album.print_texture(0)
	cover.custom_minimum_size.x = 386
	cover.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	cover.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	spread.add_child(cover)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 6)
	spread.add_child(column)
	album.game = game
	pages.add_child(album)
	album.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	album.closed.connect(close_page)
	album.hide()
	tagline = text(column, "", 14, TEAL)
	heading = text(column, "DICTATOR POOF", 34)
	chapter = text(column, "", 18, Color("e6bb7d"))
	description = text(column, "Friends have laid out a rug. The street is dark.\nRestore three power boxes around the lane,\nthen return to the speaker beside your friends.\n\nEvade or fight the patrols. Bring back the light.", 17, Color("c1c6d0"))
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(actions)
	actions.add_theme_constant_override("separation", 6)
	profile_label = text(actions, "", 15, TEAL)
	actions.add_child(profile_row)
	profile_row.add_child(profile_picker)
	profile_picker.custom_minimum_size.x = 180
	profile_picker.fit_to_longest_item = false
	profile_picker.item_selected.connect(func(_i):
		error_key = ""
		apply_language())
	profile_row.add_child(name_input)
	name_input.max_length = 32
	name_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_input.text_submitted.connect(func(_value): primary_action())
	name_input.text_changed.connect(func(_value):
		if error_key in ["profile_name_needed", "profile_name_taken"]:
			show_profile_error(""))
	status_label = text(column, "", 15, Color("ffbc95"))
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	start_button = Button.new()
	start_button.text = "STEP INTO THE LANE"
	start_button.custom_minimum_size.y = 48
	start_button.pressed.connect(primary_action)
	actions.add_child(start_button)
	var accent := StyleBoxFlat.new()
	accent.bg_color = Color("dec292")
	accent.set_corner_radius_all(3)
	start_button.add_theme_stylebox_override("normal", accent)
	for state in ["hover", "pressed", "hover_pressed"]:
		var lit := accent.duplicate() as StyleBoxFlat
		lit.bg_color = Color("f0d5a6") if state == "hover" else Color("c3a473")
		start_button.add_theme_stylebox_override(state, lit)
	for ink in ["font_color", "font_focus_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color"]:
		start_button.add_theme_color_override(ink, Album.INK)
	night_button = Button.new()
	night_button.pressed.connect(func(): game.begin_profile(name_input.text, true))
	actions.add_child(night_button)
	replay_button = Button.new()
	replay_button.text = "REPLAY THE NIGHT"
	replay_button.pressed.connect(func():
		if game.profile_id.is_empty():
			game.restart_mission()
		else:
			confirm_restart.popup_centered())
	actions.add_child(replay_button)
	add_child(confirm_restart)
	confirm_restart.theme = theme
	confirm_restart.confirmed.connect(game.restart_mission)
	add_child(confirm_quit)
	confirm_quit.theme = theme
	confirm_quit.confirmed.connect(func(): get_tree().quit())
	replay_button.hide()
	actions.add_child(album_button)
	album_button.pressed.connect(open_album)
	actions.add_child(settings_button)
	settings_button.pressed.connect(open_settings)
	actions.add_child(title_button)
	title_button.pressed.connect(game.return_to_title)
	column.add_child(settings)
	settings.hide()
	blood_button = CheckButton.new()
	blood_button.text = "Blood effects"
	blood_button.button_pressed = game.blood_enabled
	blood_button.toggled.connect(func(enabled: bool):
		game.blood_enabled = enabled
		game.save_settings())
	settings.add_child(blood_button)
	sensitivity_label = text(settings, "", 14, Color("b3b5c0"))
	var sensitivity := HSlider.new()
	sensitivity.min_value = 0.0005
	sensitivity.max_value = 0.006
	sensitivity.step = 0.0001
	sensitivity.value = game.sensitivity
	sensitivity.value_changed.connect(func(value: float):
		game.sensitivity = value
		game.save_settings())
	settings.add_child(sensitivity)
	sound_button = CheckButton.new()
	sound_button.button_pressed = game.sound_enabled
	sound_button.toggled.connect(func(enabled: bool):
		game.sound_enabled = enabled
		game.save_settings())
	settings.add_child(sound_button)
	music_label = text(settings, "", 14, Color("b3b5c0"))
	music_slider = HSlider.new()
	music_slider.min_value = 0.0
	music_slider.max_value = 1.0
	music_slider.step = 0.01
	music_slider.value = game.music_volume
	music_slider.value_changed.connect(func(value: float):
		game.music_volume = value
		game.save_settings())
	settings.add_child(music_slider)
	var language_row := HBoxContainer.new()
	language_row.add_theme_constant_override("separation", 16)
	column.add_child(language_row)
	language_label = text(language_row, "", 14, Color("b3b5c0"))
	language_picker = OptionButton.new()
	language_picker.add_item("English")
	language_picker.add_item("فارسی")
	language_picker.item_selected.connect(func(index: int): game.set_language("fa" if index == 1 else "en"))
	language_row.add_child(language_picker)
	hint = text(settings, "", 14, Color("c2c8bd"))
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	settings.add_child(back_button)
	back_button.pressed.connect(close_page)
	quit_button = Button.new()
	quit_button.pressed.connect(game.quit_game)
	actions.add_child(quit_button)
	populate_profiles()
	show_menu("title")

func populate_profiles() -> void:
	profile_picker.clear()
	for id in game.profiles.sorted_ids():
		profile_picker.add_item(game.profiles.entries[id].name)
		profile_picker.set_item_metadata(profile_picker.item_count - 1, id)
	profile_picker.add_item(game.localize("profile_new"))
	profile_picker.set_item_metadata(profile_picker.item_count - 1, "")
	profile_picker.select(0)
	name_input.clear()

func selected_id() -> String:
	return profile_picker.get_item_metadata(profile_picker.selected)

func primary_action() -> void:
	if menu_state != "title":
		game.start_or_resume()
	elif selected_id() == "":
		game.begin_profile(name_input.text, not game.story_mode)
	else:
		game.load_profile(selected_id())

func show_profile_error(key: String) -> void:
	error_key = key
	apply_language()

func open_settings() -> void:
	settings.show()
	actions.hide()
	description.hide()
	heading.text = game.localize("settings")
	back_button.grab_focus()

func saved_objective(run: Dictionary) -> String:
	if run.story:
		return game.localize("action_" + game.Nowruz.STEPS[run.visit.stage])
	if run.victory:
		return game.localize("objective_won")
	var powered: int = run.lane.lights.count(true)
	if powered == 3:
		return game.localize("objective_return")
	return game.localize("objective_power") % powered

func open_album() -> void:
	spread.hide()
	album.show()
	album.refresh()
	album.back.grab_focus()

func close_page() -> void:
	spread.show()
	settings.hide()
	album.hide()
	actions.show()
	description.show()
	apply_language()
	start_button.grab_focus()

func show_print(index: int) -> void:
	print_index = index
	print_until = game.run_time + 4.0
	print_preview.texture = Album.print_texture(index)

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
	shade.show()
	error_key = "save_failed" if game.save_failed else ""
	hud.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if game.story_mode and is_instance_valid(game.world.cards):
		game.world.cards.hide()
	if game.story_mode and game.world.bakery.packing:
		game.world.bakery.overlay.hide()
	var can_restart: bool = game.profile_id != "" and state in ["pause", "lost"]
	replay_button.visible = game.victory or can_restart or (state == "pause" and game.story_mode)
	close_page()
	if state == "title" and selected_id() == "":
		name_input.grab_focus()
	else:
		start_button.grab_focus()

func apply_language() -> void:
	menu.layout_direction = Control.LAYOUT_DIRECTION_RTL if game.language == "fa" else Control.LAYOUT_DIRECTION_LTR
	tagline.text = game.profile_name if game.started and game.profile_name != "" else game.localize("tagline")
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
	var on_title := menu_state == "title"
	var fresh := selected_id() == ""
	profile_picker.set_item_text(profile_picker.item_count - 1, game.localize("profile_new"))
	profile_label.text = game.localize("profile_label")
	profile_label.visible = on_title
	profile_row.visible = on_title
	profile_picker.visible = profile_picker.item_count > 1
	name_input.visible = fresh
	name_input.placeholder_text = game.localize("profile_name")
	name_input.accessibility_name = name_input.placeholder_text
	album_button.text = game.localize("album_count") % game.keepsakes.size()
	album_button.visible = not on_title
	title_button.visible = not on_title and game.profile_id != ""
	title_button.text = game.localize("to_title")
	settings_button.text = game.localize("settings")
	back_button.text = game.localize("back")
	status_label.visible = error_key != ""
	if status_label.visible:
		status_label.text = game.localize(error_key)
	confirm_restart.title = game.localize("restart")
	confirm_restart.dialog_text = game.localize("restart_confirm")
	confirm_restart.ok_button_text = game.localize("restart")
	confirm_restart.cancel_button_text = game.localize("back")
	confirm_quit.title = game.localize("quit")
	confirm_quit.dialog_text = game.localize("quit_unsaved")
	confirm_quit.ok_button_text = game.localize("quit")
	confirm_quit.cancel_button_text = game.localize("back")
	night_button.visible = on_title and game.story_mode and fresh
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
				description.text = game.localize("album_opening")
				start_button.text = game.localize("nowruz_start")
			if not fresh:
				var run: Dictionary = game.profiles.entries[selected_id()].run
				chapter.text = game.localize("nowruz_chapter" if run.story else "chapter")
				description.text = saved_objective(run)
				start_button.text = game.localize("continue_game")
		"pause":
			heading.text = game.localize("pause_heading")
			description.text = game.localize("pause_description")
			if game.profile_id != "" and not game.save_failed:
				description.text = game.localize("saved_as") % game.profile_name
			start_button.text = game.localize("resume")
		"won":
			heading.text = game.localize("won_heading")
			description.text = game.localize("won_description")
			start_button.text = game.localize("join")
		"lost":
			heading.text = game.localize("lost_heading")
			description.text = game.localize("lost_description")
			start_button.text = game.localize("retry_save" if game.profile_id != "" else "restart")
	if settings.visible:
		heading.text = game.localize("settings")
	var index := 2
	var stage: int = game.world.stage if game.story_mode else -1
	if on_title and not fresh:
		var run: Dictionary = game.profiles.entries[selected_id()].run
		stage = run.visit.stage if run.story else -1
	if stage >= 0:
		index = 0 if stage < 5 else 1 if stage < 9 else 2
	cover.texture = Album.print_texture(index)
	if album.visible:
		album.refresh()
	update()

func hide_menu() -> void:
	menu.hide()
	shade.hide()
	hud.show()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if game.story_mode and is_instance_valid(game.world.cards):
		game.world.cards.show()
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if game.story_mode and game.world.bakery.packing:
		game.world.bakery.overlay.show()
		hud.hide()
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	replay_button.hide()

func update() -> void:
	if not is_instance_valid(game.player):
		return
	photo_hint.hide()
	print_toast.visible = print_index >= 0 and game.run_time < print_until and game.keepsakes.has(print_index)
	if print_toast.visible:
		print_caption.text = game.localize("photo_saved_%d" % print_index)
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
		if game.active:
			hud_place.text += game.world.bearing()
		controls.text = game.localize("story_controls")
		stats.visible = false
		crosshair.text = "·"
		crosshair.visible = true
		if game.active and game.world.photo_subject() >= 0:
			photo_hint.text = game.localize("photo_prompt")
			photo_hint.show()
		if is_instance_valid(game.world.cards) and game.world.cards.visible:
			prompt.text = ""
			crosshair.hide()
	if game.active and game.save_failed:
		photo_hint.text = game.localize("save_failed_short")
		photo_hint.show()
