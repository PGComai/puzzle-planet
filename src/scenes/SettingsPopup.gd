extends PopupPanel


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_popup_menu_id_pressed(id):
	if id == 1:
		visible = true


func _on_close_button_up():
	visible = false
