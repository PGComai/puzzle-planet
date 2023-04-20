extends SubViewport

@export var target_res: float = 500

@onready var v_split = $"../../.."

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var size_scale = target_res/clamp(size.x, v_split.viewsize.x+90, v_split.viewsize.y-v_split.max_offset-10)
	scaling_3d_scale = size_scale
