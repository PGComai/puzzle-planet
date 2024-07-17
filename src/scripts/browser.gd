extends Node3D

signal found_you(idx)
signal picked_you(idx)
signal click(speed)
signal ufo_at_angle(angle, pos)
signal light_toggle(energy)
signal env_toggle(energy)

@onready var camrot = $camrot
@onready var camera_3d = $camrot/Camera3D
@onready var wheel = $camrot/Camera3D/wheel
@onready var wheelmesh = $camrot/Camera3D/wheel/wheelmesh
@onready var audio_stream_player = $AudioStreamPlayer
@onready var ufo_orbit = $UFO_orbit

const LIGHT_ENERGY := 1.0
const BONUS_CAM_DIST := 1.0

var global
var piece_rotation := false

var rot_h = 0.0
var h_sensitivity = 0.0008
var v_sensitivity = 0.0008
var og_sens: float
var dx_final := 0.0
var dy_final := 0.0

var dx = 0.0
var dy = 0.0
var drag = false
var dx_acc = []
var dy_acc = []
var tposy: float

var rotosnaps: int
var max_rotosnaps: int
var snaps = []
var snap_ease = 0.0
var piecelocs: Dictionary
var picktimer = 0.0
var pick = false
var release_ready = false
var releasetimer = 0.0

var stopped = true
var front_piece: float

var cam_dist = 0.0

var momentum := 0.0
var hold_timer := 0.0
var holding := false

var recam := false
var puzzle_done := false
var roto_ratio := 1.0
var snap_to := 0.0
var vibrate_strength := 0.0

var piece_in_space := false
var stay_at_angle := 0.0
var spin_speed := 0.0
var how_close_to_piece := 0.0

var first_touch := 0.0
var first_touch_too_low := false

var clicked := false
var holding_top := false

var chosen_piece_rotation := 0.0

var last_frame_snap_to := 0.0
var disable_click := false

var rotating := false

var pieces_ready := false

var wheel_moving := false
var ufo_come_drop_off := false
var wheel_up := true
var light_toggle_complete := false

# Called when the node enters the scene tree for the first time.
func _ready():
	global = get_node('/root/Global')
	global.browser_node = self
	global.piece_placed.connect(_on_global_piece_placed)
	global.ufo_done_signal.connect(_on_global_ufo_done_signal)
	global.num_pieces_arranged_changed.connect(_on_global_num_arranged_changed)
	global.wheel_target_rot_set.connect(_on_global_wheel_target_rot_set)
	piece_rotation = global.rotation
	camera_3d.position.z = cam_dist
	og_sens = h_sensitivity

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if puzzle_done:
		if !wheel_up:
			toggle_wheel('up')
	elif !pieces_ready:
		if recam:
			camera_3d.position.z = lerp(camera_3d.position.z, cam_dist, 0.05)
			if is_equal_approx(camera_3d.position.z, cam_dist):
				camera_3d.position.z = cam_dist
				recam = false
				print("recam ended")
	else:
		if drag:
			if abs(dx) < 0.01:
				dx = lerp(dx, 0.0, 0.1)
			if abs(dy) < 0.01:
				dy = lerp(dy, 0.0, 0.1)
			snap_ease = 0.0
			dx_acc.append(dx)
			if len(dx_acc) > 5:
				dx_acc.remove_at(0)
			dx_final = dx_acc.reduce(func(accum, number): return accum + number, 0)/5
			dy_acc.append(dy)
			if len(dy_acc) > 5:
				dy_acc.remove_at(0)
			dy_final = dy_acc.reduce(func(accum, number): return accum + number, 0)/5
		else:
			if len(dx_acc) > 0:
				dx_acc.remove_at(0)
			if len(dy_acc) > 0:
				dy_acc.remove_at(0)
			dx_final = lerp(dx_final, 0.0, 0.05)
			dy_final = lerp(dy_final, 0.0, 0.05)
			snap_ease = lerp(snap_ease, 5.0, 0.01)
			front_piece = snappedf(snap_to, 0.01)
			if front_piece == 6.28:
				front_piece = 0.0
			if piecelocs.has(front_piece):
				emit_signal("found_you", piecelocs[front_piece])
		if global.placing_piece:
			if global.rotation:
				rotating = true
				toggle_wheel('down')
				wheelmesh.rotation.z += dx_final
				global.wheel_rot =  wheelmesh.rotation.z
			else:
				dx = 0.0
			rot_h = lerp_angle(rot_h, stay_at_angle, 0.1)
			camrot.rotation.y = rot_h
			#_toggle_light(false)
		else:
			rotating = false
			if global.rotation:
				toggle_wheel('up')
			rot_h -= dx_final
			#_toggle_light(true)
		if rot_h < 0.0:
			rot_h = 2*PI-abs(rot_h)
		if rot_h >= 2*PI:
			rot_h -= 2*PI
		if !holding:
			rot_h = lerp_angle(rot_h, snap_to, 0.03*snap_ease*(1.0-spin_speed))
		camrot.rotation.y = rot_h
		if pick:
			picktimer += delta
			if picktimer > 0.05 and !drag:
				picktimer = 0.0
				pick = false
		if recam:
			camera_3d.position.z = lerp(camera_3d.position.z, cam_dist, 0.05)
			if is_equal_approx(camera_3d.position.z, cam_dist):
				camera_3d.position.z = cam_dist
				recam = false
				print("recam ended")
		snap_to = snappedf(rot_h, 2*PI/rotosnaps)
		#print(snap_to)
		how_close_to_piece = clamp(abs(rot_h-snap_to) * 50.0, 0.0, 10.1)
		spin_speed = abs(dx_final) * 100.0
		if how_close_to_piece < 0.001:
			how_close_to_piece = 0.0
		if spin_speed < 0.001:
			spin_speed = 0.0
		spin_speed = clamp(spin_speed, 0.0, 1.0)
		if !is_equal_approx(last_frame_snap_to, snap_to) and !(is_equal_approx(last_frame_snap_to, 2*PI) and is_equal_approx(snap_to, 0.0)) and !(is_equal_approx(snap_to, 2*PI) and is_equal_approx(last_frame_snap_to, 0.0)) and !disable_click:
			print("click")
			var click_force = remap(clamp(abs(dx_final), 0.01, 0.1), 0.01, 0.1, 1.0, 1.2)
			emit_signal("click", click_force)
		drag = false
		if is_equal_approx(dx, 0.0):
			dx = 0.0
		if is_equal_approx(dy, 0.0):
			dy = 0.0
		
		last_frame_snap_to = snap_to


