extends AudioStreamPlayer3D

var global

# Called when the node enters the scene tree for the first time.
func _ready():
	global = get_node('/root/Global')


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_ufo_ufo_abducting(piece, speed):
	if global.sound:
		pitch_scale = 0.8 + (speed / 5.0)
		play()
