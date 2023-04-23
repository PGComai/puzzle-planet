extends Node3D

var pos = Vector3.ZERO
var norm = Vector3.FORWARD

# Called when the node enters the scene tree for the first time.
func _ready():
	self.look_at_from_position(pos, pos+norm)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