func _on_this_is_my_rotation(rot):
	wheelmesh.rotation.z = rot


func _on_i_am_here(idx, ang):
	piecelocs[ang] = idx


func _on_global_piece_placed(cidx):
	print("browser piece placed func")
	#global.num_pieces_arranged = 0
#	pieces_ready = false
	if global.rotation:
		wheel_moving = true
	disable_click = true
	piece_in_space = false
	snaps = []
	var pieces = get_tree().get_nodes_in_group('pieces')
	rotosnaps = len(pieces)
	if rotosnaps == 0:
		global.puzzle_finished = true
		puzzle_done = true
	else:
		piecelocs = {}
		h_sensitivity = og_sens * (float(max_rotosnaps)/float(rotosnaps))
		cam_dist = remap(float(rotosnaps), 20.0, 40.0, 5.0, 10.0) + BONUS_CAM_DIST
		var ang = (2*PI)/rotosnaps
		for r in rotosnaps:
			snaps.append(ang*(r))
		recam = true
		print("recam started")
#		for p in pieces:
#			if p.circle_idx > cidx:
#				p.circle_idx -= 1
#			p.arrange(true)


func _resetti_spaghetti(set_rot := true):
	ufo_come_drop_off = false
	ufo_orbit.spin = false
	ufo_orbit.past_halfway = false
	ufo_orbit.rotation = Vector3.ZERO
	rot_h = 0.0
	camrot.rotation = Vector3.ZERO
	piece_in_space = false
	pieces_ready = false
	puzzle_done = false
	piecelocs = {}
	snaps = []
	snap_to = 0.0
	if set_rot:
		piece_rotation = global.rotation
	h_sensitivity = og_sens
	camera_3d.position.y = 0.0
	wheel.position.y = 12.0
	wheel_moving = false
	wheel_up = true
	emit_signal("light_toggle", 0.0)
	emit_signal("env_toggle", 0.0)


