extends Node

var sfx_player: AudioStreamPlayer
var music_player: AudioStreamPlayer

# This is how AudioStreamPolyphonic is meant to be used, apparently
func setup_polyphonic_player(player: AudioStreamPlayer, max_polyphony: int, bus: StringName) -> void:
	player.bus = bus
	player.max_polyphony = max_polyphony
	var stream = AudioStreamPolyphonic.new()
	stream.polyphony = max_polyphony
	player.stream = stream
	add_child(player)
	player.play() # actually play streams using player.get_stream_playback().play_stream()

func _ready() -> void:
	sfx_player = AudioStreamPlayer.new()
	var sfx_bus_name: StringName = &"sfx"
	if Global.is_web:
		sfx_bus_name = &"Master"
	setup_polyphonic_player(sfx_player, 32, sfx_bus_name)
	music_player = AudioStreamPlayer.new()
	setup_polyphonic_player(music_player, 8, &"music")
	process_mode = Node.PROCESS_MODE_ALWAYS

##
## Loading and caching audio streams by filename
##
var sfx_stream_cache = {}
var music_stream_cache = {}

func get_stream(stream_cache: Dictionary, filename: String, audio_subpath: String) -> AudioStream:
	var stream: AudioStream = stream_cache.get(filename)
	if !stream:
		stream = load("res://audio/%s/%s" % [audio_subpath, filename])
		if stream:
			stream_cache[filename] = stream
	return stream

func get_sfx_stream(filename: String) -> AudioStream:
	return get_stream(sfx_stream_cache, filename, "sfx")

func get_music_stream(filename: String) -> AudioStream:
	return get_stream(music_stream_cache, filename, "music")

##
## Playback and control using the polyphonic players
##
func set_stream_pitch_scale(player: AudioStreamPlayer, stream_id: int, pitch_scale: float) -> void:
	var playback: AudioStreamPlaybackPolyphonic = player.get_stream_playback()
	return playback.set_stream_pitch_scale(stream_id, pitch_scale)

func set_stream_volume(player: AudioStreamPlayer, stream_id: int, volume_linear: float) -> void:
	var playback: AudioStreamPlaybackPolyphonic = player.get_stream_playback()
	return playback.set_stream_volume(stream_id, linear_to_db(volume_linear))

func stop_stream(player: AudioStreamPlayer, stream_id: int) -> void:
	var playback: AudioStreamPlaybackPolyphonic = player.get_stream_playback()
	return playback.stop_stream(stream_id)

func play_stream(player: AudioStreamPlayer, stream: AudioStream, volume_linear: float = 0.5, from_offset: float = 0, pitch_scale: float = 1) -> int:
	var playback: AudioStreamPlaybackPolyphonic = player.get_stream_playback()
	return playback.play_stream(stream, from_offset, linear_to_db(volume_linear), pitch_scale)

##
## SFX control
##
func play_sfx(filename: String, volume_linear: float = 0.5, from_offset: float = 0, pitch_scale: float = 1) -> int:
	var stream = get_sfx_stream(filename)
	if !stream:
		return AudioStreamPlaybackPolyphonic.INVALID_ID
	var id = play_stream(sfx_player, stream, volume_linear, from_offset, pitch_scale)
	# AudioStreamPlaybackPolyphonic does not work in web builds, because the
	# streams never "stop" properly, or something...
	# Stopping them manually with a timer works though.
	# This does cause a C++ error about playback being null, but it doesn't
	# seem to break anything.
	if Global.is_web and id != AudioStreamPlaybackPolyphonic.INVALID_ID:
		var timer = get_tree().create_timer(stream.get_length() + 0.1)
		timer.timeout.connect(func():
			stop_stream(sfx_player, id)
		)
	return id

##
## Music control
##
class PlayingMusic extends  RefCounted:
	var id: int = AudioStreamPlaybackPolyphonic.INVALID_ID
	var volume_linear: float = 0
	var fade_in_target_volume: float = 1

var curr_music: PlayingMusic
var fading_music: Array[PlayingMusic]

const crossfade_time_secs: float = 0.5

# Fade out music over crossfade_time_secs
func stop_music() -> void:
	if curr_music:
		fading_music.append(curr_music)
		curr_music = null

# Start music
# If a song is currently playing, crossfade with it ove crossfade_time_secs
func set_music(filename: String, volume_linear: float = 0.5) -> int:
	var do_fade_in = curr_music != null
	stop_music()

	var stream = get_music_stream(filename)
	if !stream:
		return AudioStreamPlaybackPolyphonic.INVALID_ID

	curr_music = PlayingMusic.new()
	if do_fade_in:
		curr_music.volume_linear = 0
	else:
		curr_music.volume_linear = volume_linear
	curr_music.fade_in_target_volume = volume_linear
	curr_music.id = play_stream(music_player, stream, curr_music.volume_linear)

	return curr_music.id

func _physics_process(delta: float) -> void:
	var crossfade_inc = crossfade_time_secs * delta
	# fade in current music
	if curr_music:
		if curr_music.volume_linear < curr_music.fade_in_target_volume:
			curr_music.volume_linear = minf(curr_music.volume_linear + crossfade_inc, curr_music.fade_in_target_volume)
			set_stream_volume(music_player, curr_music.id, curr_music.volume_linear)
	# fade out fading music over fade_time_secs
	for music in fading_music:
		music.volume_linear -= crossfade_inc
		if music.volume_linear <= 0:
			stop_stream(music_player, music.id)
		else:
			set_stream_volume(music_player, music.id, music.volume_linear)
	# swap remove fading music that is now silent
	var i: int = 0
	while i < fading_music.size():
		if fading_music[i].volume_linear <= 0:
			fading_music[i] = fading_music.back()
			fading_music.pop_back()
		else:
			i += 1
