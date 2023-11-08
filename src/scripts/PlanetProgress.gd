extends ProgressBar

var global
var pieces_made_so_far := 0
@onready var panel_container = $"../.."
@onready var progress_full_timer = $ProgressFullTimer

# Called when the node enters the scene tree for the first time.
func _ready():
	global = get_node('/root/Global')

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_universe_piece_added():
	if global:
		pieces_made_so_far += 1
		value = ((float(pieces_made_so_far) / float(global.total_pieces)) * 100.0)
		#print(pieces_made_so_far)
		if pieces_made_so_far == global.total_pieces:
			progress_full_timer.start()

func _on_generate_button_up():
	pieces_made_so_far = 0
	set_value_no_signal(0.0)
	panel_container.visible = true
	progress_full_timer.stop()

func _on_progress_full_timer_timeout():
	panel_container.visible = false
	pieces_made_so_far = 0
	set_value_no_signal(0.0)
	progress_full_timer.stop()

func _on_start_puzzle_button_up():
	panel_container.visible = false
	pieces_made_so_far = 0
	set_value_no_signal(0.0)
	progress_full_timer.stop()
