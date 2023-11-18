extends MeshInstance3D

const TITLE_Z := -0.7
const HIDDEN_Z := 0.1
const TITLE_TEXT := "puzzle\n "
const TITLE_SIZE := 14
const TITLE_SPACING := 1
const COMPLETE_TEXT := "puzzle\ncomplete"
const COMPLETE_SIZE := 10
const COMPLETE_SPACING := 5

var global: Node

var transition_completed := false
var deployed := true

@onready var timer = $Timer
@onready var planetarium = $planetarium

# Called when the node enters the scene tree for the first time.
func _ready():
	global = get_node("/root/Global")
	global.title_screen_signal.connect(_on_global_title_screen_signal)
	global.puzzle_done.connect(_on_global_puzzle_done)
	mesh.text = TITLE_TEXT


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


func _on_global_puzzle_done():
	planetarium.visible = false
	deployed = true
	transition_completed = false
	mesh.text = COMPLETE_TEXT
	mesh.font_size = COMPLETE_SIZE
	mesh.line_spacing = COMPLETE_SPACING
	visible = true
	timer.start()


func _on_timer_timeout():
	deployed = false
	transition_completed = false
