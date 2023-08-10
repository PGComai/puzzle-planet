extends Node3D

signal ufo_time
signal ufo_ready2(dict)
signal ufo_done2
signal ready_to_start2
signal meshes_made2
signal piece_placed2
signal spin_piece(rot)
signal ufo_abducting2(piece)
signal ufo_abduction_done2
signal ufo_reset
signal piece_added
signal atmo_resize(size)

@export var h_sensitivity = 0.005
@export var v_sensitivity = 0.005

@onready var camera_3d = $h/v/Camera3D
@onready var sub_viewport = $".."
@onready var piece_target = $h/v/Camera3D/piece_target
@onready var mesh_maker = $MeshMaker
@onready var pieces = $Pieces
@onready var new_mesh_maker = preload("res://scenes/mesh_maker.tscn")
@onready var browser = $"../../../../MarginContainer/AspectRatioContainer/SubViewportContainer/SubViewport/Browser"
@onready var sun = $Sun
@onready var space = $Space
@onready var shadow_light = $h/v/Camera3D/ShadowLight
@onready var rotowindow = $"../../../../../../RotoWindow"
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

var generate_type := 1
var last_type := 1

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
	#Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED)
	h = sub_viewport.size.y
	#h_sensitivity *= 180.0/self.get_viewport().get_visible_rect().size.x
	#v_sensitivity *= 180.0/self.get_viewport().get_visible_rect().size.x
	RenderingServer.global_shader_parameter_set('atmo_daylight', Color('779ddc'))
	RenderingServer.global_shader_parameter_set('atmo_sunset', Color('e5152a'))
	generate_type = global.generate_type
	
func _unhandled_input(event):
	if event is InputEventScreenDrag:
		fling = false
		var touchborder = h# + v_split.split_offset - 15
		#print(touchborder)
		if event.position.y < touchborder:
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
				
func _process(delta):
	if ready_for_nmm and len(get_tree().get_nodes_in_group('pieces')) == 0:
		add_child(mesh_maker)
		ready_for_nmm = false
	#print(dy)
	#print($h.basis.z.angle_to(current_grab))
	#print(initial_grab.angle_to(current_grab))
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
		dx_final = lerp(dx_final, 0.0, 0.05)
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
		
#	var rot_h_tick = fmod(abs(rot_h), PI/4.0)
#	var rot_v_tick = fmod(abs(rot_v), PI/4.0)
#	if (rot_h_tick >= PI/8.0 and last_rot_h_tick < PI/8.0) or (rot_h_tick <= PI/8.0 and last_rot_h_tick > PI/8.0):
#		Input.vibrate_handheld(3)
#	elif (rot_v_tick >= PI/8.0 and last_rot_v_tick < PI/8.0) or (rot_v_tick <= PI/8.0 and last_rot_v_tick > PI/8.0):
#		Input.vibrate_handheld(3)
#	last_rot_h_tick = rot_h_tick
#	last_rot_v_tick = rot_v_tick

	$h.rotation.y = rot_h
	$h/v.rotation.x = rot_v
	
