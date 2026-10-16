extends SceneTree
## Integration checks against the actual level and physics, not a mocked game.
## Run after importing: godot --headless --path . --script tests/smoke.gd

var failures := 0
var game: Node3D

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

func position_player(at: Vector3, toward: Vector3) -> void:
	game.player.position = at
	game.player.velocity = Vector3.ZERO
	game.player.rotation = Vector3.ZERO
	game.player.camera.rotation = Vector3.ZERO
	game.player.camera.look_at(toward)
	await settle()

func run() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await settle()
	game.set_language("en", false)
	game.sound_enabled = false
	check(not game.active and game.relays.size() == 3, "title screen and three neighborhood power boxes load")
	check(game.world.neighbors.size() == 6 and not game.world.celebration, "six friends wait in the unlit courtyard")
	for i in range(6):
		check(game.world.neighbors[i].get_meta("line") == game.localize("friend_line_%d" % i), "friend %d has the assigned slogan" % (i + 1))
	for relay in game.relays:
		var approach: Vector3 = relay.node.position + Vector3(0, 0, 2)
		check(not game.chase_path(Vector3(0, 0, 18), approach).is_empty(), "power box approach is connected to the starting courtyard")
	check(game.navigation.is_point_solid(Vector2i(0, 0)), "navigation excludes central obstacle")
	check(game.chase_path(Vector3(0, 0, 6), Vector3(0, 0, -6)).size() > 2, "pursuers can route around central obstacle")
	game.start_or_resume()
	check(InputMap.has_action("holster") and game.player.weapon.visible, "H holsters a drawn gun")
	game.player.set_gun_drawn(false)
	var holstered_ammo: int = game.player.ammo
	game.player.shoot()
	check(game.player.empty_hands.visible and not game.player.weapon.visible and game.player.ammo == holstered_ammo, "holstered hands show and cannot fire")
	game.player.set_gun_drawn(true)
	check(game.player.weapon.visible and not game.player.empty_hands.visible, "drawing restores the gun")
	var guards: Array[Node] = []
	for child in game.world.get_children():
		if child is CharacterBody3D:
			guards.append(child)
			child.set_physics_process(false)
	check(guards.size() == 3, "three patrol guards spawn")
	var initial_z: float = game.player.position.z
	Input.action_press("forward")
	# Count simulated movement steps: font/texture startup can consume a
	# wall-clock timer before a quarter-second of physics has actually run.
	for tick in range(ceili(Engine.physics_ticks_per_second * 0.25) + 1):
		await physics_frame
	Input.action_release("forward")
	check(game.player.position.z < initial_z - 0.7, "WASD moves the player through actual physics")
	var friend: Node3D = game.world.neighbors[0]
	await position_player(friend.global_position + Vector3(0, 0.05, -2), friend.global_position + Vector3(0, 1.1, 0))
	game.interact()
	check(game.message_text == "Ava: Long live the Shah" and game.relays_online == 0, "talking to a friend shows their English slogan without advancing power objectives")
	game.set_language("fa", false)
	check(game.message_text == "آوا: جاوید شاه" and game.world.neighbors[0].get_meta("line") == "جاوید شاه", "switching during dialogue immediately shows the Persian line")
	game.set_language("en", false)
	check(game.message_text == "Ava: Long live the Shah" and game.world.neighbors[0].get_meta("line") == "Long live the Shah", "switching back immediately restores English")
	game.pause_run()
	var health: int = game.player.health
	game.player.take_damage(20)
	check(game.player.health == health, "pause prevents damage")
	game.start_or_resume()
	game.player.take_damage(20)
	check(game.player.health == 80, "active combat reduces health")
	Input.action_press("crouch")
	await create_timer(0.2).timeout
	check(game.player.camera.position.y < 1.0, "crouch lowers viewpoint behind cover")
	Input.action_release("crouch")
	await create_timer(0.2).timeout
	# A central pillar must block both guard sight and player shots.
	var guard = guards[0]
	guard.position = Vector3(0, 0.05, -4)
	await position_player(Vector3(0, 0.05, 4), Vector3(0, 1.2, -4))
	check(not guard.can_see_player(), "solid geometry blocks enemy line of sight")
	game.player.shoot()
	check(guard.health == 100, "player cannot shoot through solid cover")
	# Move to a clear lane and exercise raycast damage, death, and ammo use.
	guard.position = Vector3(10, 0.05, 10)
	await position_player(Vector3(10, 0.05, 14), Vector3(10, 1.2, 10))
	check(guard.can_see_player(), "clear lane restores line of sight")
	for i in range(3):
		game.player.fire_left = 0.0
		game.player.shoot()
	check(not guard.alive and game.guards_defeated == 1, "three valid hits defeat guard exactly once")
	check(game.player.ammo == 8, "blocked and successful shots each consume ammunition")
	guard.take_damage(100, guard.position)
	check(game.guards_defeated == 1, "dead guards cannot increase defeat count")
	game.player.reload()
	await create_timer(1.4).timeout
	check(game.player.ammo == 12, "reload completes and refills the magazine")
	# Defeat the other guards so mission interaction checks are deterministic.
	for other in guards:
		other.set_physics_process(false)
	await position_player(game.broadcast.position + Vector3(0, 0.05, 2), game.broadcast.position + Vector3(0, 1.1, 0))
	game.interact()
	check(not game.ended and not game.world.celebration, "gathering cannot start before power is restored")
	for relay in game.relays:
		await position_player(relay.node.position + Vector3(0, 0.05, 2), relay.node.position + Vector3(0, 1.1, 0))
		var count: int = game.relays_online
		game.interact()
		game.interact()
		check(game.relays_online == count + 1, "relay interaction is reachable and cannot be counted twice")
		check(game.world.district_lights[count].light_energy > 1.0, "restoring power visibly lights a neighborhood district")
	check(game.player.health == 100, "relay healing respects the health cap")
	await position_player(game.broadcast.position + Vector3(0, 0.05, 2), game.broadcast.position + Vector3(0, 1.1, 0))
	game.interact()
	check(game.ended and game.victory and not game.active and game.hud.heading.text == game.localize("won_heading"), "restored power and return to friends unlock victory")
	check(game.world.celebration and game.world.gathering_light.light_energy > 2.0, "victory lights the courtyard gathering")
	for other in guards:
		check(not other.visible and other.collision_layer == 0, "patrols leave the celebration")
	game.start_or_resume()
	check(game.active and game.victory and not game.player.weapon.visible and game.player.empty_hands.visible, "join friends allows peaceful exploration with visible hands")
	await position_player(friend.global_position + Vector3(0, 0.05, -2), friend.global_position + Vector3(0, 1.1, 0))
	game.interact()
	check(game.message_text == "Ava: Long live the Shah", "friend keeps their slogan during the celebration")
	var celebration_ammo: int = game.player.ammo
	game.player.shoot()
	game.player.take_damage(100)
	check(game.player.ammo == celebration_ammo and game.player.health == 100, "celebration disables combat and damage")
	var pause_event := InputEventAction.new()
	pause_event.action = "pause"
	pause_event.pressed = true
	game._unhandled_input(pause_event)
	check(not game.active and game.hud.menu.visible, "celebration exploration can be paused")
	game.start_or_resume()
	game.restart_mission()
	check(game.active and game.relays_online == 0 and game.player.health == 100, "replay resets objectives and player state")
	check(not game.victory and not game.world.celebration and game.player.weapon.visible, "replay resets celebration and restores combat")
	game.player.take_damage(100)
	check(game.ended and game.hud.heading.text == "TRY AGAIN", "zero health shows a restart screen")
	game.blood_enabled = false
	game.impact(Vector3.ZERO, true)
	var last_effect = game.effects.get_child(game.effects.get_child_count() - 1)
	check(last_effect.material_override.albedo_color == Color("efce91"), "blood toggle substitutes neutral hit particles")
	print("RESULT: %d failure(s)" % failures)
	game.queue_free()
	await process_frame
	quit(1 if failures > 0 else 0)
