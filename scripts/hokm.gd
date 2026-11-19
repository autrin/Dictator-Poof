extends Control
signal finished
const Rules := preload("res://scripts/hokm_rules.gd")
const Card := preload("res://scripts/hokm_card.gd")
const Cloth := preload("res://scripts/hokm_cloth.gd")
const BOARD_SIZE := Vector2(1280, 720)
const SEATS := [Vector2(788, 365), Vector2(937, 282), Vector2(788, 192), Vector2(639, 282)]
const NAMEPLATES := [Vector2(788, 446), Vector2(1095, 282), Vector2(788, 100), Vector2(482, 282)]
const PAPER := Color("fff1d4")
const INK := Color("283e3c")
const RUST := Color("904d3f")
const GOLD := Color("efc991")
const TURN_DELAY := 0.58
var game: Node3D
var rules := Rules.new()
var board := Cloth.new()
var hand := Control.new()
var trick := Control.new()
var actions := HBoxContainer.new()
var seats: Array[Label] = []
var scores: Array[Label] = []
var tallies: Array[HBoxContainer] = []
var heading: Label
var place: Label
var trump: Label
var help: Label
var status: Label
var next_button: Button
var wait_left := TURN_DELAY
var sliding_card: Control
var slide_to := Vector2.ZERO

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var backdrop := ColorRect.new()
	backdrop.color = Color("172e2b")
	add_child(backdrop)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(board)
	board.size = BOARD_SIZE
	resized.connect(fit_table)
	fit_table()
	place = label_at(Rect2(65, 76, 212, 31), 16, RUST)
	heading = label_at(Rect2(65, 104, 212, 62), 44, INK)
	for team in range(2):
		var y := 186 + team * 57
		scores.append(label_at(Rect2(65, y, 212, 30), 19, INK))
		var row := HBoxContainer.new()
		board.add_child(row)
		row.position = Vector2(109, y + 33)
		row.add_theme_constant_override("separation", 6)
		tallies.append(row)
		for i in range(7):
			var mark := ColorRect.new()
			mark.custom_minimum_size = Vector2(12, 5)
			row.add_child(mark)
	trump = label_at(Rect2(63, 317, 216, 46), 23, RUST)
	help = label_at(Rect2(68, 365, 206, 134), 17, INK)
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	for center: Vector2 in NAMEPLATES:
		seats.append(label_at(Rect2(center - Vector2(98, 19), Vector2(196, 38)), 23, PAPER))
	for layer in [trick, hand]:
		board.add_child(layer)
		layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	status = label_at(Rect2(330, 475, 916, 44), 23, GOLD)
	board.add_child(actions)
	actions.add_theme_constant_override("separation", 12)
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	for suit in range(4):
		var button := table_button(Card.SUITS[suit])
		button.custom_minimum_size = Vector2(69, 59)
		button.add_theme_font_size_override("font_size", 30)
		button.add_theme_color_override("font_color", Card.RED if suit in [1, 2] else INK)
		button.pressed.connect(choose.bind(suit))
		actions.add_child(button)
	actions.position = Vector2(620, 249)
	actions.size.x = 336
	next_button = table_button("")
	next_button.position = Vector2(967, 396)
	next_button.size = Vector2(237, 50)
	next_button.pressed.connect(next_trick)
	board.add_child(next_button)
	rules.deal(randi())
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	refresh()

func fit_table() -> void:
	var zoom := minf(size.x / BOARD_SIZE.x, size.y / BOARD_SIZE.y)
	board.scale = Vector2.ONE * zoom
	board.position = (size - BOARD_SIZE * zoom) / 2

