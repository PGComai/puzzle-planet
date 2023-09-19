extends MeshInstance3D

var global: Node

@onready var drawing_utensil = $"../DrawingUtensil"

# Called when the node enters the scene tree for the first time.
func _ready():
	global = get_node('/root/Global')
	global.drawing_mode_changed.connect(_on_global_drawing_mode_changed)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if drawing_utensil.is_colliding():
		global_position = drawing_utensil.get_collision_point()

func _on_global_drawing_mode_changed(value):
	visible = value
