extends SceneTree
var failures := 0
var game: Node3D
var ride_checked := false
const Rules := preload("res://scripts/day_rules.gd")
const HokmRules := preload("res://scripts/hokm_rules.gd")

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error("FAIL: " + message)
	elif message != "legal Hokm move accepted":
		print("PASS: " + message)

func settle() -> void:
	await physics_frame
	await physics_frame
	await process_frame

func approach(target: Node3D, offset: Vector3) -> void:
	game.player.position = target.global_position + offset
	game.player.velocity = Vector3.ZERO
	game.player.camera.look_at(target.global_position + Vector3(0, 1.1, 0))
	await settle()

func wait_scene() -> void:
	for frame in range(3600):
		await physics_frame
		if game.world.life.trip_phase == "driving" and not ride_checked:
			ride_checked = true
			var car_at: Vector3 = game.world.car.position
			var player_at: Vector3 = game.player.position
			game.pause_run()
			await create_timer(0.4).timeout
			check(game.world.car.position == car_at and game.player.position == player_at, "pause freezes the car and its passenger")
			game.start_or_resume()
			await create_timer(0.4).timeout
			check(game.world.car.position.distance_to(car_at) > 0.5, "the car travels continuously after resume")
			check(game.player.position.distance_to(game.world.car.position) < 1.5, "back-seat viewpoint follows the moving car")
			var phase: int = game.world.stage
			game.interact()
			check(game.world.stage == phase, "repeated interaction cannot skip a moving scene")
		if not game.world.life.busy() and not game.world.life.family_busy():
			return
	for actor in game.world.life.motion.routes:
		print("Blocked actor: ", actor.position, " heading to ", game.world.life.motion.routes[actor].points)
	check(false, "scene finishes without blocked routes: " + game.world.life.trip_phase)

