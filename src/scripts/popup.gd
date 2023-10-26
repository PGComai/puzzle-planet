extends PopupMenu

var global: Node

# Called when the node enters the scene tree for the first time.
func _ready():
	global = get_node("/root/Global")
	size.x = get_tree().root.size.x
	position.y = get_tree().root.size.y - size.y

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_id_pressed(id):
	if id == 3:
		self.visible = false

func _on_menu_button_pressed():
	visible = true
	global.debug_message = "Menu button pressed"


func _on_visibility_changed():
	global.menu_open = visible
