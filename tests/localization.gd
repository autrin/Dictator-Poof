extends SceneTree
## Checks language controls, menu fit, signs, and a live notification.

var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if condition:
		print("PASS: ", message)
	else:
		failures += 1
		push_error("FAIL: " + message)

func settle() -> void:
	await process_frame
	await process_frame

func run() -> void:
	var game: Node3D = load("res://scenes/main.tscn").instantiate()
	game.story_mode = false
	root.add_child(game)
	await settle()
	var f2_bound := false
	for event in InputMap.action_get_events("language"):
		if event is InputEventKey and event.physical_keycode == KEY_F2:
			f2_bound = true
	check(f2_bound, "F2 is bound to language switching")
	for language in ["en", "fa"]:
		game.set_language(language, false)
		await settle()
		check(game.hud.language_picker.selected == (1 if language == "fa" else 0), "menu selector follows %s" % language)
		check(game.hud.heading.text == game.localize("brand"), "title menu translates to %s" % language)
		check(game.world.localized_labels[0].label.text == game.localize(game.world.localized_labels[0].key), "world sign translates to %s" % language)
		check(game.hud.quit_button.get_global_rect().end.y <= game.hud.menu.get_global_rect().end.y, "menu controls fit in %s" % language)
	game.start_or_resume()
	game.notify("relay_message_0", 4.0)
	game.set_language("en", false)
	check(game.message_text == "A window lights up. Someone is still awake.", "active notification is English")
	game.set_language("fa", false)
	check(game.message_text == "پنجره‌ای روشن می‌شود. کسی هنوز بیدار است.", "active notification switches to Persian")
	print("RESULT: ", failures, " failure(s)")
	quit(0 if failures == 0 else 1)
