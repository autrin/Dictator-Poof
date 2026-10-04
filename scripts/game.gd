extends Node3D
## Composition root: builds the level, owns mission state, coordinates the GUI.

const PlayerScript := preload("res://scripts/player.gd")
const GuardScript := preload("res://scripts/guard.gd")
const WorldScript := preload("res://scripts/world.gd")
const HudScript := preload("res://scripts/hud.gd")

var player: CharacterBody3D
var world: Node3D
var hud: CanvasLayer
var broadcast: Node3D
var broadcast_screen: MeshInstance3D
var relays: Array[Dictionary] = []
var relays_online := 0
var guards_defeated := 0
var run_time := 0.0
var active := false
var ended := false
var victory := false
var beat_left := 0.0
var beat := 0
var started := false
var blood_enabled := true
var sound_enabled := true
var sensitivity := 0.002
var hit_marker := 0.0
var hurt_flash := 0.0
var message_text := ""
var notification_left := 0.0
var effects: Node3D
var sound_cache: Dictionary = {}
var navigation := AStarGrid2D.new()

func _ready() -> void:
	load_settings()
	configure_input()
	build_run()
	hud = HudScript.new()
	hud.game = self
	add_child(hud)

func configure_input() -> void:
	var keys := {"forward": KEY_W, "back": KEY_S, "left": KEY_A, "right": KEY_D,
		"jump": KEY_SPACE, "sprint": KEY_SHIFT, "reload": KEY_R, "interact": KEY_E,
		"pause": KEY_ESCAPE, "crouch": KEY_CTRL}
	for action: String in keys:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
			var event := InputEventKey.new()
			event.physical_keycode = keys[action]
			InputMap.action_add_event(action, event)
	if not InputMap.has_action("fire"):
		InputMap.add_action("fire")
		var click := InputEventMouseButton.new()
		click.button_index = MOUSE_BUTTON_LEFT
		InputMap.action_add_event("fire", click)

func build_run() -> void:
	if is_instance_valid(world):
		world.free()
	if is_instance_valid(player):
		player.free()
	if is_instance_valid(effects):
		effects.free()
	relays.clear()
	relays_online = 0
	guards_defeated = 0
	run_time = 0.0
	hit_marker = 0.0
	hurt_flash = 0.0
	notification_left = 0.0
	ended = false
	victory = false
	beat_left = 0.0
	beat = 0
	world = WorldScript.new()
	world.game = self
	add_child(world)
	build_navigation()
	effects = Node3D.new()
	add_child(effects)
	player = PlayerScript.new()
	player.game = self
	player.position = Vector3(0, 0.05, 18)
	add_child(player)
	var spawns := [Vector3(-10, 0.05, 0), Vector3(9, 0.05, -10), Vector3(-4, 0.05, -19)]
	for i in range(spawns.size()):
		var guard := GuardScript.new()
		guard.game = self
		guard.position = spawns[i]
		guard.guard_index = i
		world.add_child(guard)

func build_navigation() -> void:
	# The neighborhood is flat; use the actual static geometry as blocked cells.
	navigation.region = Rect2i(-15, -23, 31, 47)
	navigation.cell_size = Vector2.ONE
	navigation.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	navigation.update()
	for geometry in get_tree().get_nodes_in_group("level_geometry"):
		var size: Vector3 = geometry.mesh.size
		var at: Vector3 = geometry.global_position
		if at.y + size.y / 2.0 < 0.4 or at.y - size.y / 2.0 > 2.0:
			continue
		for x in range(-15, 16):
			for z in range(-23, 24):
				if absf(x - at.x) <= size.x / 2.0 + 0.38 and absf(z - at.z) <= size.z / 2.0 + 0.38:
					navigation.set_point_solid(Vector2i(x, z))

func chase_path(from: Vector3, to: Vector3) -> PackedVector2Array:
	var start := Vector2i(clampi(roundi(from.x), -15, 15), clampi(roundi(from.z), -23, 23))
	var goal := Vector2i(clampi(roundi(to.x), -15, 15), clampi(roundi(to.z), -23, 23))
	if navigation.is_point_solid(start) or navigation.is_point_solid(goal):
		return PackedVector2Array()
	return navigation.get_point_path(start, goal)

func start_or_resume() -> void:
	# Button signals run outside the physics step, so rebuilding here is safe.
	if ended and not victory:
		build_run()
	started = true
	active = true
	hud.hide_menu()
	player.weapon.visible = not victory

func restart_mission() -> void:
	build_run()
	start_or_resume()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and not event.is_echo() and started and (not ended or victory):
		if active:
			pause_run()
		else:
			start_or_resume()
		get_viewport().set_input_as_handled()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and active and is_instance_valid(hud):
		pause_run()

func pause_run() -> void:
	active = false
	hud.show_menu("pause")

func _process(delta: float) -> void:
	if active:
		run_time += delta
		hit_marker = maxf(0.0, hit_marker - delta)
		hurt_flash = maxf(0.0, hurt_flash - delta)
		notification_left = maxf(0.0, notification_left - delta)
		if victory:
			beat_left -= delta
			if beat_left <= 0.0:
				beat_left = 0.32
				# An original placeholder melody for the gathering.
				var notes := [293.66, 349.23, 392.0, 440.0, 392.0, 349.23, 293.66, 261.63]
				play_tone(notes[beat % notes.size()], 0.24, 0.10)
				if beat % 2 == 0:
					play_tone(73.42, 0.09, 0.12)
				beat += 1
	# HUD queries are performed in the physics tick, where raycasts are safe.

