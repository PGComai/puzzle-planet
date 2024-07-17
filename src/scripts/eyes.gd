extends Node3D

signal piece_added
signal rotation_music_multiplier(multi)
signal no_pitch_mod
signal vscan(y)

@export var h_sensitivity = 0.001
@export var v_sensitivity = 0.001

@onready var camera_3d = $h/v/Camera3D
@onready var piece_target = $h/v/Camera3D/piece_target
@onready var mesh_maker: Node
@onready var pieces = $Pieces
@onready var atmosphere = $Atmosphere
@onready var error_sound = $ErrorSound
@onready var rings = $Rings
@onready var puzzle_done_effect = $PuzzleDoneEffect

var rot_h = 0.0
var rot_v = 0.0
var v_min = -rad_to_deg((15.0*PI)/32.0)
var v_max = rad_to_deg((15.0*PI)/32.0)
var dx_acc := []
var dy_acc := []

var drag = false
var vel := Vector2()
var vel_sens = 0.1

var h: int

var upper_limit_reached := false
var lower_limit_reached := false
var limit_pull := 0.0
var fling := false

#var generate_type := 1
#var last_type := 1

var dx := 0.0
var dy := 0.0
var dx_final := 0.0
var dy_final := 0.0

var ready_for_nmm := false

var global

var last_rot_h_tick := 0.0
var last_rot_v_tick := 0.0

var piece = preload("res://scenes/planet_piece.tscn")
var current_piece: Node3D
var current_piece_mesh: MeshInstance3D
var looking := false
var correct_rotation := false
var fit_timer: float = 0.0
var fit: bool = false
var placed_signal := false

var new_mesh_maker = preload("res://scenes/mesh_maker.tscn")
var earth_mesh_maker = preload("res://scenes/mesh_maker_earth.tscn")
var moon_mesh_maker = preload("res://scenes/mesh_maker_moon.tscn")
var mars_mesh_maker = preload("res://scenes/mesh_maker_mars.tscn")
var venus_mesh_maker = preload("res://scenes/mesh_maker_venus.tscn")
var mercury_mesh_maker = preload("res://scenes/mesh_maker_mercury.tscn")
var jupiter_mesh_maker = preload("res://scenes/mesh_maker_jupiter.tscn")
var saturn_mesh_maker = preload("res://scenes/mesh_maker_saturn.tscn")
var uranus_mesh_maker = preload("res://scenes/mesh_maker_uranus.tscn")
var neptune_mesh_maker = preload("res://scenes/mesh_maker_neptune.tscn")
var pluto_mesh_maker = preload("res://scenes/mesh_maker_pluto.tscn")
var watermelon_mesh_maker = preload("res://scenes/mesh_maker_watermelon.tscn")

var vertical_scan := 1.0
var scanning := false

var title_planet_queued := false

func _ready():
	global = get_node('/root/Global')
	global.universe_node = self
	global.drawing_mode_changed.connect(_on_global_drawing_mode_changed)
	global.redo_atmosphere.connect(_on_global_redo_atmosphere)
	global.wheel_rot_signal.connect(_on_global_wheel_rot_signal)
	global.loaded_pieces_ready.connect(_on_global_loaded_pieces_ready)
	global.puzzle_done.connect(_on_global_puzzle_done)
	global.title_planet_ready.connect(_on_global_title_planet_ready)
	if global.title_screen:
		global._load_planet_for_title()


