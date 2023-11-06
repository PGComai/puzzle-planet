extends Label

var global: Node
var msg1: String
var msg2: String
var msg3: String
var num_msgs := 0

@onready var timer = $Timer

# Called when the node enters the scene tree for the first time.
func _ready():
	global = get_node("/root/Global")
	global.debug_message_added.connect(_on_global_debug_message_added)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_global_debug_message_added():
	if global.debug_log.size() > 2:
		text = String(global.debug_log[-1] + "\n"
					+ global.debug_log[-2] + "\n"
					+ global.debug_log[-3])
	elif global.debug_log.size() == 2:
		text = String(global.debug_log[-1] + "\n"
					+ global.debug_log[-2])
	else:
		text = global.debug_log[0]
	visible = true
	timer.start()


func _on_timer_timeout():
	visible = false
