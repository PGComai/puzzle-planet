extends AudioStreamPlayer

var vibrate := false

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if vibrate:
		Input.vibrate_handheld(3)
		vibrate = false


func _on_browser_click(speed):
	pitch_scale = speed
	play()
	vibrate = true
	
