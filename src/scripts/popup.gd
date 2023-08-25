extends PopupMenu


# Called when the node enters the scene tree for the first time.
func _ready():
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