func _process(delta):
	if ready_for_nmm and len(get_tree().get_nodes_in_group('pieces')) == 0:
		add_child(mesh_maker)
		ready_for_nmm = false
	if $h/v.rotation.x > -(15*PI)/32:
		upper_limit_reached = false
	if $h/v.rotation.x < (15*PI)/32:
		lower_limit_reached = false
	limit_pull = clamp(limit_pull, 0.0, 0.1)
	var fling_strength = remap(limit_pull, 0.0, 7.0, 0.0, 1.0)
	#print(limit_pull)
	if not drag:
		if len(dx_acc) > 0:
			dx_acc.remove_at(0)
		if len(dy_acc) > 0:
			dy_acc.remove_at(0)
		if fling:
			if upper_limit_reached:
				dy_final = -fling_strength
			if lower_limit_reached:
				dy_final = fling_strength
			fling = false
			limit_pull = 0.0
		if not (global.title_screen or global.puzzle_finished):
			dx_final = lerp(dx_final, 0.0, 0.05)
		else:
			dx_final = lerp(dx_final, 0.001, 0.05)
			rot_v = lerp(rot_v, 0.0, 0.01)
		dy_final = lerp(dy_final, 0.0, 0.05)
	else:
		if abs(dx) < 0.01:
			dx = lerp(dx, 0.0, 0.1)
		if abs(dy) < 0.01:
			dy = lerp(dy, 0.0, 0.1)
		dx_acc.append(dx)
		dy_acc.append(dy)
		if len(dx_acc) > 5:
			dx_acc.remove_at(0)
		if len(dy_acc) > 5:
			dy_acc.remove_at(0)
		dx_final = dx_acc.reduce(func(accum, number): return accum + number, 0.0) / 5.0
		dy_final = dy_acc.reduce(func(accum, number): return accum + number, 0.0) / 5.0
	#print(dx_final)
	if upper_limit_reached or lower_limit_reached:
		pass
		#print('limit')
	else:
		limit_pull = 0.0
	if is_equal_approx(dx, 0.0):
		dx = 0.0
	if is_equal_approx(dy, 0.0):
		dy = 0.0
	rot_h -= dx_final
	if $h/v.rotation.x > (15*PI)/32 and dy_final < 0.0:
		dy_final /= remap($h/v.rotation.x, (15*PI)/32, PI/2, 2.0, 10.0)
	elif $h/v.rotation.x < -(15*PI)/32 and dy_final > 0.0:
		dy_final /= remap(abs($h/v.rotation.x), (15*PI)/32, PI/2, 2.0, 10.0)
	rot_v -= dy_final
	
	if upper_limit_reached:
		rot_v = clamp(rot_v, -PI/2, v_max)
	elif lower_limit_reached:
		rot_v = clamp(rot_v, v_min, PI/2)
	else:
		rot_v = clamp(rot_v, v_min, v_max)
	
	if is_equal_approx(dx_final, 0.001):
		emit_signal("no_pitch_mod")
	else:
		emit_signal("rotation_music_multiplier", dx_final - 0.001)
	
	$h.rotation.y = rot_h
	$h/v.rotation.x = rot_v
	
	### PIECE MANAGEMENT
	
	if looking:
		_piece_fit(delta)
	if fit_timer > 1.5:
		_place_piece()
	
	if scanning:
		_scan_v(delta)


