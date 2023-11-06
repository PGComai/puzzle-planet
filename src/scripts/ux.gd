extends Control

var global
# Called when the node enters the scene tree for the first time.
func _ready():
	global = get_node('/root/Global')

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_resized():
	if global:
		var ar = size.x / size.y
		if ar >= 0.6 and not global.tablet_mode:
			global.tablet_mode = true
		elif ar < 0.6 and global.tablet_mode:
			global.tablet_mode = false
