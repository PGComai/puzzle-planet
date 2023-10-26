extends Button

var global: Node

# Called when the node enters the scene tree for the first time.
func _ready():
	global = get_node("/root/Global")
	set_pressed_no_signal(global.vibration)
	if button_pressed:
		text = 'ON'
	else:
		text = 'OFF'


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_toggled(button_pressed):
	if button_pressed:
		text = 'ON'
	else:
		text = 'OFF'
