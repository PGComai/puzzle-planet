extends Node3D

var global: Node

# Called when the node enters the scene tree for the first time.
func _ready():
	global = get_node("/root/Global")
	global.piece_target_node = self
	global.wheel_rot_signal.connect(_on_global_wheel_rot_signal)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_global_wheel_rot_signal(rot):
	pass
#	if get_child_count() > 0:
#		get_child(0).rotation.z = rot