func _atmo_change():
	if global.generate_type == 3:
		atmosphere.visible = true
		RenderingServer.global_shader_parameter_set('atmo_fresnel_power', 2.178)
		RenderingServer.global_shader_parameter_set('atmo_daylight', Color('779ddc'))
		RenderingServer.global_shader_parameter_set('atmo_sunset', Color('e5152a'))
	elif global.generate_type == 2:
		atmosphere.visible = true
		RenderingServer.global_shader_parameter_set('atmo_fresnel_power', 2.178)
		RenderingServer.global_shader_parameter_set('atmo_daylight', Color('b89679'))
		RenderingServer.global_shader_parameter_set('atmo_sunset', Color('b89679'))
	elif global.generate_type == 5:
		atmosphere.visible = true
		RenderingServer.global_shader_parameter_set('atmo_fresnel_power', 3.2)
		RenderingServer.global_shader_parameter_set('atmo_daylight', Color('d4995a'))
		RenderingServer.global_shader_parameter_set('atmo_sunset', Color('81cfff'))
	elif global.generate_type == 4 or global.generate_type == 1:
		atmosphere.visible = false
		RenderingServer.global_shader_parameter_set('atmo_daylight', Color('black'))
		RenderingServer.global_shader_parameter_set('atmo_sunset', Color('black'))
	elif global.generate_type == 6:
		atmosphere.visible = true
		RenderingServer.global_shader_parameter_set('atmo_fresnel_power', 4.0)
		RenderingServer.global_shader_parameter_set('atmo_daylight', Color('c5a37f'))
		RenderingServer.global_shader_parameter_set('atmo_sunset', Color('e2a277'))
	elif global.generate_type == 7:
		atmosphere.visible = true
		RenderingServer.global_shader_parameter_set('atmo_fresnel_power', 4.0)
		RenderingServer.global_shader_parameter_set('atmo_daylight', Color('c5a37f'))
		RenderingServer.global_shader_parameter_set('atmo_sunset', Color('e2a277'))
	elif global.generate_type == 8 or global.generate_type == 9:
		atmosphere.visible = true
		RenderingServer.global_shader_parameter_set('atmo_fresnel_power', 2.3)
		RenderingServer.global_shader_parameter_set('atmo_daylight', Color('7a9cae'))
		RenderingServer.global_shader_parameter_set('atmo_sunset', Color('7a9cae'))
		

func _on_mesh_maker_meshes_made():
	emit_signal("meshes_made2")

func _on_mesh_maker_piece_placed(cidx):
	emit_signal("piece_placed2", cidx)

func _on_generate_button_up():
	var ufo = get_tree().get_first_node_in_group('ufo')
	ufo.reparent(self, false)
	ufo.in_browser = false
	ufo.browser_drop_off_begin = false
	emit_signal("ufo_reset")
	shadow_light._on = false
	sun._on = true
	#sun_2._on = true
	space._on = false
	rotowindow.visible = false
	mesh_maker.queue_free()
	for n in get_tree().get_nodes_in_group('pieces'):
		n.queue_free()
	for n in pieces.get_children():
		n.queue_free()
	if global.generate_type != generate_type:
		_atmo_change()
	
	var nmm = new_mesh_maker.instantiate()
	nmm.connect('meshes_made', _on_mesh_maker_meshes_made)
	nmm.connect('piece_placed', _on_mesh_maker_piece_placed)
	nmm.connect('ready_to_start', _on_mesh_maker_ready_to_start)
	nmm.connect('ufo_ready', _on_mesh_maker_ufo_ready)
	mesh_maker = nmm
	ready_for_nmm = true
	last_type = generate_type
	generate_type = global.generate_type
	#var error = get_tree().reload_current_scene()
	#print(error)

func _on_option_button_item_selected(index):
	global.generate_type = index + 1

func _on_browser_wheel_rot(rot):
	emit_signal('spin_piece', rot)

func _on_mesh_maker_ready_to_start():
	emit_signal("ready_to_start2")

func _on_start_puzzle_button_up():
	emit_signal("ufo_time")

func _on_mesh_maker_ufo_ready(dict):
	emit_signal('ufo_ready2', dict)

func _on_ufo_ufo_done():
	emit_signal("ufo_done2")

func _on_ufo_ufo_abducting(piece, speed):
	emit_signal("ufo_abducting2", piece, speed)

func _on_ufo_ufo_abduction_done():
	emit_signal('ufo_abduction_done2')

func _on_ufo_ufo_take_me_home():
	var ufo = get_tree().get_first_node_in_group('ufo')
	ufo.reparent(self, false)

func _on_pieces_child_entered_tree(node):
	if node.get_parent() == pieces:
		emit_signal("piece_added")