func _atmo_change():
	var type = global.atmo_type
	print("new atmosphere: %s" % type)
	if type == 3:
		atmosphere.visible = true
		rings.visible = false
		RenderingServer.global_shader_parameter_set('atmo_fresnel_power', 0.75)
		RenderingServer.global_shader_parameter_set('atmo_daylight', Color('779ddc'))
		RenderingServer.global_shader_parameter_set('atmo_sunset', Color('e5152a'))
	elif type == 2:
		atmosphere.visible = true
		rings.visible = false
		RenderingServer.global_shader_parameter_set('atmo_fresnel_power', 0.75)
		RenderingServer.global_shader_parameter_set('atmo_daylight', Color('b89679'))
		RenderingServer.global_shader_parameter_set('atmo_sunset', Color('b89679'))
	elif type == 5:
		atmosphere.visible = true
		rings.visible = false
		RenderingServer.global_shader_parameter_set('atmo_fresnel_power', 1.0)
		RenderingServer.global_shader_parameter_set('atmo_daylight', Color('d4995a'))
		RenderingServer.global_shader_parameter_set('atmo_sunset', Color('207be3'))
	elif type == 4 or type == 1 or type == 11:
		atmosphere.visible = false
		rings.visible = false
		RenderingServer.global_shader_parameter_set('atmo_fresnel_power', 0.75)
		RenderingServer.global_shader_parameter_set('atmo_daylight', Color('black'))
		RenderingServer.global_shader_parameter_set('atmo_sunset', Color('black'))
	elif type == 6:
		atmosphere.visible = true
		rings.visible = false
		RenderingServer.global_shader_parameter_set('atmo_fresnel_power', 0.9)
		RenderingServer.global_shader_parameter_set('atmo_daylight', Color('c5a37f'))
		RenderingServer.global_shader_parameter_set('atmo_sunset', Color('e2a277'))
	elif type == 7:
		atmosphere.visible = true
		rings.visible = true
		RenderingServer.global_shader_parameter_set('atmo_fresnel_power', 0.9)
		RenderingServer.global_shader_parameter_set('atmo_daylight', Color('c5a37f'))
		RenderingServer.global_shader_parameter_set('atmo_sunset', Color('e2a277'))
	elif type == 8:
		atmosphere.visible = true
		rings.visible = false
		RenderingServer.global_shader_parameter_set('atmo_fresnel_power', 0.9)
		RenderingServer.global_shader_parameter_set('atmo_daylight', Color('7a9cae'))
		RenderingServer.global_shader_parameter_set('atmo_sunset', Color('7a9cae'))
	elif type == 9:
		atmosphere.visible = true
		rings.visible = false
		RenderingServer.global_shader_parameter_set('atmo_fresnel_power', 0.9)
		RenderingServer.global_shader_parameter_set('atmo_daylight', Color('7199c9'))
		RenderingServer.global_shader_parameter_set('atmo_sunset', Color('7199c9'))
	elif type == 10:
		atmosphere.visible = true
		rings.visible = false
		RenderingServer.global_shader_parameter_set('atmo_fresnel_power', 1.4)
		RenderingServer.global_shader_parameter_set('atmo_daylight', Color('81cfff'))
		RenderingServer.global_shader_parameter_set('atmo_sunset', Color('81cfff'))


func _on_global_drawing_mode_changed(value):
	pass


func _on_generate_button_up():
	var ufo = get_tree().get_first_node_in_group('ufo')
	ufo.reparent(self, false)
	ufo.in_browser = false
	ufo.browser_drop_off_begin = false
	global.ufo_reset = true
	if mesh_maker:
		mesh_maker.queue_free()
	for n in get_tree().get_nodes_in_group('pieces'):
		n.queue_free()
	for n in get_tree().get_nodes_in_group("title_pieces"):
		n.queue_free()
	for n in pieces.get_children():
		n.queue_free()
	_atmo_change()
	var nmm
	if global.generate_type == 3:
		nmm = earth_mesh_maker.instantiate()
	elif global.generate_type == 4:
		nmm = moon_mesh_maker.instantiate()
	elif global.generate_type == 5:
		nmm = mars_mesh_maker.instantiate()
	elif global.generate_type == 2:
		nmm = venus_mesh_maker.instantiate()
	elif global.generate_type == 1:
		nmm = mercury_mesh_maker.instantiate()
	elif global.generate_type == 6:
		nmm = jupiter_mesh_maker.instantiate()
	elif global.generate_type == 7:
		nmm = saturn_mesh_maker.instantiate()
	elif global.generate_type == 8:
		nmm = uranus_mesh_maker.instantiate()
	elif global.generate_type == 9:
		nmm = neptune_mesh_maker.instantiate()
	elif global.generate_type == 10:
		nmm = pluto_mesh_maker.instantiate()
	elif global.generate_type == 11:
		nmm = watermelon_mesh_maker.instantiate()
	else:
		nmm = new_mesh_maker.instantiate()
	nmm.build_planet = true
	mesh_maker = nmm ### why did i do it like this? why does this work?
	ready_for_nmm = true


func _on_resume_button_up():
	var ufo = get_tree().get_first_node_in_group('ufo')
	ufo.reparent(self, false)
	ufo.in_browser = false
	ufo.browser_drop_off_begin = false
	global.ufo_reset = true
	for n in get_tree().get_nodes_in_group('pieces'):
		n.queue_free()
	for n in get_tree().get_nodes_in_group("title_pieces"):
		n.queue_free()
	for n in pieces.get_children():
		n.queue_free()
	global._load_saved_puzzle()


