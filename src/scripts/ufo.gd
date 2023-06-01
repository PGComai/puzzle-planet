extends Node3D

signal ufo_done

@export var journey_speed_curve: Curve

var locs: Dictionary
var path: Array
var num_stops: int
var current_stop := 0
var next_stop: int
var showtime := false
var checkpoint_1 := false
var journey := false
var checkpoint_last := false
var lerp_multiplier := 1.0
var journey_lerp_multiplier := 0.0
@onready var tractor_beam = $meshes/tractor_beam

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if showtime:
		lerp_multiplier += delta
		look_at(Vector3.ZERO, Vector3.UP)
		if !checkpoint_1:
			position = position.slerp(Vector3(0.1, 1.3, 0.1), 0.1 * lerp_multiplier)
			if position.is_equal_approx(Vector3(0.1, 1.3, 0.1)):
				position = Vector3(0.1, 1.3, 0.1)
				checkpoint_1 = true
				lerp_multiplier = 1.0
				Input.vibrate_handheld(3)
		elif !journey:
			_run_journey()
		elif !checkpoint_last:
			position = position.slerp(Vector3(0.1, 5.0, 0.1), 0.1 * lerp_multiplier)
			if position.is_equal_approx(Vector3(0.1, 5.0, 0.1)):
				position = Vector3(1.0, 5.0, 0.1)
				checkpoint_last = true
				lerp_multiplier = 1.0
		else:
			emit_signal('ufo_done')
			showtime = false
			journey = false
			checkpoint_1 = false
			checkpoint_last = false
			visible = false

func _run_journey():
	if next_stop > num_stops - 1:
		journey = true
		journey_lerp_multiplier = 0.0
		next_stop = 0
	else:
		#print(journey_speed_curve.sample_baked(journey_lerp_multiplier))
		var target = locs[path[next_stop]].normalized() * 1.3
		position = position.slerp(target, journey_speed_curve.sample_baked(journey_lerp_multiplier))
		if position.is_equal_approx(target):
			journey_lerp_multiplier = (float(next_stop) + 1.0) / (float(num_stops) + 1.0)
			position = target
			next_stop += 1
			lerp_multiplier = 1.0
			Input.vibrate_handheld(3)

func _on_universe_ufo_ready_2(dict):
	locs = dict
	_make_path()

func _make_path():
	path = []
	var list = []
	var record = {}
	for l in locs.keys():
		record[locs[l].y] = l
		list.append(locs[l].y)
	list.sort()
	list.reverse()
	for l in list:
		path.append(record[l])
	num_stops = len(path)
	print(path)

func _on_universe_ufo_time():
	showtime = true
	visible = true
