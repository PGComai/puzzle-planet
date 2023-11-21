extends PopupPanel


var global: Node
@onready var ux = $".."


# Called when the node enters the scene tree for the first time.
func _ready():
	global = get_node("/root/Global")
	size.x = ux.size.x
	position.y = ux.size.y - size.y


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_ux_resized():
	if ux:
		size.x = ux.size.x
		position.y = ux.size.y - size.y


func _on_visibility_changed():
	if global:
		global.menu_open = visible


func _on_close_button_up():
	visible = false


func _on_popup_menu_id_pressed(id):
	if id == 2:
		visible = true
