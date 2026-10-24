extends Node3D
## A shared café for the daytime chapter and the original night mission.
const Props := preload("res://scripts/domestic_props.gd")
const Person := preload("res://scripts/person_visual.gd")
const BOOKS := [
	["Shahnameh", "شاهنامه", "Ferdowsi", "فردوسی", "Kings, heroes, and the cost of power. An epic that helped carry Persian through a thousand years.", "شاهان، پهلوانان و بهای قدرت؛ حماسه‌ای که در زنده ماندن زبان فارسی نقش بزرگی داشته است."],
	["Divan of Hafez", "دیوان حافظ", "Hafez", "حافظ", "Ghazals of love, hypocrisy, longing, and the pleasure of being alive.", "غزل‌هایی از عشق، ریا، اشتیاق و لذت زندگی."],
	["Golestan", "گلستان", "Saadi", "سعدی", "Short tales and poetry about people: their kindness, vanity, wisdom, and contradictions.", "حکایت‌ها و شعرهایی دربارهٔ مهربانی، غرور، خرد و تناقض‌های انسان."],
	["Rubaiyat", "رباعیات", "Omar Khayyam", "عمر خیام", "Quatrains questioning certainty and returning our attention to this brief life.", "رباعی‌هایی که یقین را به پرسش می‌کشند و به کوتاهی زندگی نگاه می‌کنند."]
]
var game: Node3D
var rules: RefCounted
var counter: Node3D
var shelves: Array[Node3D] = []
var guests: Array[Node3D] = []
var cups: Array[Node3D] = []
var signs: Array[Label3D] = []
var orders := 0
var elapsed := 0.0
var was_open := false
var player_seat: Node3D
var player_cup: Node3D
var seated := false
var coffee_ready := false
var exit_position := Vector3.ZERO

func _ready() -> void:
	PoofShapes.box(self, Vector3(0, 0.01, 0), Vector3(6, 0.02, 5.5), Color("c4b393"))
	PoofShapes.box(self, Vector3(0, 1.4, -2.4), Vector3(6, 2.8, 0.18), Color("49716b"), true)
	PoofShapes.box(self, Vector3(0, 2.8, -0.4), Vector3(6.2, 0.12, 4.3), Color("c8b187"))
	for x in [-2.85, 2.85]:
		PoofShapes.box(self, Vector3(x, 1.35, 1.5), Vector3(0.1, 2.7, 0.1), Props.WOOD, true)
	counter = Node3D.new()
	counter.position = Vector3(1.7, 0, -1.5)
	add_child(counter)
	PoofShapes.box(counter, Vector3(0, 0.51, 0), Vector3(1.4, 1.02, 0.75), Props.WOOD, true)
	PoofShapes.box(counter, Vector3(0, 1.06, 0), Vector3(1.5, 0.07, 0.85), Props.CREAM)
	PoofShapes.box(counter, Vector3(0.2, 1.28, -0.12), Vector3(0.5, 0.38, 0.4), Color("454c50"))
	Props.cup(counter, Vector3(-0.4, 1.11, 0.05))
	for i in range(BOOKS.size()):
		var book := Node3D.new()
		book.position = Vector3(-2.35 + i * 0.8, 0, -2.12)
		add_child(book)
		shelves.append(book)
		PoofShapes.box(book, Vector3(0, 1.14, 0), Vector3(0.56, 0.78, 0.09), [Color("843e42"), Color("264d58"), Color("947047"), Color("465c45")][i])
		PoofShapes.box(book, Vector3(0.01, 1.14, 0.016), Vector3(0.5, 0.72, 0.08), Props.CREAM)
		PoofShapes.box(book, Vector3(0, 1.14, 0.068), Vector3(0.56, 0.78, 0.015), [Color("843e42"), Color("264d58"), Color("947047"), Color("465c45")][i])
		var label := PoofShapes.label(book, Vector3(0, 1.16, 0.081), "", Color("f0d799"), 28)
		label.font = preload("res://assets/fonts/vazirmatn/Vazirmatn.ttf")
		label.pixel_size = 0.003
		label.outline_size = 0
		signs.append(label)
	PoofShapes.box(self, Vector3(-1.15, 0.72, -2.06), Vector3(3.7, 0.08, 0.4), Props.WOOD, true)
	for i in range(2):
		var at := Vector3(-1.7 + i * 3.2, 0, 1.6)
		Props.table(self, at, Vector2(1.05, 0.85))
		for side in [-1, 1]:
			var seat := at + Vector3(0, 0, side * 0.9)
			Props.chair(self, seat, 0 if side > 0 else PI)
			var guest := Node3D.new()
			add_child(guest)
			guest.position = seat
			guest.rotation.y = 0 if side > 0 else PI
			Person.build(guest, Color("a76853") if i == 0 else Color("426c74"), Color("c99778"), Color("342b2a"), i * 2 + (1 if side > 0 else 0))
			Person.sit(guest)
			guests.append(guest)
			cups.append(Props.cup(self, at + Vector3(0.18, 0.8, side * 0.23)))
	Props.table(self, Vector3(0, 0, 3), Vector2(0.75, 0.7))
	player_seat = Props.chair(self, Vector3(0, 0, 3.85))
	player_cup = Props.cup(self, Vector3(0, 0.8, 3))
	player_cup.hide()
	for at in [Vector3(-1.8, 2.55, 0), Vector3(1.8, 2.55, 0)]:
		Props.round_shape(self, at, 0.16, 0.05, Color("ba8b50"))
		var lamp := OmniLight3D.new()
		lamp.position = at
		lamp.light_color = Color("ffe3bb")
		lamp.light_energy = 0.5
		lamp.omni_range = 5
		add_child(lamp)
	var sign := PoofShapes.label(self, Vector3(0, 2.38, -2.28), "", Props.CREAM, 36)
	sign.font = preload("res://assets/fonts/vazirmatn/Vazirmatn.ttf")
	sign.pixel_size = 0.006
	signs.append(sign)
	refresh_language()
	refresh_service()

