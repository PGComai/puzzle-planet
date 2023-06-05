extends AudioStreamPlayer

var vibrate := false

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_browser_click(speed):
	pitch_scale = speed
	play()
	Input.vibrate_handheld(4)
	
