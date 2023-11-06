extends Node3D

signal piece_added
signal rotation_music_multiplier(multi)
signal no_pitch_mod

@export var h_sensitivity = 0.001
@export var v_sensitivity = 0.001

@onready var camera_3d = $h/v/Camera3D
@onready var piece_target = $h/v/Camera3D/piece_target
@onready var mesh_maker = $MeshMaker
@onready var pieces = $Pieces
@onready var new_mesh_maker = preload("res://scenes/mesh_maker.tscn")
@onready var sun = $Sun
@onready var space = $Space
@onready var shadow_light = $h/v/Camera3D/ShadowLight
@onready var roto_window = $"../../RotoWindow"
@onready var atmosphere = $Atmosphere
@onready var error_sound = $ErrorSound

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

func _ready():
	global = get_node('/root/Global')
	global.drawing_mode_changed.connect(_on_global_drawing_mode_changed)
	global.redo_atmosphere.connect(_on_global_redo_atmosphere)
	#Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED)
	#h = sub_viewport.size.y
	#h_sensitivity *= 180.0/self.get_viewport().get_visible_rect().size.x
	#v_sensitivity *= 180.0/self.get_viewport().get_visible_rect().size.x
#	RenderingServer.global_shader_parameter_set('atmo_daylight', Color('779ddc'))
#	RenderingServer.global_shader_parameter_set('atmo_sunset', Color('e5152a'))
	#generate_type = global.generate_type
	if global.title_screen:
		_atmo_change()

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


func _atmo_change():
	var type = global.atmo_type
	print("new atmosphere: %s" % type)
	if type == 3:
		atmosphere.visible = true
		RenderingServer.global_shader_parameter_set('atmo_fresnel_power', 2.178)
		RenderingServer.global_shader_parameter_set('atmo_daylight', Color('779ddc'))
		RenderingServer.global_shader_parameter_set('atmo_sunset', Color('e5152a'))
	elif type == 2:
		atmosphere.visible = true
		RenderingServer.global_shader_parameter_set('atmo_fresnel_power', 2.178)
		RenderingServer.global_shader_parameter_set('atmo_daylight', Color('b89679'))
		RenderingServer.global_shader_parameter_set('atmo_sunset', Color('b89679'))
	elif type == 5:
		atmosphere.visible = true
		RenderingServer.global_shader_parameter_set('atmo_fresnel_power', 3.2)
		RenderingServer.global_shader_parameter_set('atmo_daylight', Color('d4995a'))
		RenderingServer.global_shader_parameter_set('atmo_sunset', Color('81cfff'))
	elif type == 4 or type == 1 or type == 11:
		atmosphere.visible = false
		RenderingServer.global_shader_parameter_set('atmo_daylight', Color('black'))
		RenderingServer.global_shader_parameter_set('atmo_sunset', Color('black'))
	elif type == 6:
		atmosphere.visible = true
		RenderingServer.global_shader_parameter_set('atmo_fresnel_power', 4.0)
		RenderingServer.global_shader_parameter_set('atmo_daylight', Color('c5a37f'))
		RenderingServer.global_shader_parameter_set('atmo_sunset', Color('e2a277'))
	elif type == 7:
		atmosphere.visible = true
		RenderingServer.global_shader_parameter_set('atmo_fresnel_power', 4.0)
		RenderingServer.global_shader_parameter_set('atmo_daylight', Color('c5a37f'))
		RenderingServer.global_shader_parameter_set('atmo_sunset', Color('e2a277'))
	elif type == 8 or type == 9:
		atmosphere.visible = true
		RenderingServer.global_shader_parameter_set('atmo_fresnel_power', 2.3)
		RenderingServer.global_shader_parameter_set('atmo_daylight', Color('7a9cae'))
		RenderingServer.global_shader_parameter_set('atmo_sunset', Color('7a9cae'))
	elif type == 10:
		atmosphere.visible = true
		RenderingServer.global_shader_parameter_set('atmo_fresnel_power', 4.0)
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
	shadow_light._on = false
	sun._on = true
	global.piece_in_space = false
	space._on = false
	roto_window.visible = false
	mesh_maker.queue_free()
	for n in get_tree().get_nodes_in_group('pieces'):
		n.queue_free()
	for n in get_tree().get_nodes_in_group("title_pieces"):
		n.queue_free()
	for n in pieces.get_children():
		n.queue_free()
	#if global.generate_type != generate_type:
	_atmo_change()
	var nmm = new_mesh_maker.instantiate()
	nmm.build_planet = true
	mesh_maker = nmm ### why did i do it like this? why does this work?
	ready_for_nmm = true
	#last_type = generate_type
	#generate_type = global.generate_type


func _on_resume_button_up():
	var ufo = get_tree().get_first_node_in_group('ufo')
	ufo.reparent(self, false)
	ufo.in_browser = false
	ufo.browser_drop_off_begin = false
	global.ufo_reset = true
	shadow_light._on = false
	sun._on = true
	global.piece_in_space = false
	space._on = false
	roto_window.visible = false
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
		#var touchborder = h# + v_split.split_offset - 15
		#print(touchborder)
		if true:#event.position.y < touchborder:
			dx = event.relative.x * h_sensitivity
			dy = event.relative.y * v_sensitivity
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
		else:
			drag = false
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
