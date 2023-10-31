extends MeshInstance3D

const TITLE_Z := -0.7
const HIDDEN_Z := 0.1

var global: Node

var transition_completed := false
var deployed := true

# Called when the node enters the scene tree for the first time.
func _ready():
	global = get_node("/root/Global")
	global.title_screen_signal.connect(_on_global_title_screen_signal)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if not transition_completed:
		if deployed:
			position.z = lerp(position.z, TITLE_Z, 0.02)
			if is_equal_approx(position.z, TITLE_Z):
				position.z = TITLE_Z
				transition_completed = true
		else:
			position.z = lerp(position.z, HIDDEN_Z, 0.05)
			if is_equal_approx(position.z, HIDDEN_Z):
				position.z = HIDDEN_Z
				transition_completed = true
				visible = false


func _on_global_title_screen_signal(status):
	deployed = status
	transition_completed = false
	if deployed:
		visible = true
