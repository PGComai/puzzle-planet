extends PanelContainer

var global: Node
@onready var ux = $".."

# Called when the node enters the scene tree for the first time.
func _ready():
	global = get_node("/root/Global")
	global.default_vsplit_changed.connect(_on_global_default_vsplit_changed)
	position.y = max(ux.size.y - 600, ux.size.y / 2)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_global_default_vsplit_changed(split):
	position.y = split - (size.y / 2)
	if ux:
		size.x = ux.size.x
