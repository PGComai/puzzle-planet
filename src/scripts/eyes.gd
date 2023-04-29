extends Node3D

signal meshes_made2
signal piece_placed2

@onready var camera_3d = $h/v/Camera3D
@onready var sub_viewport = $".."
@onready var current = $current
@onready var initial = $initial
@onready var intermediate = $intermediate

var rot_h = 0.0
var rot_v = 0.0
var v_min = -rad_to_deg((15.0*PI)/32.0)
var v_max = rad_to_deg((15.0*PI)/32.0)
var h_sensitivity = 0.5
var v_sensitivity = 0.5
var h_acc
var v_acc

var erx = 0.0
var ery = 0.0
var drag = false
var vel := Vector2()
var vel_sens = 0.1

var h: int

var upper_limit_reached := false
var lower_limit_reached := false
var limit_pull := 0.0
var fling := false

var generate_type := 1

var initial_grab := Vector3()
var current_grab := Vector3()
var dx := 0.0
var dy := 0.0

func _ready():
	#Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED)
	h = sub_viewport.size.y
	
func _unhandled_input(event):
	if event is InputEventScreenDrag:
		fling = false
		var touchborder = h# + v_split.split_offset - 15
		#print(touchborder)
		if event.position.y < touchborder:
			if !drag:
				var presult = pointer(1)
				if presult:
					initial_grab = presult[1]
			else:
				var presult = pointer(1)
				if presult:
					current_grab = presult[1]
			drag = true
			if is_equal_approx($h/v.rotation.x, -(15*PI)/32) or $h/v.rotation.x < -(15*PI)/32:
				if dy > 0.0:
					#print('uplimit')
					upper_limit_reached = true
					limit_pull += abs(dy)
			else:
				#limit_pull = 0.0
				upper_limit_reached = false
			if is_equal_approx($h/v.rotation.x, (15*PI)/32) or $h/v.rotation.x > (15*PI)/32:
				if dy < 0.0:
					#print('downlimit')
					lower_limit_reached = true
					limit_pull += abs(dy)
			else:
				#limit_pull = 0.0
				lower_limit_reached = false
	if event is InputEventScreenTouch:
		if event.pressed == false:
			drag = false
			if limit_pull > 0.0 and abs($h/v.rotation.x) > (15*PI)/32:
				#print('fling')
				fling = true
				
func _physics_process(delta):
	#print(dy)
	#print($h.basis.z.angle_to(current_grab))
	#print(initial_grab.angle_to(current_grab))
	if $h/v.rotation.x > -(15*PI)/32:
		upper_limit_reached = false
	if $h/v.rotation.x < (15*PI)/32:
		lower_limit_reached = false
	limit_pull = clamp(limit_pull, 0.0, 20.0)
	var fling_strength = remap(limit_pull, 0.0, 20.0, 0.0, 1.0)
	#print(limit_pull)
	if not drag:
		initial_grab = initial_grab.slerp(current_grab, 0.1)
		if fling:
			if upper_limit_reached:
				dy = -fling_strength
			if lower_limit_reached:
				dy = fling_strength
			fling = false
			limit_pull = 0.0
	else:
		var presult = pointer(1)
		if presult:
			current_grab = presult[1]
		pass
	if upper_limit_reached or lower_limit_reached:
		pass
		print('limit')
	else:
		limit_pull = 0.0
	initial.position = initial_grab
	current.position = current_grab
	var intermediate_grab = initial_grab.slerp(current_grab, 0.1)
	intermediate.position = intermediate_grab
	dx = Vector3(initial_grab.x, 0.0, initial_grab.z).normalized().signed_angle_to(Vector3(intermediate_grab.x, 0.0, intermediate_grab.z).normalized(), Vector3.UP)
	dy = asin(initial_grab.normalized().y) - asin(intermediate_grab.normalized().y)
	if is_equal_approx(dx, 0.0):
		dx = 0.0
	if is_equal_approx(dy, 0.0):
		dy = 0.0
	print(camera_3d.global_position.normalized().dot(current_grab.normalized()))
	rot_h -= dx
	if $h/v.rotation.x > (15*PI)/32 and dy < 0.0:
		dy /= remap($h/v.rotation.x, (15*PI)/32, PI/2, 2.0, 10.0)
	elif $h/v.rotation.x < -(15*PI)/32 and dy > 0.0:
		dy /= remap(abs($h/v.rotation.x), (15*PI)/32, PI/2, 2.0, 10.0)
	rot_v -= dy

	if fling:
		pass
	
	if upper_limit_reached:
		rot_v = clamp(rot_v, -rad_to_deg(PI/2), v_max)
	elif lower_limit_reached:
		rot_v = clamp(rot_v, v_min, rad_to_deg(PI/2))
	else:
		rot_v = clamp(rot_v, v_min, v_max)
		
	#print(rot_v)
	
	$h.rotation.y = lerp_angle($h.rotation.y, rot_h, 1.0)
	$h/v.rotation.x = lerp_angle($h/v.rotation.x, rot_v, 1.0)
	
func pointer(coll_layer: int):
	var spaceState = get_world_3d().direct_space_state
	var mousePos = get_viewport().get_mouse_position()
	var rayStart = camera_3d.project_ray_origin(mousePos)
	var rayEnd = rayStart + camera_3d.project_ray_normal(mousePos) * 2000
	var query = PhysicsRayQueryParameters3D.create(rayStart, rayEnd, coll_layer)
	var rayDict = spaceState.intersect_ray(query)

	if rayDict.has('position'):
		return [rayDict['position'],rayDict['normal']]
	return null

func _on_mesh_maker_meshes_made():
	emit_signal("meshes_made2")

func _on_mesh_maker_piece_placed(cidx):
	emit_signal("piece_placed2", cidx)

func _on_generate_button_up():
	var error = get_tree().reload_current_scene()
	print(error)

func _on_option_button_item_selected(index):
	var global = get_node('/root/Global')
	if index == 0:
		global.generate_type = 1
	elif index == 1:
		global.generate_type = 2
