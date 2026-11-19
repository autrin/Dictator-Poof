extends Control
## The carpet border comes from the same rug that sits in the family home.
const RUG := preload("res://assets/textures/interiors/nowruz_carpet.svg")
const BRASS := Color("b49664")
const CENTER := Vector2(788, 290)
var cloth: ImageTexture

func _ready() -> void:
	# A small repeating swatch keeps the linen grain stable at every resolution.
	var swatch := Image.create_empty(64, 64, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1403
	for y in range(64):
		for x in range(64):
			var grain := rng.randf_range(-0.012, 0.012) + 0.006 * ((x + (y / 2)) % 2)
			swatch.set_pixel(x, y, Color(0.123 + grain, 0.271 + grain, 0.257 + grain))
	cloth = ImageTexture.create_from_image(swatch)
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED

func _draw() -> void:
	draw_texture_rect(RUG, Rect2(0, 0, 1280, 720), false)
	# Expose a narrow strip of the carpet's woven border above and below the felt.
	draw_texture_rect_region(RUG, Rect2(15, 4, 1250, 20), Rect2(32, 30, 960, 43))
	draw_texture_rect_region(RUG, Rect2(15, 696, 1250, 20), Rect2(32, 944, 960, 43))
	draw_texture_rect(cloth, Rect2(19, 23, 1242, 674), true)
	draw_rect(Rect2(22, 25, 1236, 669), BRASS, false, 1)
	# Two offset threads catch the light along each edge of the playing cloth.
	for y in [30, 689]:
		draw_dashed_line(Vector2(28, y), Vector2(1252, y), Color("75948a"), 1, 4)
	for x in [28, 1252]:
		draw_dashed_line(Vector2(x, 28), Vector2(x, 692), Color("75948a"), 1, 4)
	for ring in [102, 107, 167, 172]:
		var points := PackedVector2Array()
		for i in range(17):
			var angle := i * TAU / 16
			var radius: float = ring * (0.83 if i % 2 else 1.0)
			points.append(CENTER + Vector2.from_angle(angle) * radius)
		draw_polyline(points, Color("3e6359"), 1.2, true)
	# A folded ivory score sheet and a glass of tea occupy the edge of the rug.
	draw_rect(Rect2(51, 65, 249, 468), Color("153632"))
	draw_rect(Rect2(47, 60, 249, 468), Color("f3e5c8"))
	draw_rect(Rect2(53, 66, 237, 456), Color("cfbd9c"), false, 1)
	for y in [178, 309]:
		draw_line(Vector2(68, y), Vector2(275, y), BRASS, 1)
	draw_tea(Vector2(160, 610))

func draw_tea(at: Vector2) -> void:
	draw_set_transform(at, -0.13, Vector2(1, 0.81))
	draw_circle(Vector2(3, 5), 62, Color("163b37"), true, -1, true)
	draw_circle(Vector2.ZERO, 61, Color("d8caaf"), true, -1, true)
	for radius in [50, 55, 58]:
		draw_arc(Vector2.ZERO, radius, 0, TAU, 90, Color("51777e"), 1.5, true)
	for i in range(14):
		draw_circle(Vector2.from_angle(i * TAU / 14) * 53, 2, Color("487782"), true, -1, true)
	# A spoon resting over the lip of the saucer.
	draw_line(Vector2(21, 24), Vector2(85, 41), Color("a49e86"), 5, true)
	draw_line(Vector2(21, 23), Vector2(85, 40), Color("e9ddc0"), 2, true)
	draw_circle(Vector2(18, 22), 7, Color("d5ccb2"), true, -1, true)
	draw_arc(Vector2(36, -8), 13, -PI * 0.55, PI * 0.56, 22, Color("ece2c8"), 4, true)
	draw_circle(Vector2(0, -8), 36, Color("bca582"), true, -1, true)
	draw_circle(Vector2(0, -8), 31, Color("83401e"), true, -1, true)
	draw_circle(Vector2(-2, -10), 25, Color("6e311c"), true, -1, true)
	draw_arc(Vector2(0, -8), 34, 0, TAU, 72, Color("f3e3c2"), 2, true)
	draw_arc(Vector2(-1, -9), 27, 3.75, 4.8, 18, Color("d79548"), 2.5, true)
	draw_set_transform(Vector2.ZERO)
