extends Control

var global
# Called when the node enters the scene tree for the first time.
func _ready():
	global = get_node('/root/Global')


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_graphics_check_button_toggled(button_pressed):
	global.graphics_fancy = button_pressed

func _on_sound_check_button_toggled(button_pressed):
	global.sound = button_pressed

func _on_vibrate_check_button_toggled(button_pressed):
	global.vibration = button_pressed
