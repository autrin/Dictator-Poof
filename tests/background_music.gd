extends SceneTree

class TestGame extends "res://scripts/game.gd":
	var settings_saves := 0

	func load_settings() -> void:
		sound_enabled = true
		music_volume = 0.55

	func save_settings() -> void:
		settings_saves += 1

var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if condition:
		print("PASS: ", message)
	else:
		failures += 1
		push_error("FAIL: " + message)

func settle() -> void:
	await physics_frame
	await physics_frame
	await process_frame

func run() -> void:
	var game := TestGame.new()
	game.story_mode = false
	root.add_child(game)
	await settle()
	var music: AudioStreamPlayer = game.music
	var track: AudioStreamWAV = music.stream
	check(not music.playing and not game.started, "title screen is silent")
	check(track.stereo and track.format == AudioStreamWAV.FORMAT_16_BITS, "soundtrack is stereo 16-bit PCM")
	check(is_equal_approx(track.get_length(), 40.8), "soundtrack contains 2.4-second entry and 38.4-second theme")
	check(track.loop_mode == AudioStreamWAV.LOOP_FORWARD, "theme uses engine-level looping")
	check(track.loop_begin == 52920 and track.loop_end == 899640, "loop excludes the opening flourish")
	check(track.data.count(0) < track.data.size() / 2, "soundtrack contains non-silent samples")
	check(is_equal_approx(db_to_linear(music.volume_db), 0.55), "default music level is applied")
	game.start_or_resume()
	await settle()
	check(music.playing and not music.stream_paused, "entering gameplay starts music")
	music.seek(8.0)
	await settle()
	game.pause_run()
	var paused_at := music.get_playback_position()
	await settle()
	check(music.stream_paused and is_equal_approx(music.get_playback_position(), paused_at), "pause holds the playback position")
	game.start_or_resume()
	await settle()
	check(not music.stream_paused and music.get_playback_position() >= paused_at - 0.05, "resume does not restart the entry")
	game.sound_enabled = false
	check(music.volume_db <= -80.0, "Sound off mutes music immediately")
	var effect_count := game.effects.get_child_count()
	game.play_tone(440.0, 0.1, 0.2)
	check(game.effects.get_child_count() == effect_count, "Sound off also blocks sound effects")
	game.sound_enabled = true
	game.hud.music_slider.value = 0.25
	check(is_equal_approx(game.music_volume, 0.25) and is_equal_approx(db_to_linear(music.volume_db), 0.25), "music slider changes only background level")
	check(game.settings_saves == 1, "music slider requests a settings save")
	game.music_volume = 0.0
	check(music.volume_db <= -80.0 and game.sound_enabled, "zero music volume leaves sound effects enabled")
	game.play_tone(440.0, 0.1, 0.2)
	check(game.effects.get_child_count() == effect_count + 1, "effects still play while background music is silent")
	game.music_volume = 2.0
	check(is_equal_approx(game.music_volume, 1.0), "music level is clamped")
	game.music_volume = 0.0
	music.seek(track.get_length() - 0.04)
	OS.delay_msec(250)
	await settle()
	check(music.playing, "playback remains active after the repeat boundary")
	check(music.get_playback_position() >= 2.4 and music.get_playback_position() < 4.0, "repeat returns to the theme instead of the entry flourish")
	game._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(music.stream_paused and not game.active, "focus loss pauses music and gameplay together")
	game.start_or_resume()
	game.finish(false)
	check(music.stream_paused, "result menu suspends music")
	game.start_or_resume()
	await settle()
	check(game.music == music and music.playing and music.get_playback_position() < 1.0, "death retry reuses one player and restarts the flourish")
	game.finish(true)
	check(music.stream_paused, "victory menu suspends music")
	game.start_or_resume()
	check(music.playing and not music.stream_paused, "joining friends resumes music")
	game.restart_mission()
	await settle()
	check(music.playing and music.get_playback_position() < 1.0, "replay restarts the flourish")
	game.set_language("fa", false)
	check(game.hud.music_label.text == "بلندی موسیقی", "music label switches to Persian live")
	game.set_language("en", false)
	check(game.hud.music_label.text == "Music volume", "music label switches back to English")
	await settle()
	check(game.hud.menu.position.y >= 0.0 and game.hud.menu.get_rect().end.y <= 720.0, "expanded settings menu fits the 720p viewport")
	print("RESULT: ", failures, " failure(s)")
	game.free()
	quit(0 if failures == 0 else 1)
