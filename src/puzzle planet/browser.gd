extends Node3D

signal found_you(idx)
signal picked_you(idx)

@onready var orbit = $Orbit
@onready var camrot = $camrot
@onready var v_split = $"../../../../.."
@onready var ux = $"../../../../../../.."
@onready var camera_3d = $camrot/Camera3D

var rot_h = 0.0
var h_sensitivity = 0.0004
var h_acc

var erx = 0.0
var drag = false
var erx_acc = []
var tposy: float

var rotosnaps: int
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
var slower = 1.0

var cam_dist = 0.0


# Called when the node enters the scene tree for the first time.
func _ready():
	camera_3d.position.z = cam_dist

func _unhandled_input(event):
	if event is InputEventScreenDrag:
		if event.position.y > 0.0:
			drag = true
			slower = 1.0
			stopped = false
			erx = event.relative.x * h_sensitivity
	if event is InputEventScreenTouch:
		slower = 1.0
		if event.pressed == false:
			if release_ready and releasetimer < 0.2 and stopped:
				if event.position.y > 0.0:
					# this is where we pick a piece
					if piecelocs.has(front_piece):
						emit_signal("picked_you", piecelocs[front_piece])
			else:
				if abs(erx) < 0.004 and not drag:
					slower = 4.0
			drag = false
			pick = false
			release_ready = false
			releasetimer = 0.0
		elif event.pressed == true:
			pick = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if drag:
		snap_ease = 0.0
		erx_acc.append(erx)
		if len(erx_acc) > 3:
			erx_acc.remove_at(0)
		erx = erx_acc.reduce(func(accum, number): return accum + number, 0)/3
		rot_h -= erx
		if rot_h < 0.0:
			rot_h = 2*PI-abs(rot_h)
		camrot.rotation.y = rot_h
	elif not drag:
		snap_ease = lerp(snap_ease, 20.0, 0.001)
		erx = lerp(erx, 0.0, 0.03)
		erx_acc = []
		rot_h -= erx
		if rot_h < 0.0:
			rot_h = 2*PI-abs(rot_h)
		if rot_h >= 2*PI:
			rot_h -= 2*PI
		var snap_to = snappedf(rot_h, 2*PI/rotosnaps)
		rot_h = lerp_angle(rot_h, snap_to, 0.01*snap_ease*slower)
		camrot.rotation.y = rot_h
		front_piece = snappedf(snap_to, 0.01)
		if front_piece == 6.28:
			front_piece = 0.0
		#print(piecelocs[front_piece])
		if piecelocs.has(front_piece):
			emit_signal("found_you", piecelocs[front_piece])
	if abs(erx) < 0.002:
		stopped = true
	else:
		stopped = false
	if pick:
		picktimer += delta
		if picktimer > 0.05 and !drag:
			picktimer = 0.0
			pick = false
			release_ready = true
	if release_ready:
		releasetimer += delta
			
func _on_universe_meshes_made_2():
	var pieces = get_tree().get_nodes_in_group('pieces')
	rotosnaps = len(pieces)
	cam_dist = remap(float(rotosnaps), 20.0, 40.0, 5.0, 10.0) + 0.8
	print(rotosnaps)
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

func _on_universe_piece_placed_2(cidx):
	pass
#	snaps = []
#	var pieces = get_tree().get_nodes_in_group('pieces')
#	rotosnaps = len(pieces)
#	cam_dist = remap(float(rotosnaps), 20.0, 40.0, 5.0, 10.0) + 0.8
#	print(rotosnaps)
#	var ang = (2*PI)/rotosnaps
#	for r in rotosnaps:
#		snaps.append(ang*(r))
#	for p in pieces:
#		if p.circle_idx > cidx:
#			p.circle_idx -= 1
#		p.rearrange_offset = p.circle_idx - cidx
#		p.arrange(true)
