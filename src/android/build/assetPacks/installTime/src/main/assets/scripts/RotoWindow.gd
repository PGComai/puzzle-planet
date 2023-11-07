extends PanelContainer

var global: Node

@onready var ghost_ball = $"../SubViewportRoto/PieceView/Camera3D/GhostBall"
@onready var ux = $".."

# Called when the node enters the scene tree for the first time.
func _ready():
	global = get_node('/root/Global')
	global.default_vsplit_changed.connect(_on_global_default_vsplit_changed)
	visible = global.rotation
	if not global.tablet_mode:
		position.y = max(ux.size.y - 600, ux.size.y / 2) - (size.y / 2)
	else:
		position.y = (ux.size.y / 1.8) - (size.y / 2)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_browser_wheel_rot(rot):
	ghost_ball.rotation.z = rot


func _on_ux_resized():
	if ux:
		position.x = (ux.size.x / 2) - (size.x / 2)


func _on_global_default_vsplit_changed(split):
	position.y = split - (size.y / 2)
