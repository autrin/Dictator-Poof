extends VBoxContainer
## Three prints, with a clue on each unfilled page and a family voice on the reverse.
const ART := preload("res://assets/album/nowruz_prints.png")
const PAPER := Color("f0debd")
const INK := Color("243b36")
var game: Node
var title := Label.new()
var inscription := Label.new()
var pictures: Array[TextureRect] = []
var names: Array[Label] = []
var captions: Array[Label] = []
var back := Button.new()
signal closed

static func print_texture(index: int) -> AtlasTexture:
	var texture := AtlasTexture.new()
	texture.atlas = ART
	var w := ART.get_width() / 3.0
	texture.region = Rect2(roundf(index * w), 0, floorf(w), ART.get_height())
	texture.filter_clip = true
	return texture

func _ready() -> void:
	add_theme_constant_override("separation", 12)
	add_child(title)
	title.add_theme_font_size_override("font_size", 34)
	var pages := HBoxContainer.new()
	pages.add_theme_constant_override("separation", 18)
	add_child(pages)
	for i in range(3):
		var mat := PanelContainer.new()
		var paper := StyleBoxFlat.new()
		paper.bg_color = PAPER
		paper.set_content_margin_all(14)
		mat.add_theme_stylebox_override("panel", paper)
		mat.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		pages.add_child(mat)
		var page := VBoxContainer.new()
		mat.add_child(page)
		var picture := TextureRect.new()
		picture.texture = print_texture(i)
		picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		picture.custom_minimum_size.y = 206
		page.add_child(picture)
		pictures.append(picture)
		names.append(page_text(page, 21))
		captions.append(page_text(page, 17))
	add_child(inscription)
	inscription.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	inscription.add_theme_color_override("font_color", Color("eac69a"))
	add_child(back)
	back.pressed.connect(func(): closed.emit())

func page_text(page: VBoxContainer, font_size: int) -> Label:
	var words := Label.new()
	words.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	words.add_theme_font_size_override("font_size", font_size)
	words.add_theme_color_override("font_color", INK)
	page.add_child(words)
	return words

func refresh() -> void:
	var collection: Array = game.keepsakes
	title.text = game.localize("album_count") % collection.size()
	for i in range(3):
		var found := collection.has(i)
		pictures[i].modulate = Color.WHITE if found else Color("373b39")
		names[i].text = game.localize("print_%d" % i)
		captions[i].text = game.localize(("memory_%d" if found else "clue_%d") % i)
	inscription.text = game.localize("album_complete" if collection.size() == 3 else "album_how")
	back.text = game.localize("back")