func is_open() -> bool:
	return rules == null or rules.public_service_allowed()

func refresh_service() -> void:
	was_open = is_open()
	for i in range(guests.size()):
		guests[i].visible = was_open
		guests[i].get_node("Body collider").collision_layer = 1 if was_open else 0
		cups[i].visible = was_open
	if not was_open:
		coffee_ready = false
		player_cup.hide()
	refresh_language()

func refresh_language() -> void:
	var offset := 1 if game.language == "fa" else 0
	for i in range(BOOKS.size()):
		signs[i].text = BOOKS[i][offset].replace(" of ", "\nof ") + "\n\n" + BOOKS[i][2 + offset]
	signs[4].text = game.localize("cafe_open" if is_open() else "cafe_closed")

func focused_target() -> Node3D:
	var best: Node3D
	var best_score := 2.0
	var candidates: Array[Node3D] = [counter, player_seat]
	candidates.append_array(shelves)
	for guest in guests:
		if guest.visible:
			candidates.append(guest)
	for candidate in candidates:
		if not game.near_and_visible(candidate):
			continue
		var direction: Vector3 = candidate.global_position + Vector3(0, 1.1, 0) - game.player.camera.global_position
		var score: float = 1.0 - direction.normalized().dot(-game.player.camera.global_basis.z) + direction.length() * 0.003
		if score < best_score:
			best_score = score
			best = candidate
	return best

func prompt() -> String:
	if seated:
		return game.localize("cafe_stand")
	var focus := focused_target()
	if focus == null:
		return ""
	if focus == player_seat:
		return game.localize("cafe_sit")
	if shelves.has(focus):
		return game.localize("book_read")
	if focus == counter:
		return game.localize("coffee_order" if is_open() else "coffee_closed")
	return game.localize("cafe_talk")

func interact() -> bool:
	if seated:
		stand()
		return true
	var focus := focused_target()
	if focus == null:
		return false
	if focus == player_seat:
		exit_position = game.player.global_position
		seated = true
		game.player.global_position = player_seat.global_position
		game.player.velocity = Vector3.ZERO
		game.player.camera.position.y = 1.16
		game.player.rotation.y = global_rotation.y
		game.player.camera.rotation.x = -0.08
		if coffee_ready:
			player_cup.show()
		game.notify("cafe_seated", 7)
	elif shelves.has(focus):
		game.notify("book_%d" % shelves.find(focus), 12)
	elif focus == counter:
		if is_open():
			orders += 1
			coffee_ready = true
			player_cup.show()
			game.notify("coffee_served", 7)
			game.play_tone(520, 0.13, 0.08)
		else:
			game.notify("coffee_refused", 8)
	else:
		game.notify("cafe_chat_%d" % (guests.find(focus) % 2), 8)
	return true

func stand() -> void:
	seated = false
	game.player.global_position = exit_position
	game.player.camera.position.y = 1.62
	game.player.velocity = Vector3.ZERO

func _process(delta: float) -> void:
	if not game.active:
		return
	if was_open != is_open():
		refresh_service()
	elapsed += delta
	for i in range(guests.size()):
		guests[i].rotation.y = (PI if i % 2 == 0 else 0.0) + sin(elapsed * 0.7 + i) * 0.08
		var forearm := guests[i].get_node("Right arm/Forearm") as Node3D
		forearm.rotation.x = 0.3 + maxf(0, sin(elapsed * 0.7 + i)) * 0.45
