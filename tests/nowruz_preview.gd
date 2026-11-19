extends SceneTree

const Preview := preload("res://scripts/nowruz_preview.gd")
const Scene := preload("res://scenes/nowruz_preview.tscn")
const GrandmaShortcut := preload("res://scenes/grandmas_visit.tscn")
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error("FAIL: " + message)
	else:
		print("PASS: " + message)

func launch(checkpoint: Preview.Checkpoint) -> Preview:
	var game: Preview = Scene.instantiate()
	game.start_at = checkpoint
	root.add_child(game)
	game.sound_enabled = false
	return game

func wait_for_arrival(game: Preview) -> void:
	for frame in range(2400):
		await physics_frame
		if not game.world.life.busy() and not game.world.life.family_busy():
			return
	check(false, "arrival completes from the player's spawn")

func run() -> void:
	var morning := launch(Preview.Checkpoint.WAKE_UP)
	check(morning.active and morning.world.blinds.visible and morning.world.stage == 0, "Wake Up starts in bed")
	var shop: Node = morning.world.bakery
	check(not shop.pack_assortment([0, 1, 2, -1] as Array[int]) and shop.selection.is_empty() and shop.stock[0].size() == 6, "an invalid assortment leaves the trays and chapter untouched")
	morning.interact()
	check(morning.world.objective() == morning.localize("action_blinds"), "morning continues through the regular wake-up action")
	morning.free()

	var bakery := launch(Preview.Checkpoint.BAKERY_ARRIVAL)
	check(bakery.world.life.trip_phase == "arriving" and not bakery.world.scarf.visible, "Bakery Arrival begins before the patrol stop")
	bakery.pause_run()
	var sister_at: Vector3 = bakery.world.sister.position
	await create_timer(0.3).timeout
	check(sister_at == bakery.world.sister.position, "pause holds the arrival")
	bakery.start_or_resume()
	await wait_for_arrival(bakery)
	check(bakery.world.life.patrol_phase == "ready" and bakery.world.objective() == bakery.localize("action_stop"), "the bakery arrival leads into the live patrol interaction")
	bakery.free()

	var visit: Preview = GrandmaShortcut.instantiate()
	root.add_child(visit)
	visit.sound_enabled = false
	check(visit.start_at == Preview.Checkpoint.VISIT_GRANDMA and visit.world.pastry_box.get_parent() == visit.world.sister, "the existing F6 shortcut opens with the sister carrying the box")
	await wait_for_arrival(visit)
	check(visit.world.objective() == visit.localize("action_sal") and not visit.world.pastry_lid.visible, "Grandma's arrival completes the real gift handoff")
	visit.free()

	var lunch := launch(Preview.Checkpoint.FAMILY_LUNCH)
	await physics_frame
	await physics_frame
	check(lunch.world.serving.visible and lunch.world.life.eating and lunch.world.rules.minute == 14 * 60, "Family Lunch starts during the meal")
	check(lunch.world.bakery.sealed and lunch.world.bakery.selection.size() == 4 and not lunch.world.pastry_lid.visible, "the family's packed pastries are on the tea table")
	check(lunch.player.camera.is_current() and not lunch.world.bakery.packing, "lunch starts with first-person controls")
	lunch.set_language("fa", false)
	check(lunch.world.prompt().contains(lunch.localize("action_cards")), "the next interaction is reachable in Persian from the lunch spawn")
	Input.action_press("interact")
	await physics_frame
	await physics_frame
	Input.action_release("interact")
	var cards: Control = lunch.world.cards
	check(is_instance_valid(cards) and cards.visible, "pressing interact at lunch opens the actual Hokm table")
	lunch.pause_run()
	lunch.hud.replay_button.pressed.emit()
	check(lunch.active and lunch.world.life.eating and not is_instance_valid(cards) and not is_instance_valid(lunch.world.cards), "restarting from the menu restores lunch and releases the previous card table")
	lunch.start_night()
	lunch.restart_mission()
	check(not lunch.story_mode and lunch.relays.size() == 3, "restarting the night mission stays in the night mission")
	lunch.free()
	await process_frame
	print("RESULT: ", failures, " failure(s)")
	quit(0 if failures == 0 else 1)
