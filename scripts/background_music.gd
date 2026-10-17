extends AudioStreamPlayer

const SCORE := preload("res://assets/audio/esfahan_opening.wav")
const INTRO_SECONDS := 2.4

func _ready() -> void:
	name = "Background music"
	var track: AudioStreamWAV = SCORE.duplicate()
	track.loop_mode = AudioStreamWAV.LOOP_FORWARD
	track.loop_begin = roundi(INTRO_SECONDS * track.mix_rate)
	track.loop_end = roundi(track.get_length() * track.mix_rate)
	stream = track

func start_or_resume() -> void:
	if stream_paused:
		stream_paused = false
	elif not playing:
		play()

func set_mix(enabled: bool, level: float) -> void:
	volume_db = linear_to_db(level) if enabled and level > 0.0 else -80.0