func toggle_wheel(direction := 'down'):
	if wheel_moving:
		if direction == 'down':
			camera_3d.position.y = lerp(camera_3d.position.y, 1.5, 0.1)
			wheel.position.y = lerp(wheel.position.y, 5.636, 0.1)
			if is_equal_approx(camera_3d.position.y, 1.5) and is_equal_approx(wheel.position.y, 5.636):
				camera_3d.position.y = 1.5
				wheel.position.y = 5.636
				wheel_moving = false
				wheel_up = false
		else:
			camera_3d.position.y = lerp(camera_3d.position.y, 0.0, 0.1)
			wheelmesh.rotation.z = 0.0
			wheel.position.y = lerp(wheel.position.y, 12.0, 0.1)
			if is_equal_approx(camera_3d.position.y, 0.0) and is_equal_approx(wheel.position.y, 12.0):
				camera_3d.position.y = 0.0
				wheel.position.y = 12.0
				wheel_moving = false
				wheel_up = true


func _on_picked_you(idx):
	dx = 0.0
	dx_final = 0.0
	dx_acc = []
	if global.rotation:
		wheel_moving = true


func _on_global_ufo_done_signal():
	global.placing_piece = false
	global.num_pieces_arranged = 0
	#pieces_ready = true
	var pieces = get_tree().get_nodes_in_group('pieces')
	rotosnaps = len(pieces)
	max_rotosnaps = rotosnaps
	#h_sensitivity *= max_rotosnaps/float(rotosnaps) ### sensitivity issue
	#print(rotosnaps)
	cam_dist = remap(float(rotosnaps), 20.0, 40.0, 5.0, 10.0) + BONUS_CAM_DIST
	#recam = true
	camera_3d.position.z = cam_dist
	var ang = (2*PI)/rotosnaps
	#h_sensitivity = og_sens
	#print(rotosnaps)
	for r in rotosnaps:
		snaps.append(ang*(r))
	print(snaps)
	for p in pieces:
		p.reparent(self, false)
		p.i_am_here.connect(_on_i_am_here)
		#p.take_me_home.connect(_on_take_me_home)
		p.this_is_my_rotation.connect(_on_this_is_my_rotation)
		p.drop_off_original_dist = cam_dist
		p.visible = true
		p.arrange()
	emit_signal("light_toggle", 1.0)
	emit_signal("env_toggle", 0.58)


func _on_generate_button_up():
	_resetti_spaghetti()


func _on_resume_button_up():
	_resetti_spaghetti(false)


func _on_ufo_take_me_home():
	var pieces = get_tree().get_nodes_in_group('pieces')
	for p in pieces:
		p.visible = true


func _on_ufo_orbit_at_angle(angle, pos):
	if angle < 0.0:
		angle = (PI - abs(angle)) + PI
	angle += PI
	if angle >= 2.0*PI:
		angle -= 2.0*PI
	var ufo_snap_to = snappedf(angle, 2*PI/rotosnaps)
	emit_signal("ufo_at_angle", ufo_snap_to, pos)


func _on_ufo_orbit_drop_off_done():
	pieces_ready = true


func _on_browser_rect_gui_input(event):
	if pieces_ready:
		if event is InputEventScreenDrag:
			disable_click = false
			holding_top = false
			holding = true
			drag = true
			if !rotating:
				dx = event.relative.x * h_sensitivity * global.sensitivity_multiplier
			else:
				dx = event.relative.x * og_sens * global.sensitivity_multiplier
			dy = event.relative.y * v_sensitivity * global.sensitivity_multiplier
			if abs(dx) > abs(dy):
				dy = 0.0
			elif abs(dx) <= abs(dy):
				dx = 0.0
		if event is InputEventScreenTouch:
			if event.pressed == false:
				if !holding:
					if piecelocs.has(front_piece):
						emit_signal("picked_you", piecelocs[front_piece])
						stay_at_angle = front_piece
				elif dy_final < -0.01 and abs(dx_final) < 0.02 and !global.placing_piece:
					# send to space
					if piecelocs.has(front_piece):
						emit_signal("picked_you", piecelocs[front_piece])
						stay_at_angle = front_piece
				elif dy_final > 0.01 and abs(dx_final) < 0.02 and global.placing_piece:
					# return from space
					if piecelocs.has(front_piece):
						emit_signal("picked_you", piecelocs[front_piece])
						stay_at_angle = front_piece
				holding_top = false
				holding = false
				pick = false
			elif event.pressed == true:
				pick = true


func _on_global_num_arranged_changed(num):
	#var numstr := str(num)
	#print(numstr + " pieces arranged out of %s" %get_tree().get_nodes_in_group("pieces").size())
	if num == get_tree().get_nodes_in_group("pieces").size():
		pieces_ready = true
		print("pieces arranged")


func _on_global_wheel_target_rot_set(rot):
	wheelmesh.rotation.z = rot
