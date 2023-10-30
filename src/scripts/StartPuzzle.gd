extends Button

var global

@onready var timer = $Timer

# Called when the node enters the scene tree for the first time.
func _ready():
	global = get_node('/root/Global')
	global.ready_to_start_signal.connect(_on_global_ready_to_start_signal)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_button_up():
	visible = false
	if not global.current_puzzle_was_loaded:
		global.pieces_placed_so_far = [0, global.total_pieces - global.pieces_at_start]
	print(global.pieces_placed_so_far)
	global.puzzle_started = true

func _on_generate_button_up():
	visible = false


func _on_resume_button_up():
	visible = false


func _on_global_ready_to_start_signal():
	timer.start()


func _on_timer_timeout():
	visible = true
