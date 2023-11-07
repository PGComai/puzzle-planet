extends Node

signal drawing_mode_changed(mode)
signal piece_in_space_changed(value)
signal debug_message_added
signal menu_open_signal(open)
signal preferences_read
signal ready_to_start_signal
signal ufo_ready_signal(dict)
signal piece_placed(cidx)
signal ufo_reset_signal
signal ufo_time_signal
signal wheel_rot_signal(rot)
signal ufo_done_signal
signal ufo_abducting_signal(info)
signal ufo_abduction_done_signal
signal puzzle_done
signal loaded_pieces_ready(pieces)
signal redo_atmosphere
signal title_screen_signal(status)
signal stop_the_music
signal pause_the_music
signal play_the_music
signal tablet_mode_signal(onoff)
signal default_vsplit_changed(split)

var generate_type := 3
var atmo_type: int:
	set(value):
		atmo_type = value
		emit_signal("redo_atmosphere")
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
		if not value:
			emit_signal("pause_the_music")
		else:
			emit_signal("play_the_music")
var debugging := false
var planet_height_for_ufo: float
var pieces_placed_so_far := [0, 0]:
	set(value):
		pieces_placed_so_far = value
var drawing_mode := false:
	set(value):
		drawing_mode = value
		emit_signal('drawing_mode_changed', value)
var change_ez_mantle_roughness := false
var change_ez_mantle_value := false:
	set(value):
		change_ez_mantle_value = value
		change_ez_mantle_roughness = value
var ez_mantle_proxy := 0.0
var ez_roughness_proxy := 0.0
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
var puzzle_started := false:
	set(value):
		puzzle_started = value
		if value:
			_save_puzzle()
var puzzle_finished := false:
	set(value):
		puzzle_finished = value
		if value:
			print("puzzle finished")
			emit_signal("puzzle_done")
		else:
			print("puzzle unfinished")
var ready_to_start := false:
	set(value):
		if value:
			emit_signal("ready_to_start_signal")
var ufo_locations := Dictionary():
	set(value):
		emit_signal("ufo_ready_signal", value)
var placed_cidx : int:
	set(value):
		emit_signal("piece_placed", value)
var ufo_reset := false:
	set(value):
		if value:
			emit_signal("ufo_reset_signal")
var ufo_time := false:
	set(value):
		if value:
			emit_signal("ufo_time_signal")
var wheel_rot : float:
	set(value):
		emit_signal("wheel_rot_signal", value)
var ufo_done := false:
	set(value):
		if value:
			emit_signal("ufo_done_signal")
var ufo_abducting: Array:
	set(value):
		emit_signal("ufo_abducting_signal", value)
var ufo_abduction_done := false:
	set(value):
		if value:
			emit_signal("ufo_abduction_done_signal")
var piece_tracker: Dictionary
var unfinished_puzzle_exists := false
var title_screen := true:
	set(value):
		title_screen = value
		emit_signal("title_screen_signal", value)
var stop_music := false:
	set(value):
		if value:
			emit_signal("stop_the_music")

var save_data: FileAccess
var save_preferences: FileAccess

var preferences_dict: Dictionary
var node_data := {}
var current_puzzle_was_loaded := false
var title_planet_resource := preload("res://planets/title_planet_resource.tres")
var title_planet: Resource

var tablet_mode := false:
	set(value):
		tablet_mode = value
		emit_signal("tablet_mode_signal", value)
var default_vsplit: int:
	set(value):
		default_vsplit = value
		emit_signal("default_vsplit_changed", value)

# Called when the node enters the scene tree for the first time.
func _ready():
	if not FileAccess.file_exists("user://save_data.dat"):
		print("no save_data file exists")
		save_data = FileAccess.open("user://save_data.dat", FileAccess.WRITE_READ)
		save_data.store_var(false)
		save_data.close()
	else:
		save_data = FileAccess.open("user://save_data.dat", FileAccess.READ)
		unfinished_puzzle_exists = !save_data.get_var()
		print("unfinished puzzle exists: %s" % unfinished_puzzle_exists)
#		print(save_data.get_var(true))
#		print(save_data.get_var(true))
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
	RenderingServer.global_shader_parameter_set('ez_mantle_roughness', 0.0)
	_load_planet_for_title()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if change_ez_mantle_value:
		if piece_in_space:
			ez_mantle_proxy = lerp(ez_mantle_proxy, 0.6, 0.03)
			if is_equal_approx(ez_mantle_proxy, 0.6):
				ez_mantle_proxy = 0.6
				change_ez_mantle_value = false
		else:
			ez_mantle_proxy = lerp(ez_mantle_proxy, 0.0, 0.1)
			if is_equal_approx(ez_mantle_proxy, 0.0):
				ez_mantle_proxy = 0.0
				change_ez_mantle_value = false
		RenderingServer.global_shader_parameter_set('ez_mantle_effect', ez_mantle_proxy)
	if change_ez_mantle_roughness:
		if piece_in_space:
			ez_roughness_proxy = lerp(ez_roughness_proxy, 1.0, 0.15)
			if is_equal_approx(ez_roughness_proxy, 1.0):
				ez_roughness_proxy = 1.0
				change_ez_mantle_roughness = false
		else:
			ez_roughness_proxy = lerp(ez_roughness_proxy, 0.0, 0.01)
			if is_equal_approx(ez_roughness_proxy, 0.0):
				ez_roughness_proxy = 0.0
				change_ez_mantle_roughness = false
		RenderingServer.global_shader_parameter_set('ez_mantle_roughness', ez_roughness_proxy)