func run() -> void:
	var rules := Rules.new()
	rules.ramadan = true
	rules.minute = rules.dawn - 1
	check(rules.public_service_allowed(), "pre-dawn service is permitted")
	rules.minute = rules.dawn
	check(not rules.public_service_allowed(), "service closes at dawn")
	rules.minute = rules.iftar - 1
	check(not rules.public_service_allowed(), "service stays closed until iftar")
	check(rules.consume(false, true) == "drink_safe", "private meals do not trigger enforcement")
	check(rules.consume(true, false) == "drink_safe", "unwitnessed consumption does not trigger enforcement")
	check(rules.consume(true, true) == "drink_fine", "first witnessed daytime incident is cited")
	check(rules.consume(true, true) == "drink_detained", "repeat incident leads to detention")
	rules.minute = rules.iftar
	check(rules.public_service_allowed() and rules.consume(true, true) == "drink_safe", "iftar permits public service and consumption")
	rules.ramadan = false
	rules.minute = 720
	check(rules.public_service_allowed(), "ordinary days do not inherit Ramadan restrictions")
	var example := HokmRules.new()
	example.trump = 2
	example.hands = [[0], [1, 26], [12], [27]]
	check(example.play(0, 0) and not example.play(1, 26), "a player holding the led suit cannot play trump")
	check(example.play(1, 1) and example.play(2, 12) and example.play(3, 27), "void player can trump a trick")
	check(example.winner() == 3, "trump beats the ace of the led suit")
	example.collect_trick()
	check(example.turn == 3 and example.scores[1] == 1, "trick winner leads and partnership earns the trick")
	for seed_value in range(8):
		var hand := HokmRules.new()
		hand.deal(seed_value)
		check(hand.hands[0].size() == 5 and hand.deck.size() == 47, "hakem sees only first five cards")
		hand.choose_trump(seed_value % 4)
		var unique := {}
		for cards in hand.hands:
			for card in cards:
				unique[card] = true
		check(unique.size() == 52, "full deal contains 52 unique cards")
		var plays := 0
		while not hand.finished() and plays < 52:
			check(hand.play(hand.turn, hand.computer_card()), "legal Hokm move accepted")
			plays += 1
			if hand.trick.size() == 4:
				hand.collect_trick()
		check(hand.finished(), "hand terminates with a team taking seven tricks")
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await settle()
	game.sound_enabled = false
	check(game.story_mode and game.world.stage == 0, "Nowruz is the default opening")
	for language in ["en", "fa"]:
		game.set_language(language, false)
		await settle()
		check(game.hud.menu.get_global_rect().end.y <= 720, "title menu fits the viewport in " + language)
		check(game.hud.quit_button.get_global_rect().end.y <= 720, "quit button remains visible in " + language)
	game.start_or_resume()
	game.player.set_gun_drawn(true)
	check(not game.player.gun_drawn and game.player.empty_hands.visible, "family chapter starts with hands and no combat equipment")
	check(not game.world.rules.ramadan and game.world.cafe.is_open(), "Nowruz has normal daytime café service; Ramadan is reserved for later")
	for step in range(16):
		await create_timer(0.75).timeout
		if step == 15:
			break
		if step > 0:
			var target: Node3D = game.world.targets[game.world.STEPS[step]]
			game.world.teleport(target.position + Vector3(0, 0.05, 2), target.position)
			game.player.camera.look_at(target.position + Vector3(0, 1.1, 0))
			await settle()
		game.notification_left = 0
		game.interact()
		if step == 3:
			var start_at: Vector3 = game.world.sister.position
			await create_timer(0.4).timeout
			check(game.world.sister.position.distance_to(start_at) > 0.1, "family visibly walks toward the car")
		if step in [4, 8, 13, 14]:
			game.world.teleport(game.world.car.position + Vector3(2, 0.05, 2), game.world.car.position)
		await wait_scene()
		if step == 4:
			check(game.world.life.patrol_phase == "ready" and game.world.life.officers.all(func(actor): return actor.visible), "both uniformed officers approach before the confrontation")
			check(game.world.life.van.position.z > -24, "marked patrol van arrives at the bakery")
			var car_body: Node3D = game.world.car.get_node("Car collider")
			check(car_body.global_position.is_equal_approx(game.world.car.global_position), "moving car collision follows the parked vehicle")
		if step == 5:
			check(game.world.speaker.is_visible_in_tree(), "officer dialogue has a visible label over the officer")
			var officer_head: Vector3 = game.world.officer.global_position + Vector3(0, 1.65, 0)
			check(not game.player.camera.is_position_behind(officer_head), "the speaking officer is in front of the camera")
		if step == 10:
			check(game.world.serving.visible and game.world.life.spoon.visible, "cooking finishes before lunch is served")
		if step == 11:
			var arm: Node3D = game.world.relatives[0].get_node("Right arm/Forearm")
			var before: float = arm.rotation.x
			await create_timer(0.4).timeout
			check(game.world.life.eating and not is_equal_approx(before, arm.rotation.x), "seated relatives lift their utensils during lunch")
		if step == 12:
			check(is_instance_valid(game.world.cards), "Hokm opens from the table")
			if is_instance_valid(game.world.cards):
				var panel: Control = game.world.cards
				game.pause_run()
				check(not panel.visible, "pause hides the card panel")
				game.start_or_resume()
				check(panel.visible and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE, "resume restores cards and pointer")
				panel.rules.choose_trump(0)
				while not panel.rules.finished():
					while panel.rules.trick.size() < 4:
						panel.rules.play(panel.rules.turn, panel.rules.computer_card())
					panel.next_trick()
				panel.next_trick()
				await settle()
		check(game.world.stage == step + 1, "reachable story interaction: " + game.world.STEPS[step])
		if game.world.stage != step + 1:
			break
		if step == 0:
			await approach(game.world.targets.done, Vector3(-1.5, 0.05, 0))
			game.interact()
			check(game.story_mode and game.world.stage == 1, "the lane gate cannot skip the family chapter")
	check(game.world.stage == 15, "whole chapter reaches the return visit")
	check(game.world.cafe.is_open(), "café opens after the family evening")
	var cafe: Node3D = game.world.cafe
	await approach(cafe.counter, cafe.global_basis.z * 1.5 + Vector3(0, 0.05, 0))
	game.interact()
	check(cafe.orders == 1 and cafe.player_cup.visible, "ordering serves a visible coffee at the terrace table")
	game.world.rules.minute = 600
	game.world.rules.ramadan = true
	cafe.refresh_service()
	game.interact()
	check(cafe.orders == 1 and not cafe.player_cup.visible, "daytime orders are refused and service is cleared")
	game.world.rules.minute = 1200
	game.world.rules.ramadan = false
	cafe.refresh_service()
	for i in range(cafe.shelves.size()):
		await approach(cafe.shelves[i], cafe.global_basis.z * 0.8 + Vector3(0, 0.05, 0))
		game.interact()
		check(game.message_key == "book_%d" % i, "real book %d can be read independently" % i)
		game.set_language("fa", false)
		check(game.message_text == game.localize("book_%d" % i), "open book description changes language immediately")
	await approach(cafe.player_seat, cafe.global_basis.z * 1.2 + Vector3(0, 0.05, 0))
	game.interact()
	check(cafe.seated and is_equal_approx(game.player.camera.position.y, 1.16), "player sits at the correct eye height")
	var sitting_at: Vector3 = game.player.position
	Input.action_press("forward")
	await create_timer(0.3).timeout
	Input.action_release("forward")
	check(game.player.position.is_equal_approx(sitting_at), "seated movement cannot push through furniture")
	game.pause_run()
	game.start_or_resume()
	cafe.stand()
	check(not cafe.seated and game.player.position.is_equal_approx(cafe.exit_position), "standing restores the clear approach position after pause")
	for doorway in [Vector3(4.2, 0.05, -3), Vector3(4.2, 0.05, -37)]:
		game.player.position = doorway
		game.player.velocity = Vector3.ZERO
		await settle()
		var door_hit: KinematicCollision3D = game.player.move_and_collide(Vector3(0, 0, -5))
		if door_hit != null:
			print("Door collision: ", doorway, " ", door_hit.get_collider().get_path(), " ", door_hit.get_position())
		check(door_hit == null, "house doorway admits the full player capsule")
	game.world.rules.minute = 600
	game.world.teleport(game.world.officer.position + Vector3(0, 0.05, 2), game.world.officer.position)
	await settle()
	game.world.drink()
	check(game.world.rules.citations == 0, "Nowruz drinking does not trigger Ramadan enforcement")
	game.world.rules.ramadan = true
	game.world.drink()
	check(game.world.rules.citations == 1, "visible bakery patrol witnesses public consumption")
	game.world.drink()
	check(game.world.rules.detained and game.world.stage == 15, "detention preserves chapter progress")
	game.world.rules.ramadan = false
	await approach(game.world.targets.done, Vector3(-1.5, 0.05, 0))
	game.interact()
	check(game.story_mode and game.world.stage == 16 and game.message_key == "line_done", "the reachable gate introduces the raid before committing to combat")
	for language in ["en", "fa"]:
		game.set_language(language, false)
		check(game.message_text == game.localize("line_done") and game.world.prompt().contains(game.localize("action_lane")), "gate briefing and armed departure switch to " + language)
	var old_chapter: Node3D = game.world
	game.interact()
	game.interact()
	check(game.world == old_chapter and old_chapter.leaving, "departure queues one transition without freeing the interacting player")
	game.pause_run()
	await settle()
	check(game.world == old_chapter and not old_chapter.leaving, "pausing before departure keeps the visit available")
	game.start_or_resume()
	# Trigger through the player's real physics input path, not a direct scene swap.
	Input.action_press("interact")
	await physics_frame
	await physics_frame
	Input.action_release("interact")
	await settle()
	check(not game.story_mode and game.active and game.relays.size() == 3, "the completed visit leads into the playable Kaveh Lane mission")
	check(game.player.gun_drawn and game.player.weapon.visible and game.player.ammo == game.player.MAGAZINE, "collecting the case supplies a visible loaded pistol")
	check(game.message_key == "lane_arrival", "arrival explains the mission and weapon controls")
	check(game.hud.hud_title.text == game.localize("hud_title") and game.hud.hud_place.text == game.localize("lane_night_place") and game.world.late_night, "night arrival replaces the family chapter title and preserves the time of day")
	var faces := {}
	var guards: Array = game.world.get_children().filter(func(child): return child is CharacterBody3D and child.get_script() == game.GuardScript)
	for guard in guards:
		for mesh in guard.visual.get_children():
			if mesh is MeshInstance3D and mesh.mesh is QuadMesh:
				var material: StandardMaterial3D = mesh.material_override
				if material.albedo_texture != null:
					faces[material.albedo_texture.resource_path] = true
	check(guards.size() == 3 and faces.size() == 3, "three combat guards retain distinct uploaded face textures")
	game.player.set_gun_drawn(false)
	check(game.player.empty_hands.visible and not game.player.weapon.visible, "holstering remains available after the story transition")
	game.story_mode = true
	game.restart_mission()
	check(game.world.stage == 0 and game.world.rules.citations == 0, "restart resets story and enforcement state")
	game.world.stage = 16
	await approach(game.world.targets.lane, Vector3(-1.5, 0.05, 0))
	game.interact()
	game.restart_mission()
	await settle()
	check(game.story_mode and game.world.stage == 0, "no queued departure survives a chapter restart")
	game.world.life.trip = "bakery"
	game.world.life.board()
	await settle()
	game.restart_mission()
	await settle()
	check(game.world.life.trip == "" and game.player.collision_layer == 2 and game.player.empty_hands.visible, "restart during driving restores player and chapter state")
	var walker: Node3D = game.world.person(Vector3(16, 0, -28), Color("527572"), 0)
	game.world.teleport(Vector3(16, 0.05, -30), Vector3(16, 1.5, -28))
	game.world.life.motion.walk(walker, [Vector3(16, 0, -32)])
	await create_timer(3).timeout
	check(walker.position.z > -29.5, "walking actors stop for a player blocking their route")
	game.world.teleport(Vector3(18, 0.05, -30), Vector3(16, 1.5, -28))
	await create_timer(3).timeout
	check(not game.world.life.motion.busy(walker), "walking resumes when the player clears the route")
	walker.queue_free()
	game.start_night()
	await settle()
	check(not game.story_mode and game.relays.size() == 3, "original night mission remains available")
	game.free()
	await process_frame
	print("RESULT: ", failures, " failure(s)")
	quit(0 if failures == 0 else 1)
