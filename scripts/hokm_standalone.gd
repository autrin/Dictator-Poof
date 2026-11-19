extends Node
## Run this scene with F6 to play the same table used in the family chapter.
const Table := preload("res://scripts/hokm.gd")
const StoryText := preload("res://scripts/nowruz_text.gd")
var active := true
var language := "en"
var table: Table

func _ready() -> void:
	var config := ConfigFile.new()
	if config.load("user://settings.cfg") == OK and config.get_value("preferences", "language", "en") == "fa":
		language = "fa"
	deal_hand()

func deal_hand() -> void:
	table = Table.new()
	table.game = self
	table.leave_label = "hokm_deal_again"
	table.finished.connect(deal_hand, CONNECT_DEFERRED)
	add_child(table)

func localize(key: String) -> String:
	return StoryText.text(language, key)

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.keycode == KEY_F2 and event.pressed and not event.echo:
		language = "fa" if language == "en" else "en"
		table.refresh()
		get_viewport().set_input_as_handled()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		active = false
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		active = true
