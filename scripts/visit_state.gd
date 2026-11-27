extends RefCounted
## Stable actor roles let an interrupted walk or drive resume in a newly built scene.
const Person := preload("res://scripts/person_visual.gd")
const LIFE := ["trip", "trip_phase", "road", "patrol_phase", "elapsed", "eating", "cooking_left", "placing_time"]
const HAND := ["hands", "deck", "scores", "trick", "turn", "leader", "trump"]

static func actors(world: Node) -> Array:
	return world.family + world.life.officers + [world.life.cook]

static func capture(world: Node) -> Dictionary:
	var life: Node = world.life
	var data := {"stage": world.stage, "minute": world.rules.minute, "citations": world.rules.citations,
		"detained": world.rules.detained, "ramadan": world.rules.ramadan, "car": world.car.transform,
		"van": life.van.transform, "actors": [], "life": {}, "blinds": world.blinds.visible,
		"scarf": world.scarf.visible, "speaker": world.speaker.visible, "serving": world.serving.visible,
		"selection": world.bakery.selection.duplicate(), "packing": world.bakery.packing,
		"sealed": world.bakery.sealed, "on_table": world.pastry_box.visible and not world.pastry_lid.visible}
	for key in LIFE:
		data.life[key] = life.get(key)
	for actor in actors(world):
		var state := {"pose": actor.transform, "seated": actor.get_parent() == world.car,
			"visible": actor.visible, "layer": actor.get_node("Body collider").collision_layer}
		if life.motion.busy(actor):
			state.route = life.motion.routes[actor].duplicate(true)
			state.walked = life.motion.walked[actor]
		data.actors.append(state)
	if is_instance_valid(world.cards) and not world.cards.is_queued_for_deletion():
		data.hand = {}
		for key in HAND:
			data.hand[key] = world.cards.rules.get(key)
	return data

static func restore(world: Node, data: Dictionary) -> void:
	var life: Node = world.life
	# Rebuild the physical gift using the same stock, wrapping and placement as normal play.
	if data.sealed:
		world.bakery.pack_assortment(data.selection)
		if data.on_table:
			world.set_out_pastries()
	elif data.packing:
		world.bakery.open()
		for kind in data.selection:
			world.bakery.add_piece(kind)
	world.stage = data.stage
	world.rules.minute = data.minute
	world.rules.ramadan = data.ramadan
	world.rules.citations = data.citations
	world.rules.detained = data.detained
	world.car.transform = data.car
	life.van.transform = data.van
	for key in LIFE:
		life.set(key, data.life[key])
	var cast := actors(world)
	for i in range(cast.size()):
		var actor: Node3D = cast[i]
		var state: Dictionary = data.actors[i]
		if state.seated:
			actor.reparent(world.car, false)
			Person.sit(actor)
		actor.transform = state.pose
		actor.visible = state.visible
		actor.get_node("Body collider").collision_layer = state.layer
		if state.has("route"):
			life.motion.routes[actor] = state.route
			life.motion.walked[actor] = state.walked
	world.blinds.visible = data.blinds
	world.scarf.visible = data.scarf
	world.speaker.visible = data.speaker
	world.serving.visible = data.serving
	if data.has("hand"):
		world.open_cards()
		for key in HAND:
			world.cards.rules.set(key, data.hand[key])
	world.update_time()
	world.apply_language()
