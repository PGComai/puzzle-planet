extends PopupMenu

var global: Node
@onready var ux = $"../.."

# Called when the node enters the scene tree for the first time.
func _ready():
	global = get_node("/root/Global")
	var sz = ux.size
	size.x = sz.x
	print(sz)
	position.y = sz.y - size.y


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_id_pressed(id):
	if id == 3:
		self.visible = false
	elif id == 4:
		global._save_planet_for_title()


func _on_menu_button_pressed():
	visible = true
	global.debug_message = "Menu button pressed"


func _on_visibility_changed():
	if global:
		global.menu_open = visible


func _on_start_game_timer_timeout():
	visible = true


func _on_ux_resized():
	if ux:
		size.x = ux.size.x
		position.y = ux.size.y - size.y
