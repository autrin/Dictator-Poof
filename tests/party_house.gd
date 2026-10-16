extends SceneTree
## Integration check for the expanded north block and private party.

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
	await physics_frame
	await physics_frame
	await process_frame

func run() -> void:
	var game: Node3D = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await settle()
	game.set_language("en", false)
	game.sound_enabled = false
	var house: Node3D = game.world.party_house
	check(house != null and house.guests.size() == 6, "private party has six guests")
	check(game.chase_path(Vector3(0, 0, -22), Vector3(0, 0, -36)).size() > 2, "north passage connects the lane to the party house")
	check(game.navigation.is_point_solid(Vector2i(0, -41)), "courtyard pool blocks the walkable center")
	var host: Node3D = house.guests[0]
	check(host.has_node("Head") and host.has_node("Hair crown") and host.has_node("Left arm"), "guests use the articulated person model")
	check(house.guests[1].has_node("Wave") and house.guests[2].has_node("Ponytail"), "guests have distinct hair styles")
	game.start_or_resume()
	var wine_cup: Node3D = house.held_cups[3]
	var first_cup_position := wine_cup.position
	house._process(3.5)
	check(wine_cup.position.distance_to(first_cup_position) > 0.05, "guest raises a wine cup while dancing")
	game.player.position = host.global_position + Vector3(0, 0.05, 2.0)
	game.player.camera.look_at(host.global_position + Vector3(0, 1.1, 0))
	await settle()
	game.interact()
	check(game.message_text.contains("authorities") and game.interaction_prompt() == game.message_text, "host warns the player to keep the party private")
	game.set_language("fa", false)
	check(game.message_text.contains("حکومت") and house.sign.text == "خانهٔ مهتاب", "party conversation and house sign switch to Persian")
	game.set_language("en", false)
	var guard: CharacterBody3D
	for child in game.world.get_children():
		if child is CharacterBody3D:
			guard = child
			break
	guard.set_physics_process(false)
	guard.position = Vector3(0, 0.05, -33)
	house._process(0.1)
	check(house.raided and game.message_text.contains("Morality patrol"), "a patrol entering the private house interrupts the party")
	house._process(4.1)
	check(house.arrest_announced and game.message_text.contains("taking our friends") and house.guests[1].position.z > 0, "patrol raid leads to an attempted arrest at the entry")
	print("RESULT: ", failures, " failure(s)")
	quit(0 if failures == 0 else 1)
