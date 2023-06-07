extends AudioStreamPlayer

var vibrate := false
var global

# Called when the node enters the scene tree for the first time.
func _ready():
	global = get_node('/root/Global')


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_browser_click(speed):
	if global.sound:
		pitch_scale = speed
		play()
	if global.vibration:
		Input.vibrate_handheld(4)
	