func _save_puzzle():
	piece_tracker = {}
	var saving_nodes = get_tree().get_nodes_in_group("persist")
	node_data = {}
	print("saving %s nodes" % saving_nodes.size())
	for n in saving_nodes:
		var is_in_pieces_group := n.is_in_group("pieces")
		piece_tracker[n.idx] = is_in_pieces_group
		node_data[n.idx] = get_node_data(n)
	print(piece_tracker)
	#saving_nodes = saving_nodes.map(pack_scene)
	if save_data.is_open():
		save_data.close()
	save_data = FileAccess.open("user://save_data.dat", FileAccess.WRITE_READ)
	var was_puzzle_completed := false
	var puzzle_has_rotation := rotation
	save_data.store_var(was_puzzle_completed)
	save_data.store_var(puzzle_has_rotation)
	save_data.store_var(pieces_placed_so_far)
	save_data.store_var(generate_type)
	save_data.store_var(piece_tracker)
	save_data.store_var(node_data, true)
	save_data.close()
	print("puzzle saved")
	ufo_time = true ### THIS LINE STARTS THE GAME


func get_node_data(n: Node) -> Dictionary:
	var return_dict := {
		"random_rotation_offset": n.random_rotation_offset,
		"vertex": n.vertex,
		"normal": n.normal,
		"color": n.color,
		"direction": n.direction,
		"trees_on": n.trees_on,
		"tree_positions": n.tree_positions,
		"ocean": n.ocean,
		"vertex_cw": n.vertex_cw,
		"normal_cw": n.normal_cw,
		"color_cw": n.color_cw,
		"vertex_w": n.vertex_w,
		"normal_w": n.normal_w,
		"color_w": n.color_w,
		"planet_style": n.planet_style,
		"wall_vertex": n.wall_vertex,
		"wall_normal": n.wall_normal,
		"wall_color": n.wall_color,
		"offset": n.offset,
		"lat": n.lat,
		"lon": n.lon,
		"orient_upright": n.orient_upright,
		"circle_idx": n.circle_idx,
		"idx": n.idx,
	}
	return return_dict


func pack_scene(n : Node):
	var packed = PackedScene.new()
	packed.pack(n)
	return packed


func _save_puzzle_status():
	if get_tree().get_nodes_in_group("pieces").size() > 0:
		var saving_nodes = get_tree().get_nodes_in_group("persist")
		piece_tracker = {}
		for n in saving_nodes:
			var is_in_pieces_group := n.is_in_group("pieces")
			piece_tracker[n.idx] = is_in_pieces_group
		print(piece_tracker)
		if save_data.is_open():
			save_data.close()
		save_data = FileAccess.open("user://save_data.dat", FileAccess.WRITE_READ)
		var was_puzzle_completed := false
		var puzzle_has_rotation := rotation
		save_data.store_var(was_puzzle_completed)
		save_data.store_var(puzzle_has_rotation)
		save_data.store_var(pieces_placed_so_far)
		save_data.store_var(generate_type)
		save_data.store_var(piece_tracker)
		save_data.store_var(node_data, true)
		save_data.close()
		print("puzzle status saved")
	else:
		if save_data.is_open():
			save_data.close()
		save_data = FileAccess.open("user://save_data.dat", FileAccess.WRITE_READ)
		var was_puzzle_completed := true
		var puzzle_has_rotation := rotation
		save_data.store_var(was_puzzle_completed)
		save_data.store_var(puzzle_has_rotation)
		save_data.store_var(pieces_placed_so_far)
		save_data.store_var(generate_type)
		save_data.store_var(piece_tracker)
		save_data.store_var(node_data, true)
		save_data.store_var(was_puzzle_completed)
		save_data.close()


func _load_saved_puzzle():
	if save_data.is_open():
		save_data.close()
	save_data = FileAccess.open("user://save_data.dat", FileAccess.READ)
	var was_completed = save_data.get_var()
	rotation = save_data.get_var()
	pieces_placed_so_far = save_data.get_var()
	generate_type = save_data.get_var()
	var pieces_tracked = save_data.get_var()
	var loaded_pieces_data = save_data.get_var(true)
	save_data.close()
#	print("loaded %s nodes" % loaded_pieces.size())
#	for lp in loaded_pieces:
#		if lp.is_in_group("pieces") and not pieces_tracked[lp.idx]:
#			lp.remove_from_group("pieces")
	atmo_type = generate_type
	emit_signal("loaded_pieces_ready", [pieces_tracked, loaded_pieces_data])


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


func _save_planet_for_title():
	var saving_nodes = get_tree().get_nodes_in_group("persist")
	if saving_nodes.size() > 0:
		node_data = {}
		print("saving %s nodes for title" % saving_nodes.size())
		for n in saving_nodes:
			node_data[n.idx] = get_node_data(n)
	var ntp := TitlePlanet.new()
	ntp.node_data = node_data
	ntp.planet_style = generate_type
	var files := DirAccess.get_files_at("res://planets/")
	print("%s saved planets exist" % (files.size() - 1))
	var res_name := "planet%s.res" % files.size()
	ResourceSaver.save(ntp, "res://planets/%s" % res_name)


func _load_planet_for_title():
	var files := Array(DirAccess.get_files_at("res://planets/"))
	files.erase("title_planet_resource.tres")
	print(files)
	title_planet = ResourceLoader.load("res://planets/%s" % files.pick_random())
	atmo_type = title_planet.planet_style