func _physics_process(_delta: float) -> void:
	if is_instance_valid(hud):
		hud.update()

func near_and_visible(target: Node3D) -> bool:
	var point := target.global_position + Vector3(0, 1.1, 0)
	var direction: Vector3 = point - player.camera.global_position
	if direction.length() > 3.0:
		return false
	if direction.normalized().dot(-player.camera.global_basis.z) < 0.55:
		return false
	var query := PhysicsRayQueryParameters3D.create(player.camera.global_position, point, 1, [player.get_rid()])
	var result := get_world_3d().direct_space_state.intersect_ray(query)
	return result.is_empty() or target.is_ancestor_of(result.collider)

func interaction_prompt() -> String:
	if notification_left > 0.0:
		return message_text
	for friend in world.neighbors:
		if near_and_visible(friend):
			return "[E]  Speak with a friend"
	if victory:
		return "The lane is yours. Stay a while."
	for relay in relays:
		if not relay.online and near_and_visible(relay.node):
			return "[E]  Restore neighborhood power  /  +25 health"
	if near_and_visible(broadcast):
		return "[E]  Bring the gathering to life" if relays_online == 3 else "Restore the three power boxes, then come back here"
	return message_text if notification_left > 0.0 else ""

func interact() -> void:
	if not active or (ended and not victory):
		return
	for friend in world.neighbors:
		if near_and_visible(friend):
			var words: String = "بیا کنار ما. امشب زنده‌ایم!" if victory else str(friend.get_meta("line"))
			message_text = "%s: %s" % [friend.get_meta("name"), words]
			notification_left = 5.0
			return
	if victory:
		return
	for relay in relays:
		if not relay.online and near_and_visible(relay.node):
			relay.online = true
			relays_online += 1
			relay.screen.material_override = PoofShapes.material(Color("81dbc8"), 1.0)
			relay.label.text = "POWER RESTORED"
			relay.label.modulate = Color("81dbc8")
			player.health = mini(100, player.health + 25)
			world.restore_district(relays.find(relay))
			message_text = ["A window lights up. Someone is still awake.", "More light. The lane feels less alone.", "The power is back. Return to your friends by the rug."][relays_online - 1]
			notification_left = 4.0
			play_tone(640.0, 0.2, 0.18)
			if relays_online == 3:
				broadcast_screen.material_override = PoofShapes.material(Color("81dbc8"), 1.0)
			return
	if relays_online == 3 and near_and_visible(broadcast):
		finish(true)

func finish(won: bool) -> void:
	if ended:
		return
	active = false
	ended = true
	victory = won
	if won:
		world.celebrate()
		player.weapon.hide()
	hud.show_menu("won" if won else "lost")

func tracer(from: Vector3, to: Vector3, color: Color) -> void:
	var length := from.distance_to(to)
	if length < 0.01:
		return
	var streak := PoofShapes.box(effects, (from + to) / 2.0, Vector3(0.018, 0.018, length), color, false, 1.0)
	streak.look_at(to, Vector3.UP if absf((to - from).normalized().y) < 0.99 else Vector3.RIGHT)
	var tween := streak.create_tween()
	tween.tween_interval(0.045)
	tween.tween_callback(streak.queue_free)

func impact(point: Vector3, organic: bool) -> void:
	var blood := organic and blood_enabled
	var color := Color("983d48") if blood else Color("efce91")
	for i in range(5 if blood else 3):
		var particle := PoofShapes.box(effects, point, Vector3.ONE * (0.045 if blood else 0.025), color)
		var target := point + Vector3(randf_range(-0.32, 0.32), randf_range(-0.25, 0.3), randf_range(-0.32, 0.32))
		var tween := particle.create_tween()
		tween.tween_property(particle, "position", target, 0.18)
		tween.parallel().tween_property(particle, "scale", Vector3.ONE * 0.1, 0.22)
		tween.tween_callback(particle.queue_free)

func play_tone(frequency: float, duration: float, volume: float) -> void:
	if not sound_enabled:
		return
	var key := "%s:%s" % [frequency, duration]
	if not sound_cache.has(key):
		var sample := AudioStreamWAV.new()
		sample.format = AudioStreamWAV.FORMAT_16_BITS
		sample.mix_rate = 22050
		var count := int(duration * sample.mix_rate)
		var data := PackedByteArray()
		data.resize(count * 2)
		for i in range(count):
			var t := float(i) / sample.mix_rate
			var envelope := pow(1.0 - float(i) / count, 2.0)
			var wave := sin(t * TAU * frequency) * envelope
			data.encode_s16(i * 2, int(wave * 16000.0))
		sample.data = data
		sound_cache[key] = sample
	var audio_player := AudioStreamPlayer.new()
	audio_player.stream = sound_cache[key]
	audio_player.volume_db = linear_to_db(volume)
	effects.add_child(audio_player)
	audio_player.finished.connect(audio_player.queue_free)
	audio_player.play()

func load_settings() -> void:
	var config := ConfigFile.new()
	if config.load("user://settings.cfg") == OK:
		blood_enabled = bool(config.get_value("preferences", "blood", true))
		sound_enabled = bool(config.get_value("preferences", "sound", true))
		sensitivity = clampf(float(config.get_value("preferences", "sensitivity", 0.002)), 0.0005, 0.006)

func save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("preferences", "blood", blood_enabled)
	config.set_value("preferences", "sound", sound_enabled)
	config.set_value("preferences", "sensitivity", sensitivity)
	var result := config.save("user://settings.cfg")
	if result != OK:
		push_warning("Could not save preferences: %s" % error_string(result))
