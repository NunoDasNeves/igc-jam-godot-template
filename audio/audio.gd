extends Node

var audio_stream_players_pool: Array[AudioStreamPlayer] = []

func alloc_player() -> AudioStreamPlayer:
	var player: AudioStreamPlayer = audio_stream_players_pool.pop_back()
	if audio_stream_players_pool.size() == 0:
		player = AudioStreamPlayer.new()
		add_child(player)

	return player

var sfx_stream_cache: Dictionary[String, AudioStream] = {}

func get_sfx_stream(filename: String) -> AudioStream:
	var stream = sfx_stream_cache.get(filename)
	if !stream:
		stream = load("res://audio/sfx/%s" % filename)
		if stream:
			sfx_stream_cache[filename] = stream
	return stream

class PlayingSound extends RefCounted:
	static var next_id: int = 0
	var filename: String
	var id: int
	var player: AudioStreamPlayer
	var tick_started: int

var playing_sounds = {}

func stop_and_recycle_sound(sound: PlayingSound) -> void:
	sound.player.stop()
	audio_stream_players_pool.append(sound.player)

func remove_playing_sound(sound: PlayingSound) -> void:
	var arr = playing_sounds.get(sound.filename)
	if !arr:
		return

	var idx = -1
	for i in range(arr.size()):
		if arr[i].id == sound.id:
			idx = i
			break

	if idx != -1:
		# swap remove
		arr[idx] = arr.back()
		arr.resize(arr.size() - 1)

	stop_and_recycle_sound(sound)

func add_playing_sound(sound: PlayingSound, polyphony: int = -1, override: bool = true) -> bool:
	if polyphony == 0:
		return false
	var arr = playing_sounds.get(sound.filename)
	if !arr:
		arr = []
		playing_sounds[sound.filename] = arr

	if polyphony == -1 or arr.size() < polyphony or override:
		if polyphony > 0 and arr.size() >= polyphony and override:
			var min_tick = sound.tick_started
			var min_sound_idx = 0
			for i in range(arr.size()):
				var s = arr[i]
				if s.tick_started < min_tick:
					min_tick = s.tick_started
					min_sound_idx = i
			var oldest_sound = arr[min_sound_idx]
			stop_and_recycle_sound(oldest_sound)
			arr[min_sound_idx] = sound
		else:
			arr.append(sound)
		sound.player.finished.connect(func (): remove_playing_sound(sound))
		#print("num playing: %s" % arr.size())
		return true

	return false

func play_sfx(filename: String, volume_linear: float = 0.5, polyphony: int = -1, override: bool = true) -> PlayingSound:
	var stream = get_sfx_stream(filename)
	if !stream:
		return
	var player = alloc_player()
	player.bus = "SFX"
	player.stream = stream
	player.volume_linear = volume_linear
	
	var sound = PlayingSound.new()
	sound.filename = filename
	sound.player = player
	sound.id = PlayingSound.next_id
	sound.tick_started = Time.get_ticks_usec()
	PlayingSound.next_id += 1
	if add_playing_sound(sound, polyphony):
		player.play()
	else:
		return null

	return sound

func set_music(filename: String, volume_linear: float = 0.5) -> void:
	# TODO
	pass
