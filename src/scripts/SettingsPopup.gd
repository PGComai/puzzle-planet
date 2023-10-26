extends PopupPanel

var global: Node

# Called when the node enters the scene tree for the first time.
func _ready():
	global = get_tree().root.get_node("/root/Global")
	size.x = get_tree().root.size.x
	position.y = get_tree().root.size.y - size.y

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_popup_menu_id_pressed(id):
	if id == 1:
		visible = true


func _on_close_button_up():
	visible = false


func _on_vibrate_button_toggled(button_pressed):
	global.vibration = button_pressed


func _on_sound_button_toggled(button_pressed):
	global.sound = button_pressed


func _on_graphics_check_button_toggled(button_pressed):
	global.graphics_fancy = button_pressed


func _on_music_button_toggled(button_pressed):
	global.music = button_pressed


func _on_debug_button_toggled(button_pressed):
	global.debugging = button_pressed


func _on_visibility_changed():
	global.menu_open = visible
