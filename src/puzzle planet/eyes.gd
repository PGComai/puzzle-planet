extends Node3D

signal meshes_made2
signal piece_placed2

@onready var v_split = $"../../../.."
@onready var ux = $"../../../../../.."
@onready var camera_3d = $h/v/Camera3D

var rot_h = 0.0
var rot_v = 0.0
var v_min = -89.0
var v_max = 89.0
var h_sensitivity = 0.05
var v_sensitivity = 0.05
var h_acc
var v_acc

var erx = 0.0
var ery = 0.0
var drag = false
var erx_acc = []
var ery_acc = []

var h: int

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED)
	h = ux.size.y/2
	
func _unhandled_input(event):
#	if event is InputEventMouseMotion and click:
#		erx = event.relative.x * h_sensitivity
#		ery = event.relative.y * v_sensitivity
	if event is InputEventScreenDrag:
		var touchborder = h + v_split.split_offset
		#print(touchborder)
		if event.position.y < touchborder:
			drag = true
			erx = event.relative.x * h_sensitivity
			ery = event.relative.y * v_sensitivity

func _process(delta):
	if not drag:
		erx = lerp(erx, 0.0, 0.03)
		ery = lerp(ery, 0.0, 0.03)
		erx_acc = []
		ery_acc = []
	else:
		erx_acc.append(erx)
		if len(erx_acc) > 5:
			erx_acc.remove_at(0)
		ery_acc.append(ery)
		if len(ery_acc) > 5:
			ery_acc.remove_at(0)
		erx = erx_acc.reduce(func(accum, number): return accum + number, 0)/5
		ery = ery_acc.reduce(func(accum, number): return accum + number, 0)/5
	rot_h -= erx
	rot_v -= ery
	
	rot_v = clamp(rot_v, v_min, v_max)
	
	$h.rotation_degrees.y = rot_h
	$h/v.rotation_degrees.x = rot_v
	camera_3d.fov = clamp(remap(v_split.split_offset + (v_split.split_offset/2), 0.0, v_split.viewsize.y, 75.0, 120.0), 75.0, 120.0)
	#print(v_split.viewsize.y)
	drag = false

func _on_mesh_maker_meshes_made():
	emit_signal("meshes_made2")



func _on_mesh_maker_piece_placed(cidx):
	emit_signal("piece_placed2", cidx)