func label_at(rect: Rect2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.add_theme_font_override("font", Card.FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	board.add_child(label)
	label.position = rect.position
	label.size = rect.size
	return label

func table_button(words: String) -> Button:
	var button := Button.new()
	button.text = words
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_font_override("font", Card.FONT)
	button.add_theme_font_size_override("font_size", 18)
	for state in ["normal", "hover", "pressed"]:
		var style := StyleBoxFlat.new()
		style.bg_color = PAPER if state == "normal" else GOLD
		style.set_corner_radius_all(5)
		button.add_theme_stylebox_override(state, style)
		button.add_theme_color_override("font_color" if state == "normal" else "font_" + state + "_color", INK)
	button.add_theme_color_override("font_focus_color", INK)
	return button

func refresh() -> void:
	if not is_instance_valid(heading):
		return
	place.text = game.localize("hokm_place")
	heading.text = game.localize("hokm_title")
	help.text = game.localize("hokm_rules")
	for team in range(2):
		scores[team].text = game.localize("hokm_team_%d" % team) % rules.scores[team]
		for i in range(7):
			tallies[team].get_child(i).color = RUST if i < rules.scores[team] else Color("cebea1")
	var choosing := rules.trump < 0
	trump.text = game.localize("hokm_trump") % ("—" if choosing else suit_name(rules.trump))
	actions.visible = choosing
	var active_seat := rules.winner() if rules.trick.size() == 4 else rules.turn
	for i in range(4):
		actions.get_child(i).tooltip_text = suit_name(i)
		actions.get_child(i).accessibility_name = suit_name(i)
		seats[i].text = game.localize("seat_%d" % i)
		seats[i].add_theme_color_override("font_color", GOLD if i == active_seat else PAPER)
	var legal := rules.legal_cards(0)
	draw_hand(legal)
	draw_trick()
	next_button.visible = rules.trick.size() == 4 or rules.finished()
	next_button.text = game.localize("hokm_leave" if rules.finished() else "hokm_next")
	status.text = turn_prompt(legal)

func draw_hand(legal: Array) -> void:
	clear_cards(hand)
	var my_turn := rules.trump >= 0 and not rules.finished() and rules.turn == 0 and rules.trick.size() < 4
	var count: int = rules.hands[0].size()
	for i in range(count):
		var value: int = rules.hands[0][i]
		var offset := i - (count - 1) * 0.5
		var face := put_card(hand, value, Vector2(788 + offset * 61, 602 + offset * offset * 0.50),
			not my_turn or not legal.has(value))
		face.rotation = deg_to_rad(offset * 1.5)
		face.muted = my_turn and not legal.has(value)
		face.pressed.connect(play.bind(value))

func draw_trick() -> void:
	clear_cards(trick)
	sliding_card = null
	if rules.trump < 0:
		for i in range(3):
			var back := put_card(trick, -1, Vector2(784 + i * 3, 169 - i * 2), true)
			back.scale = Vector2.ONE * 0.8
			back.rotation_degrees = -10 + i * 4
	for played in rules.trick:
		var seat: int = played.seat
		var face := put_card(trick, played.card, SEATS[seat], true)
		face.rotation_degrees = [-4, 8, 3, -8][seat]
		face.winning = rules.trick.size() == 4 and rules.winner() == seat

func turn_prompt(legal: Array) -> String:
	if rules.trump < 0:
		return game.localize("hokm_choose")
	if rules.finished():
		return game.localize("hokm_won" if rules.scores[0] >= 7 else "hokm_lost")
	if rules.trick.size() == 4:
		return game.localize("hokm_winner") % seats[rules.winner()].text
	if rules.turn != 0:
		return game.localize("hokm_turn") % seats[rules.turn].text
	if rules.trick.is_empty():
		return game.localize("hokm_lead")
	var lead_suit := int(rules.trick[0].card) / 13
	if int(legal[0]) / 13 != lead_suit:
		return game.localize("hokm_discard")
	return game.localize("hokm_follow") % suit_name(lead_suit)

func suit_name(suit: int) -> String:
	return game.localize("hokm_suit_%d" % suit)

func put_card(layer: Control, value: int, center: Vector2, locked: bool) -> Card:
	var face := Card.new()
	face.card = value
	face.disabled = locked
	if locked:
		face.mouse_filter = Control.MOUSE_FILTER_STOP if layer == hand else Control.MOUSE_FILTER_IGNORE
		face.focus_mode = Control.FOCUS_NONE
	if value >= 0:
		face.accessibility_name = Card.RANKS[value % 13] + " " + suit_name(value / 13)
	layer.add_child(face)
	face.position = center - Card.FACE_SIZE / 2
	return face

func clear_cards(layer: Control) -> void:
	for child in layer.get_children():
		layer.remove_child(child)
		child.queue_free()

func choose(suit: int) -> void:
	if game.active and rules.trump < 0:
		rules.choose_trump(suit)
		refresh()

func play(value: int) -> void:
	if game.active and rules.play(0, value):
		show_play(0)

func show_play(seat: int) -> void:
	refresh()
	sliding_card = trick.get_child(-1)
	slide_to = sliding_card.position
	sliding_card.position += (NAMEPLATES[seat] - SEATS[seat]).normalized() * 55
	wait_left = TURN_DELAY

func _process(delta: float) -> void:
	if not game.active or not is_visible_in_tree():
		return
	if is_instance_valid(sliding_card):
		sliding_card.position = sliding_card.position.move_toward(slide_to, delta * 320)
	if rules.trump < 0 or rules.finished() or rules.turn == 0 or rules.trick.size() == 4:
		return
	wait_left -= delta
	if wait_left <= 0:
		var seat := rules.turn
		if rules.play(seat, rules.computer_card()):
			show_play(seat)

func next_trick() -> void:
	if not game.active:
		return
	if rules.finished():
		hide()
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		finished.emit()
		queue_free()
	elif rules.trick.size() == 4:
		rules.collect_trick()
		wait_left = TURN_DELAY
		refresh()
