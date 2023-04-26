extends Node3D

signal meshes_made2
signal piece_placed2

@onready var camera_3d = $h/v/Camera3D
@onready var sub_viewport = $".."

var rot_h = 0.0
var rot_v = 0.0
var v_min = -rad_to_deg((15.0*PI)/32.0)
var v_max = rad_to_deg((15.0*PI)/32.0)
var h_sensitivity = 0.15
var v_sensitivity = 0.15
var h_acc
var v_acc

var erx = 0.0
var ery = 0.0
var drag = false
var erx_acc = []
var ery_acc = []

var h: int

var upper_limit_reached := false
var lower_limit_reached := false
var limit_pull := 0.0
var fling := false

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED)
	h = sub_viewport.size.y
	
func _unhandled_input(event):
#	if event is InputEventMouseMotion and click:
#		erx = event.relative.x * h_sensitivity
#		ery = event.relative.y * v_sensitivity
	if event is InputEventScreenDrag:
		fling = false
		var touchborder = h# + v_split.split_offset - 15
		#print(touchborder)
		if event.position.y < touchborder:
			drag = true
			erx = event.relative.x * h_sensitivity
			ery = event.relative.y * v_sensitivity
			if is_equal_approx($h/v.rotation.x, -(15*PI)/32) or $h/v.rotation.x < -(15*PI)/32:
				if event.relative.y > 0.0:
					#print('uplimit')
					upper_limit_reached = true
					limit_pull += abs(event.relative.y * v_sensitivity)
			else:
				#limit_pull = 0.0
				upper_limit_reached = false
			if is_equal_approx($h/v.rotation.x, (15*PI)/32) or $h/v.rotation.x > (15*PI)/32:
				if event.relative.y < 0.0:
					#print('downlimit')
					lower_limit_reached = true
					limit_pull += abs(event.relative.y * v_sensitivity)
			else:
				#limit_pull = 0.0
				lower_limit_reached = false
	if event is InputEventScreenTouch:
		if event.pressed == false:
			if limit_pull > 0.0 and abs($h/v.rotation.x) > (15*PI)/32:
				#print('fling')
				fling = true
				
func _process(delta):
	if $h/v.rotation.x > -(15*PI)/32:
		upper_limit_reached = false
	if $h/v.rotation.x < (15*PI)/32:
		lower_limit_reached = false
	limit_pull = clamp(limit_pull, 0.0, 20.0)
	var fling_strength = remap(limit_pull, 0.0, 20.0, 0.0, 1.0)
	#print(limit_pull)
	if not drag:
		erx = lerp(erx, 0.0, 0.03)
		ery = lerp(ery, 0.0, 0.03)
		erx_acc = []
		ery_acc = []
		if fling:
			if upper_limit_reached:
				ery = -fling_strength
			if lower_limit_reached:
				ery = fling_strength
			fling = false
			limit_pull = 0.0
	else:
		erx_acc.append(erx)
		if len(erx_acc) > 5:
			erx_acc.remove_at(0)
		ery_acc.append(ery)
		if len(ery_acc) > 5:
			ery_acc.remove_at(0)
		erx = erx_acc.reduce(func(accum, number): return accum + number, 0)/5
		ery = ery_acc.reduce(func(accum, number): return accum + number, 0)/5
	if upper_limit_reached or lower_limit_reached:
		pass
		#print('limit')
	else:
		limit_pull = 0.0
	rot_h -= erx
	if $h/v.rotation.x > (15*PI)/32 and ery < 0.0:
		ery /= remap($h/v.rotation.x, (15*PI)/32, PI/2, 2.0, 10.0)
	elif $h/v.rotation.x < -(15*PI)/32 and ery > 0.0:
		ery /= remap(abs($h/v.rotation.x), (15*PI)/32, PI/2, 2.0, 10.0)
	rot_v -= ery
	
	#print(ery)
	
	if fling:
		pass
	
	if upper_limit_reached:
		rot_v = clamp(rot_v, -rad_to_deg(PI/2), v_max)
	elif lower_limit_reached:
		rot_v = clamp(rot_v, v_min, rad_to_deg(PI/2))
	else:
		rot_v = clamp(rot_v, v_min, v_max)
		
	#print(rot_v)
	
	$h.rotation_degrees.y = rot_h
	$h/v.rotation_degrees.x = rot_v
	drag = false

func _on_mesh_maker_meshes_made():
	emit_signal("meshes_made2")

func _on_mesh_maker_piece_placed(cidx):
	emit_signal("piece_placed2", cidx)
