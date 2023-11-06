extends RayCast3D

var global: Node

# Called when the node enters the scene tree for the first time.
func _ready():
	global = get_node('/root/Global')
	global.drawing_mode_changed.connect(_on_global_drawing_mode_changed)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_global_drawing_mode_changed(value):
	enabled = value
