extends BaseButton
## A paper card drawn at deck coordinates so table and hand share one face.
const FACE_SIZE := Vector2(82, 116)
const SUITS := ["♠", "♥", "♦", "♣"]
const RANKS := ["2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K", "A"]
const GOLD := Color("bc9252")
const INK := Color("253e44")
const RED := Color("a03940")
const PAPER := Color("fff3d7")
const FONT := preload("res://assets/fonts/vazirmatn/Vazirmatn.ttf")
# Coordinates on a three-column, seven-row pip grid.
const PIPS := [
	[1, 19], [1, 10, 19], [0, 2, 18, 20], [0, 2, 10, 18, 20],
	[0, 2, 9, 11, 18, 20], [0, 2, 4, 9, 11, 18, 20],
	[0, 2, 4, 9, 11, 16, 18, 20], [0, 2, 6, 8, 10, 12, 14, 18, 20],
	[0, 2, 4, 6, 8, 12, 14, 16, 18, 20],
]
var card := -1
var muted := false
var winning := false

func _ready() -> void:
	size = FACE_SIZE
	pivot_offset = size / 2
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if not disabled else Control.CURSOR_ARROW
	for changed: Signal in [mouse_entered, mouse_exited, focus_entered, focus_exited]:
		changed.connect(queue_redraw)

func _draw() -> void:
	var highlight := not disabled and (is_hovered() or has_focus())
	var rect := Rect2(Vector2.ZERO, FACE_SIZE)
	var style := StyleBoxFlat.new()
	style.set_corner_radius_all(6)
	style.bg_color = Color("fffaf0") if highlight else PAPER
	style.shadow_color = Color(0.025, 0.04, 0.03, 0.44)
	style.shadow_size = 3
	style.shadow_offset = Vector2(1, 3)
	style.set_border_width_all(3 if highlight or winning else 1)
	style.border_color = Color("eda74e") if highlight or winning else Color("b4a792")
	draw_style_box(style, rect)
	if card < 0:
		draw_back(rect)
		return
	var rank := card % 13
	var suit := card / 13
	var ink := RED if suit in [1, 2] else INK
	for corner in range(2):
		draw_set_transform(Vector2.ZERO if corner == 0 else FACE_SIZE, corner * PI)
		glyph(RANKS[rank], Vector2(13, 23), 20, ink)
		glyph(SUITS[suit], Vector2(13, 38), 16, ink)
	draw_set_transform(Vector2.ZERO)
	if rank < 9:
		for spot: int in PIPS[rank]:
			glyph(SUITS[suit], Vector2(27 + (spot % 3) * 14, 32 + (spot / 3) * 10), 17, ink)
	else:
		# An engraved seal for the courts and ace, keyed to the suit's ink.
		var center := FACE_SIZE / 2
		draw_colored_polygon(diamond(center, Vector2(23, 40)), ink)
		draw_polyline(diamond(center, Vector2(20, 35)), GOLD, 1.4, true)
		draw_seal(center, rank, suit)
	if muted:
		style.shadow_size = 0
		style.set_border_width_all(0)
		style.bg_color = Color(0.19, 0.24, 0.21, 0.40)
		draw_style_box(style, rect)

func draw_seal(center: Vector2, rank: int, suit: int) -> void:
	draw_set_transform(center)
	match rank:
		9: # The jack's feather.
			draw_colored_polygon(PackedVector2Array([Vector2(-8, 9), Vector2(-9, -4),
				Vector2(-1, -17), Vector2(10, -22), Vector2(9, -7), Vector2(3, 3)]), PAPER)
			draw_line(Vector2(-11, 15), Vector2(6, -15), GOLD, 2, true)
		10: # A six-petalled flower for the queen.
			for i in range(6):
				draw_circle(Vector2.from_angle(i * TAU / 6) * 7 + Vector2(0, -5), 5, PAPER, true, -1, true)
			draw_circle(Vector2(0, -5), 4, GOLD, true, -1, true)
		11:
			draw_colored_polygon(PackedVector2Array([Vector2(-14, -13), Vector2(-7, -5),
				Vector2(0, -17), Vector2(7, -5), Vector2(14, -13), Vector2(10, 2), Vector2(-10, 2)]), PAPER)
			draw_line(Vector2(-9, 6), Vector2(9, 6), GOLD, 2, true)
		12:
			glyph(SUITS[suit], Vector2(0, 9), 33, PAPER)
	if rank < 12:
		glyph(SUITS[suit], Vector2(0, 22), 13, GOLD)
	else:
		for y in [-23, 23]:
			draw_circle(Vector2(0, y), 2, GOLD, true, -1, true)
	draw_set_transform(Vector2.ZERO)

func draw_back(rect: Rect2) -> void:
	var field := rect.grow(-4)
	draw_rect(field, Color("863e47"))
	draw_rect(field.grow(-3), GOLD, false, 1)
	for row in range(5):
		for col in range(3):
			var point := Vector2(20 + col * 21, 18 + row * 20)
			draw_polyline(diamond(point, Vector2(8, 8)), Color("c88771"), 1, true)
	var center := rect.get_center()
	draw_colored_polygon(diamond(center, Vector2(20, 27)), INK)
	draw_polyline(diamond(center, Vector2(17, 23)), GOLD, 1.5, true)
	draw_colored_polygon(diamond(center, Vector2(6, 9)), PAPER)

static func diamond(at: Vector2, radius: Vector2) -> PackedVector2Array:
	return PackedVector2Array([at - Vector2(0, radius.y), at + Vector2(radius.x, 0),
		at + Vector2(0, radius.y), at - Vector2(radius.x, 0), at - Vector2(0, radius.y)])

func glyph(value: String, baseline: Vector2, font_size: int, color: Color) -> void:
	var width := FONT.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	draw_string(FONT, baseline - Vector2(width / 2, 0), value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