func _on_ufo_ufo_take_me_home():
	var ufo = get_tree().get_first_node_in_group('ufo')
	ufo.reparent(self, false)


func _on_pieces_child_entered_tree(node):
	if node.get_parent() == pieces:
		emit_signal("piece_added")


func _on_universe_rect_gui_input(event):
	if event is InputEventScreenDrag:
		fling = false
		dx = event.relative.x * h_sensitivity * global.sensitivity_multiplier
		dy = event.relative.y * v_sensitivity * global.sensitivity_multiplier
		if !drag:
			#first touch
			pass
		else:
			pass
		drag = true
		if is_equal_approx($h/v.rotation.x, -(15*PI)/32) or $h/v.rotation.x < -(15*PI)/32:
			if dy_final > 0.0:
				#print('uplimit')
				upper_limit_reached = true
				limit_pull += abs(dy_final)
		else:
			#limit_pull = 0.0
			upper_limit_reached = false
		if is_equal_approx($h/v.rotation.x, (15*PI)/32) or $h/v.rotation.x > (15*PI)/32:
			if dy_final < 0.0:
				#print('downlimit')
				lower_limit_reached = true
				limit_pull += abs(dy_final)
		else:
			#limit_pull = 0.0
			lower_limit_reached = false
	if event is InputEventScreenTouch:
		if event.pressed == false:
			drag = false
			if limit_pull > 0.0 and abs($h/v.rotation.x) > (15*PI)/32:
				#print('fling')
				if global.vibration:
					Input.vibrate_handheld(8)
				if global.sound:
					error_sound.play()
				fling = true


func _on_global_redo_atmosphere():
	_atmo_change()


func _on_global_loaded_pieces_ready(data):
	global.atmo_type = global.generate_type
	if global.generate_type == 7:
		rings.visible = true
	else:
		rings.visible = false
	var pieces_tracked: Dictionary = data[0]
	var loaded_pieces_data: Dictionary = data[1]
	var ufo_locations = {}
	var new_circle_idx := 0
	
	for i in loaded_pieces_data.keys():
		var newpiece = piece.instantiate()
		var piece_dict = loaded_pieces_data[i]
		newpiece.random_rotation_offset = piece_dict["random_rotation_offset"]
		newpiece.vertex = piece_dict["vertex"]
		newpiece.normal = piece_dict["normal"]
		newpiece.color = piece_dict["color"]
		newpiece.direction = piece_dict["direction"]
		newpiece.trees_on = piece_dict["trees_on"]
		newpiece.tree_positions = piece_dict["tree_positions"]
		newpiece.ocean = piece_dict["ocean"]
		newpiece.vertex_cw = piece_dict["vertex_cw"]
		newpiece.normal_cw = piece_dict["normal_cw"]
		newpiece.color_cw = piece_dict["color_cw"]
		newpiece.vertex_w = piece_dict["vertex_w"]
		newpiece.normal_w = piece_dict["normal_w"]
		newpiece.color_w = piece_dict["color_w"]
		newpiece.planet_style = piece_dict["planet_style"]
		newpiece.wall_vertex = piece_dict["wall_vertex"]
		newpiece.wall_normal = piece_dict["wall_normal"]
		newpiece.wall_color = piece_dict["wall_color"]
		newpiece.offset = piece_dict["offset"]
		newpiece.lat = piece_dict["lat"]
		newpiece.lon = piece_dict["lon"]
		newpiece.orient_upright = piece_dict["orient_upright"]
		newpiece.idx = piece_dict["idx"]
		newpiece.particle_edges = piece_dict["particle_edges"]
		
		if not pieces_tracked[i]:
			newpiece.remove_from_group("pieces")
		else:
			newpiece.circle_idx = new_circle_idx
			new_circle_idx += 1
			ufo_locations[i] = piece_dict["direction"]
		
		pieces.add_child(newpiece)
	global.ufo_locations = ufo_locations
	global.ready_to_start = true


