extends SceneTree
## Save and reload through the real title screen. Each run owns a disposable directory.
const Main := preload("res://scenes/main.tscn")
var game: Node3D
var directory: String
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if ok:
		print("PASS: ", message)
	else:
		failures += 1
		push_error("FAIL: " + message)

func launch() -> void:
	game = Main.instantiate()
	game.profiles.directory = directory
	root.add_child(game)
	game.set_language("en", false)
	game.sound_enabled = false

func reload_from_disk() -> void:
	game.pause_run()
	game.free()
	launch()
	game.hud.start_button.pressed.emit()

func approach(target: Node3D) -> void:
	game.world.teleport(target.global_position + Vector3(0, 0.05, 1.5), target.global_position)
	game.player.camera.look_at(target.global_position + Vector3.UP * 1.1)
	await physics_frame
	await physics_frame

func run() -> void:
	directory = ProjectSettings.globalize_path("res://builds/profile-test-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()])
	launch()
	game.hud.name_input.text = "   "
	game.hud.start_button.pressed.emit()
	check(not game.started and game.hud.error_key == "profile_name_needed", "blank names stay on the title screen")
	game.hud.name_input.text = "  سارا  "
	game.hud.start_button.pressed.emit()
	check(game.active and game.profile_name == "سارا" and game.profiles.entries.size() == 1, "create a Persian-named profile from the title")
	if not game.active:
		quit(1)
		return
	var first_id: String = game.profile_id
	game.world.advance()
	game.world.advance()
	await approach(game.world.targets.album_garden)
	game.world.take_photo()
	game.world.take_photo()
	check(game.keepsakes == [0], "looking at the home Haft-Seen earns exactly one print")
	var at: Transform3D = game.player.transform
	var camera: Transform3D = game.player.camera.transform
	reload_from_disk()
	check(game.player.transform.is_equal_approx(at) and game.player.camera.transform.is_equal_approx(camera), "cold continue restores position and view")
	check(game.world.stage == 2 and not game.world.blinds.visible and game.keepsakes == [0], "story and album survive a cold continue")
	game.world.advance()
	game.world.advance()
	game.world.life.begin_trip("bakery")
	game.world.life.board()
	game.world.life._physics_process(0.15)
	var car: Transform3D = game.world.car.transform
	reload_from_disk()
	check(game.world.life.trip_phase == "driving" and game.world.car.transform.is_equal_approx(car) and game.world.sister.get_parent() == game.world.car, "resume the moving car with its passengers")
	game.world.life.disembark("bakery")
	game.world.life.motion.routes.clear()
	game.world.life.finish_arrival()
	game.world.life.dismiss_patrol(false)
	game.world.advance()
	game.world.advance()
	game.world.advance()
	game.world.bakery.add_piece(2)
	game.world.bakery.add_piece(1)
	reload_from_disk()
	check(game.world.stage == 7 and game.world.bakery.selection == [2, 1] and game.world.bakery.camera.is_current(), "unfinished pastry box reopens with the same stock and camera")
	game.world.bakery.add_piece(0)
	game.world.bakery.add_piece(2)
	game.world.bakery.wrap_box()
	await approach(game.world.targets.pastry)
	game.world.take_photo()
	check(game.keepsakes.has(1), "wrapped gift unlocks the pastry counter print")
	game.world.set_out_pastries()
	game.world.stage = 12
	await approach(game.world.targets.gift)
	game.world.take_photo()
	check(game.keepsakes.size() == 3, "Grandma's tea completes the album")
	game.world.advance()
	game.world.cards.choose(2)
	game.world.cards.play(game.world.cards.rules.legal_cards(0)[0])
	var hands: Array = game.world.cards.rules.hands.duplicate(true)
	var trick: Array = game.world.cards.rules.trick.duplicate(true)
	reload_from_disk()
	check(game.world.cards.visible and game.world.cards.rules.hands == hands and game.world.cards.rules.trick == trick and game.world.cards.rules.trump == 2, "mid-trick save retains all four hands, trump and table")
	check(game.world.bakery.selection == [2, 1, 0, 2] and not game.world.pastry_lid.visible, "the chosen pastries are still on Grandma's table")
	game.pause_run()
	game.hud.open_album()
	game.set_language("fa", false)
	check(game.hud.album.inscription.text == game.localize("album_complete"), "completed album reveals Grandma's message in Persian")
	game.return_to_title()
	game.hud.profile_picker.select(game.hud.profile_picker.item_count - 1)
	game.hud.apply_language()
	game.hud.name_input.text = "سارا"
	game.hud.start_button.pressed.emit()
	check(not game.started and game.hud.error_key == "profile_name_taken", "an existing name cannot overwrite another profile")
	game.hud.name_input.text = "Mina"
	game.hud.night_button.pressed.emit()
	var night_id: String = game.profile_id
	game.light_relay(1)
	game.player.health = 64
	game.player.ammo = 5
	game.player.set_gun_drawn(false)
	var guard: CharacterBody3D = game.world.get_children().filter(func(n): return n is CharacterBody3D)[0]
	guard.take_damage(120, guard.position)
	reload_from_disk()
	check(game.profile_id == night_id and night_id != first_id and game.keepsakes.is_empty(), "latest profile selected on relaunch, collections stay independent")
	check(not game.story_mode and game.relays[1].online and game.relays_online == 1 and game.player.health == 64 and game.player.ammo == 5 and not game.player.gun_drawn and game.guards_defeated == 1, "lane resources, power and defeated guard restore")
	game.finish(false)
	game.hud.start_button.pressed.emit()
	check(game.active and game.player.health == 64 and game.relays_online == 1, "retry uses the living save")
	game.light_relay(0)
	game.light_relay(2)
	game.finish(true)
	reload_from_disk()
	check(game.victory and game.world.celebration and game.relays_online == 3, "the completed lane remains explorable after relaunch")
	# Simulate an interrupted newest generation, leaving the other generation intact.
	game.save_progress()
	var rev: int = game.profiles.entries[night_id].revision
	var path := directory.path_join(night_id + (".a" if rev % 2 == 1 else ".b"))
	var torn := FileAccess.open(path, FileAccess.WRITE)
	torn.store_string("DPF1")
	torn.close()
	game.free()
	launch()
	check(game.profiles.entries[night_id].revision == rev - 1 and game.profiles.entries.has(first_id), "damaged latest save falls back without affecting the other profile")
	game.free()
	var folder := DirAccess.open(directory)
	for file in folder.get_files():
		folder.remove(file)
	DirAccess.remove_absolute(directory)
	print("RESULT: ", failures, " failure(s)")
	quit(0 if failures == 0 else 1)
