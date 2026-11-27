extends RefCounted
## Store gameplay values and transforms. Scene nodes and resources stay in the level.
const Visit := preload("res://scripts/visit_state.gd")
const GUARD_FIELDS := ["transform", "health", "alive", "attack_left", "elapsed", "chase_memory", "last_seen", "velocity"]
const PLAYER_FIELDS := ["transform", "velocity", "health", "ammo", "reload_left", "fire_left", "collision_layer"]
const CAFE_FIELDS := ["orders", "coffee_ready", "seated", "exit_position"]

static func fields(object: Object, names: Array) -> Dictionary:
	var data := {}
	for key in names:
		data[key] = object.get(key)
	return data

static func apply_fields(object: Object, data: Dictionary) -> void:
	for key in data:
		object.set(key, data[key])

static func capture(game: Node) -> Dictionary:
	var p: CharacterBody3D = game.player
	var data := {"story": game.story_mode, "late": game.late_night, "victory": game.victory,
		"player": fields(p, PLAYER_FIELDS), "camera": p.camera.transform, "drawn": p.gun_drawn,
		"cafe": fields(game.world.cafe, CAFE_FIELDS), "time": game.run_time,
		"message": game.message_key, "message_left": game.notification_left,
		"album": game.keepsakes.duplicate()}
	if game.story_mode:
		data.visit = Visit.capture(game.world)
	else:
		data.lane = capture_lane(game)
	return data

static func restore(game: Node, data: Dictionary) -> void:
	# Caller has just built the correct chapter and its HUD.
	if game.story_mode:
		Visit.restore(game.world, data.visit)
	else:
		restore_lane(game, data.lane)
	game.keepsakes.assign(data.album)
	game.run_time = data.time
	game.victory = data.victory
	game.ended = data.victory
	if game.victory:
		game.world.celebrate()
	apply_fields(game.world.cafe, data.cafe)
	game.world.cafe.player_cup.visible = data.cafe.coffee_ready
	apply_fields(game.player, data.player)
	game.player.camera.transform = data.camera
	game.player.set_gun_drawn(data.drawn)
	game.notify(data.message, data.message_left)
	game.hud.apply_language()

static func capture_lane(game: Node) -> Dictionary:
	var lights := []
	for relay in game.relays:
		lights.append(relay.online)
	var guards := {}
	for child in game.world.get_children():
		if child is CharacterBody3D:
			guards[child.guard_index] = fields(child, GUARD_FIELDS)
	var park: Node = game.world.park_encounter
	var party: Node = game.world.party_house
	var guests := []
	for guest in party.guests:
		guests.append(guest.transform)
	return {"lights": lights, "guards": guards, "defeated": game.guards_defeated,
		"park": fields(park, ["started", "completed", "elapsed", "shown_beat"]),
		"party": fields(party, ["elapsed", "raided", "raid_elapsed", "arrest_announced"]), "guests": guests}

static func restore_lane(game: Node, data: Dictionary) -> void:
	for i in range(data.lights.size()):
		if data.lights[i]:
			game.light_relay(i)
	for child in game.world.get_children():
		if child is CharacterBody3D:
			apply_fields(child, data.guards[child.guard_index])
			if not child.alive:
				child.collision_layer = 0
				child.collision_mask = 0
				child.visual.rotation.x = -PI / 2
				child.visual.position.y = 0.22
	game.guards_defeated = data.defeated
	var park: Node = game.world.park_encounter
	apply_fields(park, data.park)
	if park.started:
		park.pose_encounter()
	var party: Node = game.world.party_house
	if data.party.raided:
		party.start_raid()
	apply_fields(party, data.party)
	for i in range(party.guests.size()):
		party.guests[i].transform = data.guests[i]
