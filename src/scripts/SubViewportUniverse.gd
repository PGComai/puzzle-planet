extends SubViewport

const PHONE_SIZE := Vector2i(180, 320)
const TABLET_SIZE := Vector2i(360, 360)

var global: Node
@onready var sub_viewport_browser = $"../SubViewportBrowser"

# Called when the node enters the scene tree for the first time.
func _ready():
	global = get_node("/root/Global")
	global.tablet_mode_signal.connect(_on_global_tablet_mode_signal)
	if not global.tablet_mode:
		size.x = PHONE_SIZE.x
		size.y = PHONE_SIZE.y
		sub_viewport_browser.size.x = PHONE_SIZE.x
		sub_viewport_browser.size.y = PHONE_SIZE.x
	else:
		size.x = TABLET_SIZE.x
		size.y = TABLET_SIZE.y
		sub_viewport_browser.size.x = TABLET_SIZE.x
		sub_viewport_browser.size.y = TABLET_SIZE.y


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_global_tablet_mode_signal(onoff):
	if onoff:
		
		### PRETTY MODE
#		size_2d_override.x = TABLET_SIZE.x
#		size_2d_override.y = TABLET_SIZE.y
#		size.x = 1024
#		size.y = 1024
		### PRETTY MODE
		
		size.x = TABLET_SIZE.x
		size.y = TABLET_SIZE.y
		sub_viewport_browser.size.x = TABLET_SIZE.x
		sub_viewport_browser.size.y = TABLET_SIZE.y
	else:
		size.x = PHONE_SIZE.x
		size.y = PHONE_SIZE.y
		sub_viewport_browser.size.x = PHONE_SIZE.x
		sub_viewport_browser.size.y = PHONE_SIZE.x
