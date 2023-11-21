extends VideoStreamPlayer


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_finished():
	play()


func _on_how_to_play_popup_visibility_changed():
	if is_inside_tree():
		if visible:
			play()
		else:
			stop()
