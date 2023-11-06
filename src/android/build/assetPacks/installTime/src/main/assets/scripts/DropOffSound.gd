extends AudioStreamPlayer3D

var global

# Called when the node enters the scene tree for the first time.
func _ready():
	global = get_node('/root/Global')


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_planet_piece_drop_off_sound():
	if global.sound:
		play()
