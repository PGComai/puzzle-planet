extends Button

var global: Node

# Called when the node enters the scene tree for the first time.
func _ready():
	global = get_node("/root/Global")
	#global.title_screen_signal.connect(_on_global_title_screen_signal)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


#func _on_global_title_screen_signal(status):
#	visible = status


func _on_button_up():
	visible = false
	global.title_screen = false
