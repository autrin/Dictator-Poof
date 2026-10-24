extends SceneTree
var failures := 0
var game: Node3D
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
	game.world.teleport(Vector3(-6.5, 0.05, -14), Vector3(-7.2, 1.5, -16.7))
	await settle()
	game.world.drink()
	check(game.world.rules.citations == 0, "Nowruz drinking does not trigger Ramadan enforcement")
	game.world.rules.ramadan = true
	game.world.drink()
	check(game.world.rules.citations == 1, "visible bakery patrol witnesses public consumption")
	game.world.drink()
	check(game.world.rules.detained and game.world.stage == 15, "detention preserves chapter progress")
	game.restart_mission()
	check(game.world.stage == 0 and game.world.rules.citations == 0, "restart resets story and enforcement state")
	game.start_night()
	await settle()
	check(not game.story_mode and game.relays.size() == 3, "original night mission remains available")
	game.free()
	await process_frame
	print("RESULT: ", failures, " failure(s)")
	quit(0 if failures == 0 else 1)
