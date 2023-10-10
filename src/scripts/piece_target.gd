extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_universe_spin_piece(rot):
	if get_child_count() > 0:
		get_child(0).rotation.z = rot
		#print(fmod(abs(rot), 2*PI))
