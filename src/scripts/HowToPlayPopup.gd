extends PopupPanel

@onready var ux = $".."

# Called when the node enters the scene tree for the first time.
func _ready():
	size.x = ux.size.x
	position.y = ux.size.y - size.y

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_ux_resized():
	if ux:
		size.x = ux.size.x
		position.y = ux.size.y - size.y
