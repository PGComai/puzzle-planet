extends PanelContainer

@onready var ghost_ball = $"../SubViewportRoto/PieceView/Camera3D/GhostBall"
@onready var ux = $".."

# Called when the node enters the scene tree for the first time.
func _ready():
	var global = get_node('/root/Global')
	visible = global.rotation
	position.y = min(ux.size.y - 560, ux.size.y / 2) - 50

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_browser_wheel_rot(rot):
	ghost_ball.rotation.z = rot
