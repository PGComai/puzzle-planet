extends Camera3D

const PHONE_FOV := 90.0
const TABLET_FOV := 110.0

var global: Node
var transition_complete := true

# Called when the node enters the scene tree for the first time.
func _ready():
	global = get_node("/root/Global")
	global.tablet_mode_signal.connect(_on_global_tablet_mode_signal)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if not transition_complete:
		if global.tablet_mode:
			fov = lerp(fov, TABLET_FOV, 0.1)
			if is_equal_approx(fov, TABLET_FOV):
				fov = TABLET_FOV
				transition_complete = true
		else:
			fov = lerp(fov, PHONE_FOV, 0.1)
			if is_equal_approx(fov, PHONE_FOV):
				fov = PHONE_FOV
				transition_complete = true


func _on_global_tablet_mode_signal(onoff):
	transition_complete = false
