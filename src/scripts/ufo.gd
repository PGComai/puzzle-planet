extends Node3D

signal ufo_done
signal ufo_abducting(piece, speed)
signal ufo_abduction_done
signal spinny_time
signal ufo_take_me_home

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
var beam_timer := 0.0
var beam_done := false
var abduct_signal_sent := false
var in_browser := false
var browser_drop_off_begin := false
var browser_drop_off_end := false
var drop_off_cam_dist: float
var drop_off_cam_pos: Vector3
var drop_off_enter_circle_checkpoint := false
var drop_off_exit_circle_checkpoint := false
var start_drop_off_pos: Vector3
var planet_hover_height := 1.3

var global

@onready var tractor_beam = $meshes/tractor_beam
@onready var abduction_sound = $AbductionSound

# Called when the node enters the scene tree for the first time.
func _ready():
	global = get_node('/root/Global')
	global.ufo_ready_signal.connect(_on_global_ufo_ready_signal)
	global.ufo_reset_signal.connect(_on_global_ufo_reset_signal)
	global.ufo_time_signal.connect(_on_global_ufo_time_signal)
	visible = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if showtime:
		lerp_multiplier += delta
		
		if !checkpoint_1:
			position = position.slerp(Vector3(0.1, (planet_hover_height + global.planet_height_for_ufo), 0.1), 0.1 * lerp_multiplier)
			if position.is_equal_approx(Vector3(0.1, (planet_hover_height + global.planet_height_for_ufo), 0.1)):
				position = Vector3(0.1, (planet_hover_height + global.planet_height_for_ufo), 0.1)
				checkpoint_1 = true
				lerp_multiplier = 1.0
				if global.vibration:
					Input.vibrate_handheld(5)
		elif !journey:
			_run_journey(delta)
		elif !checkpoint_last:
			position = position.slerp(Vector3(0.1, -5.0, 0.1), 0.1 * lerp_multiplier)
			if position.is_equal_approx(Vector3(0.1, -5.0, 0.1)):
				position = Vector3(1.0, 5.0, 0.1)
				checkpoint_last = true
				lerp_multiplier = 1.0
				visible = false
		else:
			#emit_signal('ufo_done')
			global.ufo_done = true
			showtime = false
			journey = false
			checkpoint_1 = false
			checkpoint_last = false
			#visible = false
		look_at(Vector3.ZERO, Vector3.UP)
	elif in_browser:
		if browser_drop_off_begin:
			position = Vector3(0.0, 12.0, 0.0)
			browser_drop_off_begin = false
			drop_off_enter_circle_checkpoint = false
			drop_off_exit_circle_checkpoint = false
			start_drop_off_pos = -drop_off_cam_pos.limit_length(drop_off_cam_pos.length() - 1.3) + Vector3(0.0, 0.2, 0.0)
			visible = true
		elif !browser_drop_off_end:
			_drop_off()
		else:
			position = lerp(position, Vector3(0.0, 12.0, 0.0), 0.1)
			if position.y > 8.0:
				emit_signal('ufo_take_me_home')
				in_browser = false
				browser_drop_off_begin = false
				browser_drop_off_end = false
				drop_off_enter_circle_checkpoint = false
				drop_off_exit_circle_checkpoint = false
				visible = false

func _drop_off():
	if !drop_off_enter_circle_checkpoint:
		position = lerp(position, start_drop_off_pos, 0.1)
		var loo = start_drop_off_pos.normalized() * 100.0
		var look = Vector3(loo.x, -20.0, loo.z)
		look_at(look, Vector3.UP)
		if position.is_equal_approx(start_drop_off_pos):
			drop_off_enter_circle_checkpoint = true
			emit_signal('spinny_time')
	elif drop_off_exit_circle_checkpoint:
		position = lerp(position, Vector3(0.0, 0.2, 0.0), 0.1)
		if position.is_equal_approx(Vector3(0.0, 0.2, 0.0)):
			browser_drop_off_end = true

func _run_journey(delta):
	if next_stop > num_stops - 1:
		journey = true
		journey_lerp_multiplier = 0.0
		next_stop = 0
	else:
		#print(journey_speed_curve.sample_baked(journey_lerp_multiplier))
		var target = locs[path[next_stop]].normalized() * (planet_hover_height + global.planet_height_for_ufo)
		position = position.slerp(target, journey_speed_curve.sample_baked(journey_lerp_multiplier))
		if position.is_equal_approx(target):
			if !abduct_signal_sent:
				var speed = journey_speed_curve.sample_baked(journey_lerp_multiplier)
				if global.sound:
					abduction_sound.pitch_scale = 0.8 + (speed / 5.0)
					abduction_sound.play()
				global.ufo_abducting = [path[next_stop], speed]
				abduct_signal_sent = true
			if !beam_done:
				_beam(delta, journey_lerp_multiplier)
			else:
				journey_lerp_multiplier = (float(next_stop) + 1.0) / (float(num_stops) + 1.0)
				position = target
				next_stop += 1
				lerp_multiplier = 1.0
				if global.vibration:
					Input.vibrate_handheld(5)
				beam_done = false
				abduct_signal_sent = false

func _beam(delta, multi := 1.0):
	beam_timer += delta
	#print(beam_timer)
	if beam_timer > 0.5 * (1.0/(1.0 + multi)):
		beam_done = true
		beam_timer = 0.0
		tractor_beam.visible = false
		#emit_signal("ufo_abduction_done")
		global.ufo_abduction_done = true
	else:
		tractor_beam.visible = true


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
	#print(path)


func _on_global_ufo_ready_signal(dict):
	locs = dict
	_make_path()


func _on_global_ufo_reset_signal():
	visible = false
	showtime = false
	beam_timer = 0.0
	next_stop = 0
	checkpoint_1 = false
	journey = false
	checkpoint_last = false
	lerp_multiplier = 1.0
	journey_lerp_multiplier = 0.0
	beam_done = false
	abduct_signal_sent = false
	position = Vector3(0.1, 5.0, 0.1)
	tractor_beam.visible = false


func _on_global_ufo_time_signal():
	showtime = true
	visible = true
