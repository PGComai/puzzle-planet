extends PanelContainer

@onready var ux = $".."

# Called when the node enters the scene tree for the first time.
func _ready():
	position.y = min(ux.size.y - 560, ux.size.y / 2)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