func _on_global_wheel_rot_signal(rot):
	var the_rot = fmod(abs(rot), 2*PI)
	if the_rot < (0.0 + (PI/32)) or the_rot > ((2*PI) - (PI/32)):
		correct_rotation = true
	else:
		correct_rotation = false


func _piece_fit(delta):
	if current_piece.global_position.normalized().angle_to(current_piece.direction.normalized()) < PI/32:
		if global.rotation:
			if correct_rotation:
				fit_timer += delta
			else:
				fit_timer = 0.0
		else:
			fit_timer += delta
	else:
		fit_timer = 0.0


func _place_piece():
	global.browser_node.pieces_ready = false
	current_piece.reparent(pieces, false)
	current_piece.position = Vector3.ZERO
	current_piece.rotation = Vector3.ZERO
	current_piece_mesh.rotation = Vector3.ZERO
	current_piece.global_position = piece_target.global_position
	current_piece.placed = true
	looking = false
	fit_timer = 0.0
	global.pieces_placed_so_far[0] += 1
	print(global.pieces_placed_so_far)
	global._save_puzzle_status()


func _load_title_planet():
	var node_data: Dictionary = global.title_planet.node_data
	var new_circle_idx := 0
	global.atmo_type = global.title_planet.planet_style
	if global.title_planet.planet_style == 7:
		rings.visible = true
	for i in node_data.keys():
		var newpiece = piece.instantiate()
		var piece_dict = node_data[i]
		newpiece.random_rotation_offset = piece_dict["random_rotation_offset"]
		newpiece.vertex = piece_dict["vertex"]
		newpiece.normal = piece_dict["normal"]
		newpiece.color = piece_dict["color"]
		newpiece.direction = piece_dict["direction"]
		newpiece.trees_on = piece_dict["trees_on"]
		newpiece.tree_positions = piece_dict["tree_positions"]
		newpiece.ocean = piece_dict["ocean"]
		newpiece.vertex_cw = piece_dict["vertex_cw"]
		newpiece.normal_cw = piece_dict["normal_cw"]
		newpiece.color_cw = piece_dict["color_cw"]
		newpiece.vertex_w = piece_dict["vertex_w"]
		newpiece.normal_w = piece_dict["normal_w"]
		newpiece.color_w = piece_dict["color_w"]
		newpiece.planet_style = piece_dict["planet_style"]
		newpiece.wall_vertex = piece_dict["wall_vertex"]
		newpiece.wall_normal = piece_dict["wall_normal"]
		newpiece.wall_color = piece_dict["wall_color"]
		newpiece.offset = piece_dict["offset"]
		newpiece.lat = piece_dict["lat"]
		newpiece.lon = piece_dict["lon"]
		newpiece.orient_upright = piece_dict["orient_upright"]
		newpiece.idx = piece_dict["idx"]
		newpiece.particle_edges = piece_dict["particle_edges"]
		#newpiece.ready_for_launch.connect(_on_ready_for_launch)
		newpiece.remove_from_group("pieces")
		newpiece.add_to_group("title_pieces")
		pieces.add_child(newpiece)


func _on_piece_target_child_entered_tree(node):
	if node.is_in_group("pieces"):
		current_piece = node
		current_piece_mesh = current_piece.get_child(0)
		current_piece.in_space = true
		looking = true
		print("piece_target child entered")


func _on_piece_target_child_exiting_tree(node):
	if node.is_in_group("pieces"):
		current_piece.in_space = false
		looking = false
		print("piece_target child exited")


func _scan_v(delta, speed := 1.0):
	vertical_scan -= delta * speed
	emit_signal("vscan", vertical_scan)
	if vertical_scan <= -1.0:
		scanning = false
		vertical_scan = 1.0


func _on_global_puzzle_done():
	puzzle_done_effect.start()


func _on_puzzle_done_effect_timeout():
	scanning = true


func _on_global_title_planet_ready():
	_load_title_planet()
