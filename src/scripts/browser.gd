extends Node3D

signal found_you(idx)
signal picked_you(idx)

@onready var orbit = $Orbit
@onready var camrot = $camrot
@onready var ux = $"../../../../../../.."
@onready var camera_3d = $camrot/Camera3D
var global

var rot_h = 0.0
var h_sensitivity = 0.004
var v_sensitivity = 0.004
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
var counter = 0
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

# Called when the node enters the scene tree for the first time.
func _ready():
	global = get_node('/root/Global')
	camera_3d.position.z = cam_dist
	h_sensitivity *= 180.0/self.get_viewport().get_visible_rect().size.x
	v_sensitivity *= 180.0/self.get_viewport().get_visible_rect().size.x
	#h_sensitivity *= global.pieces_at_start/15.0
	og_sens = h_sensitivity

func _unhandled_input(event):
	if event is InputEventScreenDrag:
		if event.position.y > 0.0:
			holding = true
			drag = true
			dx = event.relative.x * h_sensitivity
			dy = event.relative.y * v_sensitivity
			if abs(dx) > abs(dy):
				dy = 0.0
			elif abs(dx) <= abs(dy):
				dx = 0.0
		else:
			holding = false
			drag = false
	if event is InputEventScreenTouch:
		if event.pressed == false:
			if !holding:
				if event.position.y > 0.0:
					# this is where we pick a piece
					if piecelocs.has(front_piece):
						piece_in_space = true
						emit_signal("picked_you", piecelocs[front_piece])
						stay_at_angle = front_piece
			elif dy_final < -0.02 and abs(dx_final) < 0.02 and !piece_in_space:
				if piecelocs.has(front_piece):
					piece_in_space = true
					emit_signal("picked_you", piecelocs[front_piece])
					stay_at_angle = front_piece
			elif dy_final > 0.02 and abs(dx_final) < 0.02 and piece_in_space:
				if piecelocs.has(front_piece):
					emit_signal("picked_you", piecelocs[front_piece])
					stay_at_angle = front_piece
			holding = false
			pick = false
		elif event.pressed == true:
			pick = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if puzzle_done:
		pass
	else:
		#print(piece_in_space)
		if piece_in_space:
			dx = 0.0
			rot_h = lerp_angle(rot_h, stay_at_angle, 0.1)
			camrot.rotation.y = rot_h
		if drag:
			if abs(dx) < 0.01:
				dx = lerp(dx, 0.0, 0.1)
			snap_ease = 0.0
			dx_acc.append(dx)
			if len(dx_acc) > 5:
				dx_acc.remove_at(0)
			dx_final = dx_acc.reduce(func(accum, number): return accum + number, 0)/5
			dy_acc.append(dy)
			if len(dy_acc) > 5:
				dy_acc.remove_at(0)
			dy_final = dy_acc.reduce(func(accum, number): return accum + number, 0)/5
			rot_h -= dx_final
			if rot_h < 0.0:
				rot_h = 2*PI-abs(rot_h)
			camrot.rotation.y = rot_h
		if !drag and !holding:
			if len(dx_acc) > 0:
				dx_acc.remove_at(0)
			if len(dy_acc) > 0:
				dy_acc.remove_at(0)
			dx_final = lerp(dx_final, 0.0, 0.05)
			dy_final = lerp(dy_final, 0.0, 0.05)
			snap_ease = lerp(snap_ease, 5.0, 0.01)
			dx = lerp(dx, 0.0, 0.01)
			dy = lerp(dy, 0.0, 0.01)
			rot_h -= dx
			if rot_h < 0.0:
				rot_h = 2*PI-abs(rot_h)
			if rot_h >= 2*PI:
				rot_h -= 2*PI
			#snap_to = snappedf(rot_h, 2*PI/rotosnaps)
			rot_h = lerp_angle(rot_h, snap_to, 0.03*snap_ease*(1.0+(1.0-spin_speed)))
			camrot.rotation.y = rot_h
			front_piece = snappedf(snap_to, 0.01)
			if front_piece == 6.28:
				front_piece = 0.0
			if piecelocs.has(front_piece):
				emit_signal("found_you", piecelocs[front_piece])
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
		snap_to = snappedf(rot_h, 2*PI/rotosnaps)
		how_close_to_piece = abs(rot_h-snap_to) * 50.0
		spin_speed = abs(dx_final) * 100.0
		if how_close_to_piece < 0.001:
			how_close_to_piece = 0.0
		if spin_speed < 0.001:
			spin_speed = 0.0
		spin_speed = clamp(spin_speed, 0.0, 1.0)
#		if how_close_to_piece < 0.3:
		#print(1.0+(1.0-spin_speed))
		drag = false
		if is_equal_approx(dx, 0.0):
			dx = 0.0
		if is_equal_approx(dy, 0.0):
			dy = 0.0
			
func _on_universe_meshes_made_2():
	var pieces = get_tree().get_nodes_in_group('pieces')
	rotosnaps = len(pieces)
	max_rotosnaps = rotosnaps
	cam_dist = remap(float(rotosnaps), 20.0, 40.0, 5.0, 10.0) + 0.8
	#print(rotosnaps)
	var ang = (2*PI)/rotosnaps
	for r in rotosnaps:
		snaps.append(ang*(r))
	for p in pieces:
		p.reparent(self, false)
		p.i_am_here.connect(_on_i_am_here)
		p.take_me_home.connect(_on_take_me_home)
		p.arrange()
		
func _on_i_am_here(idx, ang):
	piecelocs[ang] = idx
	
func _on_take_me_home(idx):
	var pieces = get_tree().get_nodes_in_group('pieces')
	for p in pieces:
		if p.idx == idx:
			p.reparent(self, false)
			p.in_space = false
			p.back_from_space = true
			piece_in_space = false

func _on_universe_piece_placed_2(cidx):
	piece_in_space = false
	snaps = []
	var pieces = get_tree().get_nodes_in_group('pieces')
	rotosnaps = len(pieces)
	if rotosnaps == 0:
		puzzle_done = true
		print('done')
	else:
		h_sensitivity = og_sens * (float(max_rotosnaps)/float(rotosnaps))
		print(float(max_rotosnaps)/float(rotosnaps))
		cam_dist = remap(float(rotosnaps), 20.0, 40.0, 5.0, 10.0) + 0.8
		recam = true
		#print(rotosnaps)
		var ang = (2*PI)/rotosnaps
		for r in rotosnaps:
			snaps.append(ang*(r))
		for p in pieces:
			if p.circle_idx > cidx:
				p.circle_idx -= 1
			#p.rearrange_offset = p.circle_idx - cidx
			p.arrange(true)
