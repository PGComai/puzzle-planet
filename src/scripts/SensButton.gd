extends Button

var options := ["0.5x", "0.75x", "1x", "1.25x", "1.5x"]
var option_values := [0.5, 0.75, 1.0, 1.25, 1.5]
var selected_idx := 2
var global: Node

# Called when the node enters the scene tree for the first time.
func _ready():
	global = get_node("/root/Global")
	selected_idx = option_values.find(global.sensitivity_multiplier)
	text = options[selected_idx]


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_button_up():
	selected_idx += 1
	if selected_idx >= options.size():
		selected_idx = 0
	text = options[selected_idx]
	global.sensitivity_multiplier = option_values[selected_idx]
