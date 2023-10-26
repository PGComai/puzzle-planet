extends Node

signal drawing_mode_changed(mode)
signal piece_in_space_changed(value)
signal debug_message_added
signal menu_open_signal(open)
signal preferences_read

var generate_type := 3
var pieces_at_start := 15
var total_pieces := 30
var graphics_fancy := false
var preferences_have_been_read := false
var rotation := false
var sound := true:
	set(value):
		sound = value
		if preferences_have_been_read:
			_write_preferences_dict()
var vibration := true:
	set(value):
		vibration = value
		if preferences_have_been_read:
			_write_preferences_dict()
var music := true:
	set(value):
		music = value
		if preferences_have_been_read:
			_write_preferences_dict()
var debugging := false
var planet_height_for_ufo: float
var pieces_placed_so_far := [0, 0]
var drawing_mode := false:
	set(value):
		drawing_mode = value
		emit_signal('drawing_mode_changed', value)
var change_ez_mantle_value := false
var ez_mantle_proxy := 0.0
var ez_mantle_changed_during_placement := false
var piece_in_space := false:
	set(value):
		piece_in_space = value
		change_ez_mantle_value = true
		emit_signal('piece_in_space_changed', value)
var debug_log := PackedStringArray()
var debug_message: String:
	set(value):
		if debugging:
			debug_log.append(value)
			emit_signal('debug_message_added')
var menu_open := false:
	set(value):
		menu_open = value
		emit_signal('menu_open_signal', value)

var save_data: FileAccess
var save_preferences: FileAccess

var preferences_dict: Dictionary


# Called when the node enters the scene tree for the first time.
func _ready():
	save_data = FileAccess.open("user://save_data.dat", FileAccess.WRITE_READ)
	save_data.close()
	if not FileAccess.file_exists("user://save_preferences.dat"):
		print("no save_preferences file exists")
		save_preferences = FileAccess.open("user://save_preferences.dat", FileAccess.WRITE_READ)
		preferences_dict = {
			'sound': sound,
			'vibration': vibration,
			'music': music,
		}
		save_preferences.store_var(preferences_dict, true)
		save_preferences.close()
	else:
		_read_preferences_dict()
	preferences_have_been_read = true
	RenderingServer.global_shader_parameter_set('ez_mantle_effect', 0.0)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if change_ez_mantle_value:
		if piece_in_space:
			ez_mantle_proxy = lerp(ez_mantle_proxy, 0.6, 0.05)
			if is_equal_approx(ez_mantle_proxy, 0.6):
				ez_mantle_proxy = 0.6
				change_ez_mantle_value = false
		else:
			ez_mantle_proxy = lerp(ez_mantle_proxy, 0.0, 0.1)
			if is_equal_approx(ez_mantle_proxy, 0.0):
				ez_mantle_proxy = 0.0
				change_ez_mantle_value = false
		RenderingServer.global_shader_parameter_set('ez_mantle_effect', ez_mantle_proxy)


func _save_call():
	pass


func _write_preferences_dict():
	if save_preferences.is_open():
		save_preferences.close()
	save_preferences = FileAccess.open("user://save_preferences.dat", FileAccess.WRITE_READ)
	preferences_dict = {
		'sound': sound,
		'vibration': vibration,
		'music': music,
	}
	save_preferences.store_var(preferences_dict, true)
	save_preferences.close()
	debug_message = "Saved user preferences"
	print('writing save_preferences file')
	print(preferences_dict)


func _read_preferences_dict():
	if save_preferences:
		if save_preferences.is_open():
			save_preferences.close()
	save_preferences = FileAccess.open("user://save_preferences.dat", FileAccess.READ)
	preferences_dict = save_preferences.get_var(true)
	sound = preferences_dict['sound']
	vibration = preferences_dict['vibration']
	music = preferences_dict['music']
	print("reading save_preferences file")
	print(preferences_dict)
	save_preferences.close()
