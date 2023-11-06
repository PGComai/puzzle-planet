extends Node3D

var global: Node

# Called when the node enters the scene tree for the first time.
func _ready():
	global = get_node("/root/Global")
	global.wheel_rot_signal.connect(_on_global_wheel_rot_signal)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_global_wheel_rot_signal(rot):
	rotation.z = rot
