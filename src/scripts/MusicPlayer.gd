extends AudioStreamPlayer

@export var fade_curve: Curve
@export var fade_time := 2.0

var intro := preload("res://audio/placing pieces of planets intro.ogg")
var loop_intro := preload("res://audio/placing pieces of planets loop.ogg")
var day_night_cycle_loop := preload("res://audio/day night cycle.ogg")
var moonwalk_air_loop := preload("res://audio/moonwalk air.ogg")
var warp_drive_diagnostics_loop := preload("res://audio/warp drive diagnostics.ogg")
var gravity_assist := preload("res://audio/gravity assist.ogg")

var intro_done := false
var global: Node
var fade_and_stop := false
var default_db := 0.0
var faded_db := -80.0
var fade_counter := 0.0
var default_pitch := 1.0
var pitch_mod := false
var album: Array[AudioStreamOggVorbis]
var song_queued := false
var music_mode := true

# Called when the node enters the scene tree for the first time.
func _ready():
	global = get_node("/root/Global")
	global.title_screen_signal.connect(_on_global_title_screen_signal)
	global.stop_the_music.connect(_on_global_stop_the_music)
	global.pause_the_music.connect(_on_global_pause_the_music)
	global.play_the_music.connect(_on_global_play_the_music)
	album = [day_night_cycle_loop, moonwalk_air_loop, warp_drive_diagnostics_loop, gravity_assist]
	if global.music:
		play()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if fade_and_stop:
		fade_counter += delta
		fade_counter = clamp(fade_counter, 0.0, fade_time)
		var fade_remapped = remap(fade_counter, 0.0, fade_time, 0.0, 1.0)
		volume_db = lerp(default_db, faded_db, fade_curve.sample_baked(fade_remapped))
		if is_equal_approx(fade_counter, fade_time):
			stop()
			volume_db = default_db
			fade_and_stop = false
			fade_counter = 0.0
			print("music stopped")
	elif song_queued:
		_pick_new_song()


func _on_finished():
	if not intro_done:
		intro_done = true
		stream = loop_intro
		if global.music:
			play()


func _on_global_title_screen_signal(status):
	if not status:
		fade_and_stop = true
		intro_done = true
		music_mode = false


func _on_universe_rotation_music_multiplier(multi):
	if global.title_screen:
		pitch_scale = default_pitch + multi


func _on_universe_no_pitch_mod():
	pitch_scale = 1.0


func _on_start_puzzle_button_up():
	music_mode = true
	if fade_and_stop:
		song_queued = true
	else:
		_pick_new_song()


func _pick_new_song():
	stream = album.pick_random()
	if global.music:
		play()
	song_queued = false


func _on_global_stop_the_music():
	music_mode = false
	if playing and not fade_and_stop:
		fade_and_stop = true


func _on_global_pause_the_music():
	if playing:
		stream_paused = true


func _on_global_play_the_music():
	if not music_mode:
		stop()
	stream_paused = false
	if not playing and music_mode:
		play()
