extends SceneTree
## Focused check for the park encounter trigger and its visible progression.

var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if condition:
		print("PASS: ", message)
	else:
		failures += 1
		push_error("FAIL: " + message)

func run() -> void:
	var game: Node3D = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await physics_frame
	await process_frame
	game.sound_enabled = false
	game.start_or_resume()
	var park: Node3D = game.world.park_encounter
	check(park != null and not park.started and park.civilians.size() == 4 and park.officers.size() == 4, "park scene starts with four walking friends and four officers")
	game.player.position = park.global_position + Vector3(0, 0.05, 0)
	await process_frame
	await process_frame
	check(park.started, "approaching the park triggers the encounter")
	park._process(15.5)
	check(park.officers[0].visible and park.van.position.z < 4.0, "officers emerge from the arriving van")
	check(park.civilians[1].rotation.z < -0.1 and park.officers[1].get_node("Left arm").position.y > 1.4, "officer grabs toward a woman's hair while she recoils")
	check(park.civilians[0].rotation.z > 0.1 and park.officers[0].get_node("Left arm").position.y > 1.0, "man recoils from the officer's raised arm")
	park._process(8.0)
	check(park.completed and game.message_text.contains("ون"), "attempted forced loading into the van completes the scene")
	print("RESULT: ", failures, " failure(s)")
	quit(0 if failures == 0 else 1)
