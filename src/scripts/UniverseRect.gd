extends TextureRect

var global: Node

@onready var timer = $Timer
@onready var browser_rect = $"../BrowserRect"

# Called when the node enters the scene tree for the first time.
func _ready():
	global = get_node("/root/Global")
	global.menu_open_signal.connect(_on_global_menu_open_signal)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_global_menu_open_signal(open):
	if open:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		browser_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		timer.stop()
	else:
		timer.start()


func _on_timer_timeout():
	mouse_filter = Control.MOUSE_FILTER_PASS
	browser_rect.mouse_filter = Control.MOUSE_FILTER_PASS
