extends PanelContainer
signal finished
const Rules := preload("res://scripts/hokm_rules.gd")
const SUITS := ["♠", "♥", "♦", "♣"]
const RANKS := ["2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K", "A"]
var game: Node3D
var rules := Rules.new()
var column: VBoxContainer
var status: Label
var trick_label: Label
var options: GridContainer
var next_button: Button

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	offset_left = -460
	offset_right = 460
	offset_top = -220
	offset_bottom = 220
	var style := StyleBoxFlat.new()
	style.bg_color = Color("233d39")
	style.set_content_margin_all(24)
	add_theme_stylebox_override("panel", style)
	column = VBoxContainer.new()
	column.add_theme_constant_override("separation", 18)
	add_child(column)
	status = Label.new()
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.custom_minimum_size = Vector2(850, 80)
	status.add_theme_font_override("font", preload("res://assets/fonts/vazirmatn/Vazirmatn.ttf"))
	column.add_child(status)
	trick_label = Label.new()
	trick_label.custom_minimum_size.y = 70
	trick_label.add_theme_font_override("font", preload("res://assets/fonts/vazirmatn/Vazirmatn.ttf"))
	column.add_child(trick_label)
	options = GridContainer.new()
	options.columns = 7
	column.add_child(options)
	next_button = Button.new()
	next_button.pressed.connect(next_trick)
	column.add_child(next_button)
	rules.deal(randi())
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	refresh()

func card_text(card: int) -> String:
	return RANKS[card % 13] + " " + SUITS[card / 13]

func refresh() -> void:
	if not is_instance_valid(column):
		return
	for child in options.get_children():
		options.remove_child(child)
		child.queue_free()
	status.text = game.localize("hokm_choose") if rules.trump < 0 else game.localize("hokm_score") % [SUITS[rules.trump], rules.scores[0], rules.scores[1]]
	trick_label.text = game.localize("hokm_rules") + "\n"
	for played in rules.trick:
		trick_label.text += game.localize("seat_%d" % played.seat) + ": " + card_text(played.card) + "    "
	if rules.trump < 0:
		trick_label.text += "\n"
		for card: int in rules.hands[0]:
			trick_label.text += card_text(card) + "    "
		for suit in range(4):
			var button := add_button(SUITS[suit])
			button.pressed.connect(func():
				if game.active:
					rules.choose_trump(suit)
					refresh())
	else:
		for card: int in rules.hands[0]:
			var button := add_button(card_text(card))
			button.disabled = rules.finished() or rules.turn != 0 or rules.trick.size() == 4 or not rules.legal_cards(0).has(card)
			button.modulate = Color("ffbcb0") if card / 13 in [1, 2] else Color.WHITE
			button.pressed.connect(func():
				if game.active and rules.play(0, card):
					play_computers()
					refresh())
	next_button.visible = rules.trick.size() == 4 or rules.finished()
	next_button.text = game.localize("hokm_leave" if rules.finished() else "hokm_next")
	if rules.trick.size() == 4:
		trick_label.text += "\n" + game.localize("hokm_winner") % game.localize("seat_%d" % rules.winner())
	if rules.finished():
		status.text += "\n" + game.localize("hokm_won" if rules.scores[0] >= 7 else "hokm_lost")

func add_button(words: String) -> Button:
	var button := Button.new()
	button.text = words
	button.custom_minimum_size = Vector2(105, 54)
	button.add_theme_font_size_override("font_size", 23)
	options.add_child(button)
	return button

func play_computers() -> void:
	while rules.turn != 0 and rules.trick.size() < 4 and not rules.finished():
		rules.play(rules.turn, rules.computer_card())

func next_trick() -> void:
	if not game.active:
		return
	if rules.finished():
		hide()
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		finished.emit()
		queue_free()
		return
	rules.collect_trick()
	if not rules.finished():
		play_computers()
	refresh()
