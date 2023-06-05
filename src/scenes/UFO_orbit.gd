extends Node3D

signal at_angle(angle)
signal drop_off_done

@export var spinny_curve: Curve
var spin := false
var past_halfway := false
var ufo: Node3D
var ufo_starting_pos: Vector3

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if spin:
		_spin()

func _connect_to_UFO():
	if get_child_count() > 0:
		ufo = get_child(0)
		if !ufo.is_connected('spinny_time', _on_UFO_spinny_time):
			ufo.spinny_time.connect(_on_UFO_spinny_time)

func _on_UFO_spinny_time():
	spin = true
	past_halfway = false
	ufo_starting_pos = Vector3(ufo.global_position.x, 0.0 ,ufo.global_position.z)
	ufo.tractor_beam.visible = true

func _spin():
	var ang = ufo_starting_pos.signed_angle_to(Vector3(ufo.global_position.x, 0.0 ,ufo.global_position.z), Vector3.UP)
	var scaled_ang = remap(abs(ang), 0.0, PI, 0.0, 1.0)
	rotate(Vector3.UP, PI/180.0 * spinny_curve.sample_baked(scaled_ang))
	emit_signal("at_angle", ang)
	if ang < 0.0:
		past_halfway = true
	if past_halfway and ang > 0.0:
		spin = false
		past_halfway = false
		ufo.drop_off_exit_circle_checkpoint = true
		ufo.tractor_beam.visible = false
		emit_signal('drop_off_done')
